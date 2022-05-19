//
//  SQLiteProvider.swift
//
//  Created by Adrian Herridge on 08/05/2019.
//

import Foundation

import CSQLite
import Dispatch
import CryptoSwift

fileprivate let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
fileprivate let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

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
        
        // tables
        _ = try self.execute(sql: """
CREATE TABLE IF NOT EXISTS Data (
    partition TEXT,
    keyspace TEXT,
    id TEXT,
    value BLOB,
    ttl INTEGER,
    timestamp INT,
    querykey1 TEXT,
    queryvalue1 TEXT,
    querykey2 TEXT,
    queryvalue2 TEXT,
    querykey3 TEXT,
    queryvalue3 TEXT,
    querykey4 TEXT,
    queryvalue4 TEXT,
    PRIMARY KEY (partition,keyspace,id)
);
""", params: [])
        
    }
    
    public func close() throws {
        sqlite3_close(db)
        db = nil;
    }
    
    fileprivate func makeId(_ key: String) -> String {
        return key
    }
    
    fileprivate func hashParam(_ key: String,_ paramValue: Any?) -> Data {
        var hash = key.data(using: .utf8)!
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
    
    func put(partition: String, key: String, keyspace: String, object: Data?, queryKeys: [Data]?, ttl: Int) -> Bool {
        
        var qk1: String? = nil
        var qk2: String? = nil
        var qk3: String? = nil
        var qk4: String? = nil
        
        for kvp in queryKeys ?? [] {
            if qk1 == nil {
                qk1 = paramValue(kvp)
            } else if qk2 == nil {
                qk2 = paramValue(kvp)
            } else if qk3 == nil {
                qk3 = paramValue(kvp)
            } else if qk4 == nil {
                qk4 = paramValue(kvp)
            }
        }
        
        let id = makeId(key)
        do {
            if config.aes256encryptionKey == nil {
                try execute(sql: "INSERT OR REPLACE INTO Data (partition,keyspace,id,value,ttl,querykey1,querykey2,querykey3,querykey4,queryvalue1,queryvalue2,queryvalue3,queryvalue4,timestamp) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);", params: [partition,keyspace,id,object,ttl == -1 ? nil : Int(Date().timeIntervalSince1970) + ttl,qk1,qk2,qk3,qk4,nil,nil,nil,nil,Int(Date().timeIntervalSince1970)])
            } else {
                // this data is to be stored encrypted
                if let encKey = config.aes256encryptionKey {
                    let key = encKey.sha256()
                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                    do {
                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                        // look at dealing with null assignment here
                        let encryptedData = Data(try aes.encrypt(object!.bytes))
                        try execute(sql: "INSERT OR REPLACE INTO Data (partition,keyspace,id,value,ttl,querykey1,querykey2,querykey3,querykey4,queryvalue1,queryvalue2,queryvalue3,queryvalue4,timestamp) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);", params: [partition,keyspace,id,encryptedData,ttl == -1 ? nil : Int(Date().timeIntervalSince1970) + ttl,qk1,qk2,qk3,qk4,nil,nil,nil,nil,Int(Date().timeIntervalSince1970)])
                    } catch {
                        assertionFailure("encryption error: \(error)")
                    }
                }
            }
            return true
        } catch {
            return false
        }
        
    }
    
    fileprivate func paramValue(_ value: Any?) -> String? {
        if let value = value {
            if let v = value as? String {
                return v
            } else if let v = value as? Int {
                return "\(v)"
            } else if let v = value as? Double {
                return "\(v)"
            } else if let v = value as? Date {
                return "\(v.timeIntervalSince1970)"
            } else if let v = value as? Data {
                return "\(v.base64EncodedString())"
            } else if let v = value as? Bool {
                return "\(v)"
            } else if let v = value as? UUID {
                return "\(v.uuidString.lowercased())"
            } else {
                return "\(value)"
            }
        } else {
            return nil
        }
    }
    
    public func put<T>(partition: String, key: String, keyspace: String, ttl: Int, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        var qk1: String? = nil
        var qk2: String? = nil
        var qk3: String? = nil
        var qk4: String? = nil
        var qv1: String? = nil
        var qv2: String? = nil
        var qv3: String? = nil
        var qv4: String? = nil
        
        if let queryableObject = object as? Queryable {
            for kvp in queryableObject.queryableItems {
                if qk1 == nil {
                    qk1 = kvp.key
                    qv1 = paramValue(kvp.value)
                } else if qk2 == nil {
                    qk2 = kvp.key
                    qv2 = paramValue(kvp.value)
                } else if qk3 == nil {
                    qk3 = kvp.key
                    qv3 = paramValue(kvp.value)
                } else if qk4 == nil {
                    qk4 = kvp.key
                    qv4 = paramValue(kvp.value)
                }
            }
        }
        
        if let jsonObject = try? JSONEncoder().encode(object) {
            let id = makeId(key)
            do {
                if config.aes256encryptionKey == nil {
                    try execute(sql: "INSERT OR REPLACE INTO Data (partition,keyspace,id,value,ttl,querykey1,querykey2,querykey3,querykey4,queryvalue1,queryvalue2,queryvalue3,queryvalue4,timestamp) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);", params: [partition,keyspace,id,jsonObject,ttl == -1 ? nil : Int(Date().timeIntervalSince1970) + ttl,qk1,qk2,qk3,qk4,qv1,qv2,qv3,qv4,Int(Date().timeIntervalSince1970)])
                } else {
                    // this data is to be stored encrypted
                    if let encKey = config.aes256encryptionKey {
                        let key = encKey.sha256()
                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
                        do {
                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                            let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
                            try execute(sql: "INSERT OR REPLACE INTO Data (partition,keyspace,id,value,ttl,querykey1,querykey2,querykey3,querykey4,queryvalue1,queryvalue2,queryvalue3,queryvalue4,timestamp) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);", params: [partition,keyspace,id,encryptedData,ttl == -1 ? nil : Int(Date().timeIntervalSince1970) + ttl,qk1,qk2,qk3,qk4,qv1,qv2,qv3,qv4,Int(Date().timeIntervalSince1970)])
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
            try execute(sql: "DELETE FROM Data WHERE partition = ? AND keyspace = ? AND id = ?;", params: [partition, keyspace, key])
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func get<T>(partition: String, key: String, keyspace: String) -> T? where T : Decodable, T : Encodable {
        do {
            if config.aes256encryptionKey == nil {
                if let data = try query(sql: "SELECT value FROM Data WHERE partition = ? AND keyspace = ? AND id = ?", params: [partition,keyspace,key]).first, let objectData = data {
                    let object = try decoder.decode(T.self, from: objectData)
                    return object
                }
            } else {
                if let data = try query(sql: "SELECT value FROM Data WHERE partition = ? AND keyspace = ? AND id = ?", params: [partition,keyspace,key]).first, let objectData = data, let encKey = config.aes256encryptionKey {
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
            if let data = try? query(sql: "SELECT value FROM Data WHERE partition = ? AND keyspace = ? AND id = ?", params: [partition,keyspace,key]).first, let objectData = data, let body = String(data: objectData, encoding: .utf8) {
                
                debugPrint("Object data:")
                debugPrint(body)
                
            }
        }
        return nil
    }
    
    @discardableResult
    public func query<T>(partition: String, keyspace: String, params: [param]?) -> [T] where T : Decodable, T : Encodable {
        var results: [T] = []
        
        var whereParams: [Any?] = [partition,keyspace]
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
        var wheres: [String] = []
        var whereSql = ""
        if foundWhere {
            
            var idx = 0
            for p in params ?? [] {
                switch p {
                case .where(let key, let op, let param):
                    switch op {
                    case .equals:
                        if config.hashQueriableProperties {
                            wheres.append("((querykey1 = ? OR querykey2 = ? OR querykey3 = ? OR querykey4 = ?))")
                            let v = hashParam(key, param)
                            whereParams.append(v)
                            whereParams.append(v)
                            whereParams.append(v)
                            whereParams.append(v)
                        } else {
                            wheres.append("((querykey1 = ? AND queryvalue1 = ?) OR (querykey2 = ? AND queryvalue2 = ?) OR (querykey3 = ? AND queryvalue3 = ?) OR (querykey4 = ? AND queryvalue4 = ?))")
                            whereParams.append(key)
                            whereParams.append(paramValue(param))
                            whereParams.append(key)
                            whereParams.append(paramValue(param))
                            whereParams.append(key)
                            whereParams.append(paramValue(param))
                            whereParams.append(key)
                            whereParams.append(paramValue(param))
                        }
                    case .greater:
                        wheres.append("((queryKey1 = ? AND cast(queryvalue1 as real) > cast(? as real)) OR (queryKey2 = ? AND cast(queryvalue2 as real) > cast(? as real)) OR (queryKey3 = ? AND cast(queryvalue3 as real) > cast(? as real)) OR (queryKey4 = ? AND cast(queryvalue4 as real) > cast(? as real)))")
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                    case .isnotnull:
                        wheres.append("((querykey1 = ? AND queryvalue1 IS NOT NULL) OR (querykey2 = ? AND queryvalue2 IS NOT NULL) OR (querykey3 = ? AND queryvalue3 IS NOT NULL) OR (querykey4 = ? AND queryvalue4 IS NOT NULL))")
                        whereParams.append(key)
                        whereParams.append(key)
                        whereParams.append(key)
                        whereParams.append(key)
                    case .isnull:
                        wheres.append("((querykey1 = ? AND queryvalue1 IS NULL) OR (querykey2 = ? AND queryvalue2 IS NULL) OR (querykey3 = ? AND queryvalue3 IS NULL) OR (querykey4 = ? AND queryvalue4 IS NULL))")
                        whereParams.append(key)
                        whereParams.append(key)
                        whereParams.append(key)
                        whereParams.append(key)
                    case .less:
                        wheres.append("((queryKey1 = ? AND cast(queryvalue1 as real) < cast(? as real)) OR (queryKey2 = ? AND cast(queryvalue2 as real) < cast(? as real)) OR (queryKey3 = ? AND cast(queryvalue3 as real) < cast(? as real)) OR (queryKey4 = ? AND cast(queryvalue4 as real) < cast(? as real)))")
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                        whereParams.append(key)
                        whereParams.append(paramValue(param))
                    }
                    idx += 1
                    break;
                default:
                    break
                }
            }
            
            whereSql = " AND "
            whereSql += wheres.joined(separator: " AND ")
        }
        do {
            // urgh, this is complex, but works well in fact
            // SELECT QD1.recid FROM QueriableData as QD1 JOIN QueriableData AS QD2 on QD1.recid = QD2.recid JOIN QueriableData AS QD3 on QD2.recid = QD3.recid WHERE (QD1.key = "age" AND QD1.value = 40) AND (QD2."key" = "name" AND QD2.value = "adrian") AND (QD3.key = "surname" AND QD3.value = "herridge")
            let data = try query(sql: "SELECT value FROM Data WHERE (partition = ? AND keyspace = ?) \(whereSql);", params: whereParams)
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
    public func all<T>(partition: String, keyspace: String) -> [T] where T : Decodable, T : Encodable {
        do {
            let data = try query(sql: "SELECT value FROM Data WHERE partition = ? AND keyspace = ? ORDER BY timestamp ASC;", params: [partition, keyspace])
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
