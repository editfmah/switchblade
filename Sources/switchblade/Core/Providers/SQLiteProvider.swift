//
//  SQLiteProvider.swift
//
//  Created by Adrian Herridge on 08/05/2019.
//

import Foundation

#if os(Linux)
import CSQLiteLinux
#else
import CSQLiteDarwin
#endif

import Dispatch
import CryptoSwift

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public class SQLiteProvider: DataProvider, DataProviderPrivate {
        
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
        sqlite3_create_function(db, "SHA512", 1, SQLITE_ANY, nil, nil, sha512step, sha512finalize)
        _ = try self.execute(sql: "CREATE TABLE IF NOT EXISTS Data (id BLOB PRIMARY KEY, value BLOB);", params: [])
        _ = try self.execute(sql: "CREATE TABLE IF NOT EXISTS Records (id BLOB PRIMARY KEY, keyspace BLOB);", params: [])
        _ = try self.execute(sql: "CREATE TABLE IF NOT EXISTS QueryableData (recid BLOB PRIMARY KEY, id BLOB, keyspace BLOB, key TEXT, value BLOB);", params: [])
    }
    
    public func close() throws {
        sqlite3_close(db)
        db = nil;
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
    
    public func execute(sql: String, params:[Any?]) throws {
        
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
    
    fileprivate func query(sql: String, params:[Any?]) throws -> [Data?] {
        
        if let results = try lock.throwingMutex ({ () -> [Data?] in
            
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
    
    func put(key: Data, keyspace: Data, object: Data?, queryKeys: [Data]?) -> Bool {
        
            let id = makeId(key, keyspace)
            do {
                if config.aes256encryptionKey == nil {
                    try execute(sql: "INSERT OR REPLACE INTO Data (id,value) VALUES (?,?);", params: [id,object])
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            // look at dealing with null assignment here
                            let encryptedData = Data(try aes.encrypt(object!.bytes))
                            try execute(sql: "INSERT OR REPLACE INTO Data (id,value) VALUES (?,?);", params: [id,encryptedData])
                        } catch {
                            assertionFailure("encryption error: \(error)")
                        }
                    }
                }
                
                try execute(sql: "INSERT OR REPLACE INTO Records (id,keyspace) VALUES (?,?)", params: [id,keyspace])
                if let queryKeys = queryKeys {
                    //QueriableData (id BLOB PRIMARY KEY, keyspace BLOB, key TEXT, value TEXT)
                    try? execute(sql: "DELETE FROM QueryableData WHERE id = ?;", params: [id])
                    for k in queryKeys {
                        try? execute(sql: "INSERT OR REPLACE INTO QueryableData (recid,id,keyspace,key) VALUES (?,?,?,?);", params: [UUID().asData(),id,keyspace,k])
                    }
                }
                return true
            } catch {
                return false
            }
        
    }

    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        if let jsonObject = try? JSONEncoder().encode(object) {
            let id = makeId(key, keyspace)
            do {
                if config.aes256encryptionKey == nil {
                    try execute(sql: "INSERT OR REPLACE INTO Data (id,value) VALUES (?,?);", params: [id,jsonObject])
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
                            try execute(sql: "INSERT OR REPLACE INTO Data (id,value) VALUES (?,?);", params: [id,encryptedData])
                        } catch {
                            print("encryption error: \(error)")
                        }
                    }
                }
                
                try execute(sql: "INSERT OR REPLACE INTO Records (id,keyspace) VALUES (?,?)", params: [id,keyspace])
                if let queryableObject = object as? Queryable {
                    //QueriableData (id BLOB PRIMARY KEY, keyspace BLOB, key TEXT, value TEXT)
                    try? execute(sql: "DELETE FROM QueryableData WHERE id = ?;", params: [id])
                    for kv in queryableObject.queryableItems {
                        if config.hashQueriableProperties == false {
                            try? execute(sql: "INSERT OR REPLACE INTO QueryableData (recid,id,keyspace,key,value) VALUES (?,?,?,?,?);", params: [UUID().asData(),id,keyspace,kv.key, kv.value])
                        } else {
                            // hash the key and value together so data can be queried, but remains anonymous
                            let keyHash = hashParam(kv.key.data(using: .utf8)!, kv.value)
                            try? execute(sql: "INSERT OR REPLACE INTO QueryableData (recid,id,keyspace,key) VALUES (?,?,?,?);", params: [UUID().asData(),id,keyspace,keyHash])
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
    
    public func delete(key: Data, keyspace: Data) -> Bool {
        let id = makeId(key, keyspace)
        do {
            try execute(sql: "DELETE FROM QueryableData WHERE id = ?;", params: [id])
            try execute(sql: "DELETE FROM Data WHERE id = ?;", params: [id])
            try execute(sql: "DELETE FROM Records WHERE id = ?;", params: [id])
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func get<T>(key: Data, keyspace: Data) -> T? where T : Decodable, T : Encodable {
        let id = makeId(key, keyspace)
        do {
            if config.aes256encryptionKey == nil {
                if let data = try query(sql: "SELECT value FROM Data WHERE id = ?", params: [id]).first, let objectData = data, let object = try? decoder.decode(T.self, from: objectData) {
                    return object
                }
            } else {
                if let data = try query(sql: "SELECT value FROM Data WHERE id = ?", params: [id]).first, let objectData = data, let encKey = config.aes256encryptionKey {
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
            
        }
        return nil
    }
    
    @discardableResult
    public func query<T>(keyspace: Data, params: [param]?) -> [T] where T : Decodable, T : Encodable {
        var results: [T] = []
        var whereParams: [Any?] = []
        // loop to see if there are any where conditions
        var foundWhere = false
        for p in params ?? [] {
            switch p {
            case .where(_, _, _):
                foundWhere = true
                break;
            default:
                break
            }
        }
        var whereSql = ""
        if foundWhere {
            whereSql += " QueryableData AS QD0 "
            var wheres: [String] = []
            var idx = 0
            for p in params ?? [] {
                switch p {
                case .where(let key, let op, let param):
                    if idx > 0 {
                        whereSql += " JOIN QueryableData AS QD\(idx) on QD\(idx-1).id = QD\(idx).id "
                    }
                    switch op {
                    case .equals:
                        if config.hashQueriableProperties {
                            wheres.append("(QD\(idx).key = ?)")
                            whereParams.append(hashParam(key.data(using: .utf8)!, param))
                        } else {
                            wheres.append("(QD\(idx).key = ? AND QD\(idx).value = ?)")
                            whereParams.append(key)
                            whereParams.append(param)
                        }
                    case .greater:
                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value > ?)")
                        whereParams.append(key)
                        whereParams.append(param)
                    case .isnotnull:
                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value IS NOT NULL)")
                        whereParams.append(key)
                    case .isnull:
                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value IS NULL)")
                        whereParams.append(key)
                    case .less:
                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value < ?)")
                        whereParams.append(key)
                        whereParams.append(param)
                    }
                    idx += 1
                    break;
                default:
                    break
                }
            }
            
            whereSql += " WHERE "
            whereSql += wheres.joined(separator: " AND ")
        }
        do {
            // urgh, this is complex, but works well in fact
            // SELECT QD1.recid FROM QueriableData as QD1 JOIN QueriableData AS QD2 on QD1.recid = QD2.recid JOIN QueriableData AS QD3 on QD2.recid = QD3.recid WHERE (QD1.key = "age" AND QD1.value = 40) AND (QD2."key" = "name" AND QD2.value = "adrian") AND (QD3.key = "surname" AND QD3.value = "herridge")
            let data = try query(sql: "SELECT value FROM Data WHERE id IN (SELECT QD0.id FROM \(whereSql) );", params: whereParams)
            for d in data {
                if config.aes256encryptionKey == nil {
                    if let objectData = d, let object = try? decoder.decode(T.self, from: objectData) {
                        results.append(object)
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
                                let object = try decoder.decode(T.self, from: Data(objectData))
                                results.append(object)
                            }
                        } catch {
                            print("encryption error: \(error)")
                        }
                    }
                }
            }
            return results
        } catch  {
            return []
        }
    }
    
    @discardableResult
    public func all<T>(keyspace: Data) -> [T] where T : Decodable, T : Encodable {
        var results: [T] = []
        do {
            let data = try query(sql: "SELECT value FROM Data WHERE id IN (SELECT id FROM Records WHERE keyspace = ?);", params: [keyspace])
            for d in data {
                if config.aes256encryptionKey == nil {
                    if let objectData = d, let object = try? decoder.decode(T.self, from: objectData) {
                        results.append(object)
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
                                let object = try decoder.decode(T.self, from: Data(objectData))
                                results.append(object)
                            }
                        } catch {
                            print("encryption error: \(error)")
                        }
                    }
                }
            }
            return results
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

extension UUID{
    public func asData() -> Data {
        func asUInt8Array() -> [UInt8] {
            let (u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16) = self.uuid
            return [u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16]
        }
        return Data(asUInt8Array())
    }
}

extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}
