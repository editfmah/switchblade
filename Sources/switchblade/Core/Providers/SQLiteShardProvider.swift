//
//  SQLiteShardProvider.swift
//  Switchblade
//
//  Created by Adrian on 20/10/2024.
//

import Foundation

import Dispatch
import CryptoSwift
import CSQLite

public class SQLiteShardProvider: DataProvider {

    public var config: SwitchbladeConfig!
    public weak var blade: Switchblade!
    
    fileprivate var lock = Mutex()
    fileprivate var dbs: [String : SQLiteShardInterfaceProvider] = [:]

    fileprivate func provider(_ partition: String, keyspace: String) -> SQLiteShardInterfaceProvider {
        var provider: SQLiteShardInterfaceProvider!
        let index = partition + keyspace
        lock.mutex {
            if let p = dbs[index.md5()] {
                provider = p
            } else {
                provider = SQLiteShardInterfaceProvider(path: "\(path!)/\(index.md5()).sqlite")
                provider.config = config
                provider.blade = blade
                try? provider.open()
                dbs[index.md5()] = provider
            }
        }
        return provider
    }
    
    fileprivate func providers() -> [SQLiteShardInterfaceProvider] {
        var providers: [SQLiteShardInterfaceProvider] = []
        lock.mutex {
            providers = dbs.map { $0.value }
        }
        return providers
    }
        
    private var path: String?
    let decoder: JSONDecoder = JSONDecoder()
    
    public init(path: String)  {
        self.path = path
    }
    
    public func open() throws {
        // search for all .sqlite files in the path and open them.  Appending them to the dbs dictionary
        let fm = FileManager.default
        let files = try fm.contentsOfDirectory(atPath: path!)
        for file in files {
            if file.hasSuffix(".sqlite") {
                // filename is already an md5
                let provider = SQLiteShardInterfaceProvider(path: "\(path!)/\(file)")
                provider.config = config
                provider.blade = blade
                try provider.open()
                dbs[file.replacingOccurrences(of: ".sqlite", with: "")] = provider
            }
        }
    }
    
    public func close() throws {
    }
    
    public func transact(_ mode: transaction) -> Bool {
        // no transactions in sharded databases
        return true
    }
    
    public func put<T>(partition: String, key: String, keyspace: String, ttl: Int, filter: [String : String]?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        return provider(partition, keyspace: keyspace).put(partition: partition, key: key, keyspace: keyspace, ttl: ttl, filter: filter, object)
    }
    
    public func delete(partition: String, key: String, keyspace: String) -> Bool {
        return provider(partition, keyspace: keyspace).delete(partition: partition, key: key, keyspace: keyspace)
    }
    
    public func get<T>(partition: String, key: String, keyspace: String) -> T? where T : Decodable, T : Encodable {
        return provider(partition, keyspace: keyspace).get(partition: partition, key: key, keyspace: keyspace)
    }
    
    public func query<T>(partition: String, keyspace: String, filter: [String : String]?, map: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        return provider(partition, keyspace: keyspace).query(partition: partition, keyspace: keyspace, filter: filter, map: map)
    }
    
    public func all<T>(partition: String, keyspace: String, filter: [String : String]?) -> [T] where T : Decodable, T : Encodable {
        return provider(partition, keyspace: keyspace).all(partition: partition, keyspace: keyspace, filter: filter)
    }
    
    public func iterate<T>(partition: String, keyspace: String, filter: [String : String]?, iterator: ((T) -> Void)) where T : Decodable, T : Encodable {
        return provider(partition, keyspace: keyspace).iterate(partition: partition, keyspace: keyspace, filter: filter, iterator: iterator)
    }
    
    public func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: @escaping ((FromType) -> ToType?)) where FromType : SchemaVersioned, ToType : SchemaVersioned {
        // this is a migration of all. And in paralell as well
        for provider in providers() {
            provider.migrate(from: from, to: to, migration: migration)
        }
    }
    
    public func ids(partition: String, keyspace: String, filter: [String : String]?) -> [String] {
        return provider(partition, keyspace: keyspace).ids(partition: partition, keyspace: keyspace, filter: filter)
    }
    
}

fileprivate let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
fileprivate let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

