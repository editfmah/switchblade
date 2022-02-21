//
//  SQLiteHighPerformanceProvider.swift
//  
//
//  Created by Adrian Herridge on 21/02/2022.
//

import Foundation

import CSQLite
import Dispatch
import CryptoSwift

fileprivate let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
fileprivate let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public class SQLiteHighPerformanceProvider: DataProvider, DataProviderPrivate {
        
    public var config: SwitchbladeConfig!
    public weak var blade: Switchblade!
    fileprivate var schemalock = Mutex()
    fileprivate var schemaseen: [Data] = []
    fileprivate var schemalocks: [Data:Mutex] = [:]
    
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
        
    }
    
    public func close() throws {
        sqlite3_close(db)
        db = nil;
    }
    
    fileprivate func obtainLock(keyspace: Data) -> Mutex {
        
        var lock: Mutex?
        
        schemalock.mutex {
            lock = schemalocks[keyspace]
        }
        
        // deliberately fragile to promote correct order of execution
        return lock!
        
    }
    
    fileprivate func makeTableNames(keyspace: Data) -> (data: String, records: String) {
        
        let names: (data: String, records: String) = ("data_\(keyspace.md5().toHexString())","records_\(keyspace.md5().toHexString())")
        
        schemalock.mutex {
            if schemaseen.contains(keyspace) == false {
                
                // setup lock
                schemalocks[keyspace] = Mutex()
                schemaseen.append(keyspace)
                
                // tables
                _ = try? self.execute(keyspace: keyspace, sql: "CREATE TABLE IF NOT EXISTS \(names.data) (id BLOB PRIMARY KEY, value BLOB);", params: [])
                _ = try? self.execute(keyspace: keyspace, sql: "CREATE TABLE IF NOT EXISTS \(names.records) (id BLOB PRIMARY KEY, keyspace BLOB);", params: [])
                
                // indexes
                _ = try? self.execute(keyspace: keyspace, sql: "CREATE INDEX IF NOT EXISTS idx_\(names.records)_keyspace ON \(names.records) (keyspace);", params: [])
            }
            return
        }
        
        return names
        
    }
    
    fileprivate func makeId(_ key: Data,_ keyspace: Data) -> Data {
        var id = Data(key)
        id.append(keyspace)
        return id.sha224()
    }
    
    fileprivate func hashParam(_ key: Data,_ paramValue: Any?) -> Data {
        var hash = key
        if let value = paramValue as? Date {
            hash += Data("\(value.timeIntervalSince1970)".bytes)
        } else if let value = paramValue {
            hash += Data("\(value)".bytes)
        }
        return hash.sha256()
    }
    
    public func execute(keyspace: Data, sql: String, params:[Any?]) throws {
        
        try obtainLock(keyspace: keyspace).throwingMutex {
            var values: [Any?] = []
            for o in params {
                values.append(o)
            }
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil) == SQLITE_OK {
                
                bind(stmt: stmt, params: values);
                
                while true {
                    let result = sqlite3_step(stmt)
                    if result == SQLITE_OK || result == SQLITE_DONE {
                        // everything was fine
                        break
                    } else if result == SQLITE_MISUSE {
                        // urgh, fail hard
                        assertionFailure("Switchblade internal error: SQLITE_MISUSE")
                        break
                    } else if result == SQLITE_BUSY {
                        Thread.sleep(forTimeInterval: 0.005)
                        sqlite3_reset(stmt)
                    } else {
                        assertionFailure("Switchblade internal error: SQLITE error \(result)")
                    }
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
    
    fileprivate func query(keyspace: Data, sql: String, params:[Any?]) throws -> [Data?] {
        
        if let results = try obtainLock(keyspace: keyspace).throwingMutex ({ () -> [Data?] in
            
            var results: [Data?] = []
            
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
                        var value: Data?
                        let i = 0
                        switch sqlite3_column_type(stmt, Int32(i)) {
                        case SQLITE_BLOB:
                            let d = Data(bytes: sqlite3_column_blob(stmt, Int32(i)), count: Int(sqlite3_column_bytes(stmt, Int32(i))))
                            value = d
                        default:
                            value = nil
                            break;
                        }
                        results.append(value)
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
    
    public func query(keyspace: Data, sql: String, parameters:[Any?]) -> [[Any?]] {
        
        var results: [[Any?]] = []
        
        obtainLock(keyspace: keyspace).mutex {
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
        return true
    }
    
    func put(key: Data, keyspace: Data, object: Data?, queryKeys: [Data]?) -> Bool {
        
            let id = makeId(key, keyspace)
            let names = makeTableNames(keyspace: keyspace)
            do {
                if config.aes256encryptionKey == nil {
                    try execute(keyspace: keyspace, sql: "INSERT OR REPLACE INTO \(names.data) (id,value) VALUES (?,?);", params: [id,object])
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            // look at dealing with null assignment here
                            let encryptedData = Data(try aes.encrypt(object!.bytes))
                            try execute(keyspace: keyspace, sql: "INSERT OR REPLACE INTO \(names.data) (id,value) VALUES (?,?);", params: [id,encryptedData])
                        } catch {
                            assertionFailure("encryption error: \(error)")
                        }
                    }
                }
                
                try execute(keyspace: keyspace, sql: "INSERT OR REPLACE INTO \(names.records) (id,keyspace) VALUES (?,?)", params: [id,keyspace])
                
                return true
            } catch {
                return false
            }
        
    }

    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        let names = makeTableNames(keyspace: keyspace)
        
        if let jsonObject = try? JSONEncoder().encode(object) {
            let id = makeId(key, keyspace)
            do {
                if config.aes256encryptionKey == nil {
                    try execute(keyspace: keyspace, sql: "INSERT OR REPLACE INTO \(names.data) (id,value) VALUES (?,?);", params: [id,jsonObject])
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
                            try execute(keyspace: keyspace, sql: "INSERT OR REPLACE INTO \(names.data) (id,value) VALUES (?,?);", params: [id,encryptedData])
                        } catch {
                            print("encryption error: \(error)")
                        }
                    }
                }
                
                try execute(keyspace: keyspace, sql: "INSERT OR REPLACE INTO \(names.records) (id,keyspace) VALUES (?,?)", params: [id,keyspace])
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    public func delete(key: Data, keyspace: Data) -> Bool {
        let id = makeId(key, keyspace)
        let names = makeTableNames(keyspace: keyspace)
        do {
            try execute(keyspace: keyspace, sql: "DELETE FROM \(names.data) WHERE id = ?;", params: [id])
            try execute(keyspace: keyspace, sql: "DELETE FROM \(names.records) WHERE id = ?;", params: [id])
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func get<T>(key: Data, keyspace: Data) -> T? where T : Decodable, T : Encodable {
        let id = makeId(key, keyspace)
        let names = makeTableNames(keyspace: keyspace)
        do {
            if config.aes256encryptionKey == nil {
                if let data = try query(keyspace: keyspace, sql: "SELECT value FROM \(names.data) WHERE id = ?", params: [id]).first, let objectData = data {
                    let object = try decoder.decode(T.self, from: objectData)
                    return object
                }
            } else {
                if let data = try query(keyspace: keyspace, sql: "SELECT value FROM \(names.data) WHERE id = ?", params: [id]).first, let objectData = data, let encKey = config.aes256encryptionKey {
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
            if let data = try? query(keyspace: keyspace, sql: "SELECT value FROM \(names.data) WHERE id = ?", params: [id]).first, let objectData = data, let body = String(data: objectData, encoding: .utf8) {
                
                debugPrint("Object data:")
                debugPrint(body)
                
            }
        }
        return nil
    }
    
    @discardableResult
    public func query<T>(keyspace: Data, params: [param]?) -> [T] where T : Decodable, T : Encodable {
        let results: [T] = []
        return results
    }
    
    @discardableResult
    public func all<T>(keyspace: Data) -> [T] where T : Decodable, T : Encodable {
        do {
            let names = makeTableNames(keyspace: keyspace)
            let data = try query(keyspace: keyspace, sql: "SELECT value FROM \(names.data) WHERE id IN (SELECT id FROM \(names.records) WHERE keyspace = ?);", params: [keyspace])
            var aggregation: [Data] = []
            for d in data {
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