fileprivate var ttl_now: Int {
    get {
        return Int(Date().timeIntervalSince1970)
    }
}

fileprivate class SQLiteShardInterfaceProvider: DataProvider {
    
    public var config: SwitchbladeConfig!
    public weak var blade: Switchblade!
    fileprivate var lock = Mutex()
    
    var db: OpaquePointer?
    private var p: String?
    let decoder: JSONDecoder = JSONDecoder()
    
    public init(path: String)  {
        p = path
    }
    
    public func open() throws {
        
        // create any folders up until this point as well
        let _ = sqlite3_open("\(p!)", &db);
        if db == nil {
            throw DatabaseError.Init(.UnableToCreateLocalDatabase)
        }
        
        // tables
        _ = try self.execute(sql: """
CREATE TABLE IF NOT EXISTS Data (
    id TEXT,
    value BLOB,
    ttl INTEGER,
    timestamp INT,
    model TEXT,
    version INTEGER,
    filter TEXT,
    PRIMARY KEY (id)
);
""", params: [])
        
        // indexes
        _ = try self.execute(sql: "CREATE INDEX IF NOT EXISTS idx_ttl ON Data (ttl);", params: [])
        _ = try self.execute(sql: "CREATE INDEX IF NOT EXISTS idx_schema ON Data (model,version);", params: [])
        
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 60, execute: {
            while self.db != nil {
                // only clean up data that is over two hours old. This is to allow offline nodes to replay changes when they come back online
                try? self.execute(sql: "DELETE FROM Data WHERE ttl IS NOT NULL AND ttl < ?;", params: [ttl_now - (7200)])
                Thread.sleep(forTimeInterval: 60)
            }
        })
        
    }
    
    public func close() throws {
        sqlite3_close(db)
        db = nil;
    }
    
    fileprivate func makeId(_ key: String) -> String {
        return key
    }
    
    public func execute(sql: String, params:[Any?], silent: Bool = false) throws {
        
        if silent {
            
            lock.mutex {
                var values: [Any?] = []
                for o in params {
                    values.append(o)
                }
                
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
                    
                    bind(stmt: stmt, params: values);
                    while sqlite3_step(stmt) != SQLITE_DONE {
                        
                    }
                    
                }
                
                sqlite3_finalize(stmt)
            }
            
        } else {
           
            try lock.throwingMutex {
                var values: [Any?] = []
                for o in params {
                    values.append(o)
                }
                
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
                    
                    bind(stmt: stmt, params: values);
                    while sqlite3_step(stmt) != SQLITE_DONE {
                        
                    }
                    
                } else {
                    // error in statement
                    debugPrint(String(cString: sqlite3_errmsg(db)))
                    Switchblade.errors[blade.instance] = true
                    throw DatabaseError.Execute(.SyntaxError("\(String(cString: sqlite3_errmsg(db)))"))
                }
                
                sqlite3_finalize(stmt)
            }
            
        }

    }
    
    fileprivate func iterate<T:Codable>(sql: String, params:[Any?], iterator: ( (T) -> Void)) {
        
        var values: [Any?] = []
        for o in params {
            values.append(o)
        }
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
            bind(stmt: stmt, params: values);
            while sqlite3_step(stmt) == SQLITE_ROW {
                
                let columns = sqlite3_column_count(stmt)
                if columns > 0 {
                    let i = 0
                    switch sqlite3_column_type(stmt, Int32(i)) {
                    case SQLITE_BLOB:
                        let d = Data(bytes: sqlite3_column_blob(stmt, Int32(i)), count: Int(sqlite3_column_bytes(stmt, Int32(i))))
                        if config.aes256encryptionKey == nil {
                            if let object = try? decoder.decode(T.self, from: d) {
                                iterator(object)
                            }
                        } else {
                            // this data is to be stored encrypted
                            if let encKey = config.aes256encryptionKey {
                                let key = encKey.sha256()
                                let iv = (encKey + Data(kSaltValue.bytes)).md5()
                                do {
                                    let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                                    let objectData = try aes.decrypt(d.bytes)
                                    if let object = try? decoder.decode(T.self, from: Data(bytes: objectData, count: objectData.count)) {
                                        iterator(object)
                                    }
                                } catch {
                                    print("encryption error: \(error)")
                                }
                            }
                        }
                    default:
                        break;
                    }
                }
                
            }
        } else {
            print(String(cString: sqlite3_errmsg(db)))
            Switchblade.errors[blade.instance] = true
        }
        
        sqlite3_finalize(stmt)
        
    }
    
    public func ids(partition: String, keyspace: String, filter: [String : String]?) -> [String] {
            
            var results: [String] = []
            
            var f: String = ""
            if let filter = filter, filter.isEmpty == false {
                for kvp in filter {
                    let value = "\(kvp.key)=\(kvp.value)".md5()
                    f += " AND filter LIKE '%\(value)%' "
                }
            }
        
        let sql = "SELECT id FROM Data WHERE (ttl IS NULL OR ttl >= ?) \(f) ORDER BY timestamp ASC;"
            
            // now query the database
            lock.mutex {
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
                    bind(stmt: stmt, params: [ttl_now]);
                    while sqlite3_step(stmt) == SQLITE_ROW {
                        
                        let columns = sqlite3_column_count(stmt)
                        if columns > 0 {
                            let i = 0
                            switch sqlite3_column_type(stmt, Int32(i)) {
                            case SQLITE_TEXT:
                                let value = String.init(cString:sqlite3_column_text(stmt, Int32(i)))
                                results.append(value)
                            default:
                                break;
                            }
                        }
                        
                    }
                } else {
                    print(String(cString: sqlite3_errmsg(db)))
                    Switchblade.errors[blade.instance] = true
                }
                
                sqlite3_finalize(stmt)
            }
        
        
            
            return results
        
    }
    
    fileprivate func migrate<T:SchemaVersioned>(iterator: ( (T) -> SchemaVersioned?)) {
        
        let fromInfo = T.version
        let values: [Any?] = [fromInfo.objectName, fromInfo.version, ttl_now]
        
        let sql = "SELECT value, \"\", \"\", id, ttl, filter FROM Data WHERE model = ? AND version = ? AND (ttl IS NULL or ttl >= ?)"
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
            bind(stmt: stmt, params: values);
            while sqlite3_step(stmt) == SQLITE_ROW {
                
                let columns = sqlite3_column_count(stmt)
                if columns > 0 {
                    let partition = String.init(cString:sqlite3_column_text(stmt, Int32(1)))
                    let keyspace = String.init(cString:sqlite3_column_text(stmt, Int32(2)))
                    let id = String.init(cString:sqlite3_column_text(stmt, Int32(3)))
                    var ttl: Int? = nil
                    if sqlite3_column_type(stmt, Int32(4)) == SQLITE_INTEGER {
                        ttl = Int(sqlite3_column_int64(stmt, Int32(4))) - ttl_now
                    }
                
                    switch sqlite3_column_type(stmt, Int32(0)) {
                    case SQLITE_BLOB:
                        let d = Data(bytes: sqlite3_column_blob(stmt, Int32(0)), count: Int(sqlite3_column_bytes(stmt, Int32(0))))
                        if config.aes256encryptionKey == nil {
                            if let object = try? decoder.decode(T.self, from: d) {
                                if let newObject = iterator(object) {
                                    var filters: [String:String] = [:]
                                    if let filterable = newObject as? Filterable {
                                        filters = filterable.filters.dictionary
                                    }
                                    let _ = self.put(partition: partition, key: id, keyspace: keyspace, ttl: ttl ?? -1, filter: filters, newObject)
                                } else {
                                    let _ = self.delete(partition: partition, key: id, keyspace: keyspace)
                                }
                            }
                        } else {
                            // this data is to be stored encrypted
                            if let encKey = config.aes256encryptionKey {
                                let key = encKey.sha256()
                                let iv = (encKey + Data(kSaltValue.bytes)).md5()
                                do {
                                    let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                                    let objectData = try aes.decrypt(d.bytes)
                                    if let object = try? decoder.decode(T.self, from: Data(bytes: objectData, count: objectData.count)) {
                                        if let newObject = iterator(object) {
                                            var filters: [String:String] = [:]
                                            if let filterable = newObject as? Filterable {
                                                filters = filterable.filters.dictionary
                                            }
                                            let _ = self.put(partition: partition, key: id, keyspace: keyspace, ttl: ttl ?? -1, filter: filters, newObject)
                                        } else {
                                            let _ = self.delete(partition: partition, key: id, keyspace: keyspace)
                                        }
                                    }
                                } catch {
                                    print("encryption error: \(error)")
                                }
                            }
                        }
                    default:
                        break;
                    }
                }
                
            }
        } else {
            print(String(cString: sqlite3_errmsg(db)))
            Switchblade.errors[blade.instance] = true
        }
        
        sqlite3_finalize(stmt)
        
    }
    
    public func query(sql: String, params:[Any?]) throws -> [(partition: String, keyspace: String, id: String, value: Data?)] {
        
        if let results = try lock.throwingMutex ({ () -> [(partition: String, keyspace: String, id: String, value: Data?)] in
            
            var results: [(partition: String, keyspace: String, id: String, value: Data?)] = []
            
            var values: [Any?] = []
            for o in params {
                values.append(o)
            }
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
                bind(stmt: stmt, params: values);
                while sqlite3_step(stmt) == SQLITE_ROW {
                    
                    let columns = sqlite3_column_count(stmt)
                    if columns > 3 {
                        let partition = String.init(cString:sqlite3_column_text(stmt, Int32(0)))
                        let keyspace = String.init(cString:sqlite3_column_text(stmt, Int32(1)))
                        let id = String.init(cString:sqlite3_column_text(stmt, Int32(2)))
                        var value: Data?
                        switch sqlite3_column_type(stmt, Int32(3)) {
                        case SQLITE_BLOB:
                            let d = Data(bytes: sqlite3_column_blob(stmt, Int32(3)), count: Int(sqlite3_column_bytes(stmt, Int32(3))))
                            value = d
                        default:
                            value = nil
                            break;
                        }
                        
                        results.append((partition: partition, keyspace: keyspace, id: id, value: value))
                    }
                    
                }
            } else {
                print(String(cString: sqlite3_errmsg(db)))
                Switchblade.errors[blade.instance] = true
                throw DatabaseError.Query(.SyntaxError("\(String(cString: sqlite3_errmsg(db)))"))
            }
            
            sqlite3_finalize(stmt)
            
            return results
            
        }) {
            return results
        } else {
            return []
        }
        
    }
    
    public func query(sql: String, parameters:[Any?]) -> [[Any?]] {
        
        var results: [[Any?]] = []
        
        lock.mutex {
            var values: [Any?] = []
            for o in parameters {
                values.append(o)
            }
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
                bind(stmt: stmt, params: values);
                while sqlite3_step(stmt) == SQLITE_ROW {
                    
                    var row: [Any?] = []
                    
                    let columns = sqlite3_column_count(stmt)
                    if columns > 0 {
                        for i in 0..<columns {
                            switch sqlite3_column_type(stmt, Int32(i)) {
                            case SQLITE_BLOB:
                                let d = Data(bytes: sqlite3_column_blob(stmt, Int32(i)), count: Int(sqlite3_column_bytes(stmt, Int32(i))))
                                row.append(d)
                            case SQLITE_INTEGER:
                                let value = Int(sqlite3_column_int64(stmt, Int32(i)))
                                row.append(value)
                            case SQLITE_FLOAT:
                                let value = Double(sqlite3_column_double(stmt, Int32(i)))
                                row.append(value)
                            case SQLITE_TEXT:
                                let value = String.init(cString:sqlite3_column_text(stmt, Int32(i)))
                                row.append(value)
                            case SQLITE_NULL:
                                row.append(nil)
                            default:
                                row.append(nil)
                                break;
                            }
                        }
                    }
                    
                    results.append(row)
                    
                }
            } else {
                print(String(cString: sqlite3_errmsg(db)))
                Switchblade.errors[blade.instance] = true
            }
            
            sqlite3_finalize(stmt)
        }
        return results
        
    }
    
    public func transact(_ mode: transaction) -> Bool {
        do {
            switch mode {
            case .begin:
                try execute(sql: "BEGIN TRANSACTION", params: [])
            case .commit:
                try execute(sql: "COMMIT TRANSACTION", params: [])
            case .rollback:
                try execute(sql: "ROLLBACK TRANSACTION", params: [])
            }
            return true
        } catch {
            return false
        }
    }
    
    public func put<T>(partition: String, key: String, keyspace: String, ttl: Int, filter: [String:String]?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        if let jsonObject = try? JSONEncoder().encode(object) {
            let id = makeId(key)
            do {
                if config.aes256encryptionKey == nil {
                    var model: String? = nil
                    var version: Int? = nil
                    if let info = (T.self as? SchemaVersioned.Type)?.version {
                        model = info.objectName
                        version = info.version
                    }
                    try execute(sql: "INSERT OR REPLACE INTO Data (id,value,ttl,timestamp,model,version,filter) VALUES (?,?,?,?,?,?,?);",
                                params: [
                                    id,
                                    jsonObject,ttl == -1 ? nil : Int(Date().timeIntervalSince1970) + ttl,
                                    Int(Date().timeIntervalSince1970),
                                    model,
                                    version,
                                    filter?.compactMap({ "\($0.key)=\($0.value)".md5() }).joined(separator: ",") ?? "",
                                ])
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
                            var model: String? = nil
                            var version: Int? = nil
                            if let info = (T.self as? SchemaVersioned.Type)?.version {
                                model = info.objectName
                                version = info.version
                            }
                            try execute(sql: "INSERT OR REPLACE INTO Data (id,value,ttl,timestamp,model,version,filter) VALUES (?,?,?,?,?,?,?);",
                                        params: [
                                            id,
                                            encryptedData,
                                            ttl == -1 ? nil : Int(Date().timeIntervalSince1970) + ttl,
                                            Int(Date().timeIntervalSince1970),
                                            model,
                                            version,
                                            filter?.compactMap({ "\($0.key)=\($0.value)".md5() }).joined(separator: ",") ?? "",
                                        ])
                        } catch {
                            print("encryption error: \(error)")
                        }
                    }
                }
                
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    public func delete(partition: String, key: String, keyspace: String) -> Bool {
        do {
            try execute(sql: "UPDATE Data SET ttl = ?, timestamp = ? WHERE id = ?;",
                        params: [
                            (ttl_now - 5),
                            Int(Date().timeIntervalSince1970),
                            key])
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func get<T>(partition: String, key: String, keyspace: String) -> T? where T : Decodable, T : Encodable {
        do {
            if config.aes256encryptionKey == nil {
                if let data = try query(sql: "SELECT \"\", \"\", id, value FROM Data WHERE  id = ? AND (ttl IS NULL OR ttl >= ?)", params: [key,ttl_now]).first, let objectData = data.value {
                    let object = try decoder.decode(T.self, from: objectData)
                    return object
                }
            } else {
                if let data = try query(sql: "SELECT \"\", \"\", id, value FROM Data WHERE id = ? AND (ttl IS NULL OR ttl >= ?)", params: [key,ttl_now]).first, let objectData = data.value, let encKey = config.aes256encryptionKey {
                    let key = encKey.sha256()
                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                    do {
                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                        let decryptedBytes = try aes.decrypt(objectData.bytes)
                        let decryptedData = Data(decryptedBytes)
                        let object = try decoder.decode(T.self, from: decryptedData)
                        return object
                    } catch {
                        print("encryption error: \(error)")
                    }
                }
            }
        } catch {
            debugPrint("SQLiteProvider Error:  Failed to decode stored object into type: \(T.self)")
            debugPrint("Error:")
            debugPrint(error)
            if let data = try? query(sql: "SELECT \"\", \"\", id, value FROM Data WHERE id = ? AND (ttl IS NULL OR ttl >= ?)", params: [key, ttl_now]).first, let objectData = data.value, let body = String(data: objectData, encoding: .utf8) {
                
                debugPrint("Object data:")
                debugPrint(body)
                
            }
        }
        return nil
    }

    @discardableResult
    public func query<T>(partition: String, keyspace: String, filter: [String : String]?, map: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        var results: [T] = []
        
        for result: T in all(partition: partition, keyspace: keyspace, filter: filter) {
            if map(result) {
                results.append(result)
            }
        }
        
        return results
    }
    
    public func migrate<FromType: SchemaVersioned, ToType: SchemaVersioned>(from: FromType.Type, to: ToType.Type, migration: ((FromType) -> ToType?)) {
        self.migrate(iterator: migration)
    }
    
    public func iterate<T>(partition: String, keyspace: String, filter: [String : String]?, iterator: ((T) -> Void)) where T : Decodable, T : Encodable {
        
        var f: String = ""
        if let filter = filter, filter.isEmpty == false {
            for kvp in filter {
                let value = "\(kvp.key)=\(kvp.value)".md5()
                f += " AND filter LIKE '%\(value)%' "
            }
        }
        
        iterate(sql: "SELECT value FROM Data WHERE (ttl IS NULL OR ttl >= ?) \(f) ORDER BY timestamp ASC;", params: [ttl_now], iterator: iterator)
        
    }
    
    @discardableResult
    public func all<T>(partition: String, keyspace: String, filter: [String : String]?) -> [T] where T : Decodable, T : Encodable {
        do {
            
            var f: String = ""
            if let filter = filter, filter.isEmpty == false {
                for kvp in filter {
                    let value = "\(kvp.key)=\(kvp.value)".md5()
                    f += " AND filter LIKE '%\(value)%' "
                }
            }
            
            let data = try query(sql: "SELECT \"\", \"\", id, value FROM Data WHERE (ttl IS NULL OR ttl >= ?) \(f) ORDER BY timestamp ASC;", params: [ttl_now])
            var aggregation: [Data] = []
            for d in data.map({ $0.value }) {
                if config.aes256encryptionKey == nil {
                    if let objectData = d {
                        aggregation.append(objectData)
                    }
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            if let encryptedData = d {
                                let objectData = try aes.decrypt(encryptedData.bytes)
                                aggregation.append(Data(objectData))
                            }
                        } catch {
                            print("encryption error: \(error)")
                        }
                    }
                }
            }
            let opener = "[".data(using: .utf8)!
            let closer = "]".data(using: .utf8)!
            let separater = ",".data(using: .utf8)!
            var fullData = opener
            fullData.append(contentsOf: aggregation.joined(separator: separater))
            fullData.append(closer)
            if let results = try? JSONDecoder().decode([T].self, from: fullData) {
                return results
            } else {
                var results: [T] = []
                for v in aggregation {
                    if let object = try? JSONDecoder().decode(T.self, from: v) {
                        results.append(object)
                    }
                }
                return results
            }
        } catch  {
            return []
        }
    }
    
    fileprivate func bind(stmt: OpaquePointer?, params:[Any?]) {
        
        var paramCount = sqlite3_bind_parameter_count(stmt)
        let passedIn = params.count
        
        if(Int(paramCount) != passedIn) {
            // error
        }
        
        paramCount = 1;
        
        for v in params {
            
            if v != nil {
                
                if let s = v! as? String {
                    sqlite3_bind_text(stmt,paramCount,s,Int32(s.count),SQLITE_TRANSIENT)
                } else if let u = v! as? UUID {
                    sqlite3_bind_blob(stmt, paramCount, u.asData().bytes, Int32(u.asData().bytes.count), SQLITE_TRANSIENT)
                } else if let b = v! as? Data {
                    sqlite3_bind_blob(stmt, paramCount,b.bytes,Int32(b.count), SQLITE_TRANSIENT)
                } else if let d = v! as? Double {
                    sqlite3_bind_double(stmt, paramCount, d)
                } else if let f = v! as? Float {
                    sqlite3_bind_double(stmt, paramCount, NSNumber(value: f).doubleValue)
                } else if let i = v! as? Int {
                    sqlite3_bind_int64(stmt, paramCount, Int64(i))
                } else if let i = v! as? Int64 {
                    sqlite3_bind_int64(stmt, paramCount, i)
                } else {
                    let s = "\(v!)"
                    sqlite3_bind_text(stmt, paramCount, s,Int32(s.count) , SQLITE_TRANSIENT)
                }
                
            } else {
                sqlite3_bind_null(stmt, paramCount)
            }
            
            paramCount += 1
            
        }
        
    }
    
}

fileprivate extension UUID {
    func asData() -> Data {
        func asUInt8Array() -> [UInt8] {
            let (u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16) = self.uuid
            return [u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16]
        }
        return Data(asUInt8Array())
    }
}

fileprivate extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}
