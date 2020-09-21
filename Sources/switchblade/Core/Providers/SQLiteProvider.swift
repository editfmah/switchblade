//
//  SQLiteProvider.swift
//  SwiftyShark
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

public class SQLiteProvider: DataProvider {
    
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
        _ = try self.execute(sql: "CREATE TABLE IF NOT EXISTS QueriableData (id BLOB PRIMARY KEY, keyspace BLOB, key TEXT, value TEXT);", params: [])
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
    
    fileprivate func execute(sql: String, params:[Any?]) throws {
        
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
            throw DatabaseError.Execute(.SyntaxError("\(String(cString: sqlite3_errmsg(db)))"))
        }
        
        sqlite3_finalize(stmt)
        
    }
    
    fileprivate func query(sql: String, params:[Any?]) throws -> [Data?] {
        
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
            throw DatabaseError.Query(.SyntaxError("\(String(cString: sqlite3_errmsg(db)))"))
        }
    
        sqlite3_finalize(stmt)
        
        return results
        
    }
    
    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        if let data = try? JSONEncoder().encode(object) {
            let id = makeId(key, keyspace)
            do {
                try execute(sql: "INSERT OR REPLACE INTO Data (id,value) VALUES (?,?); INSERT OR REPLACE INTO Records (id,keyspace) VALUES (?,?)", params: [id,data,id,keyspace])
                if let queryableObject = object as? Queryable {
                    //QueriableData (id BLOB PRIMARY KEY, keyspace BLOB, key TEXT, value TEXT)
                    try? execute(sql: "DELETE FROM QueriableData WHERE id = ?;", params: [id])
                    for kv in queryableObject.queryableItems {
                        try? execute(sql: "INSERT OR REPLACE INTO QueriableData (id,keyspace,key,value) VALUES (?,?,?,?);", params: [id,keyspace,kv.key, kv.value])
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
            try execute(sql: "DELETE FROM QueriableData WHERE id = ?;", params: [id])
            try execute(sql: "DELETE FROM Data WHERE id = ?;", params: [id])
            try execute(sql: "DELETE FROM Records WHERE id = ?;", params: [id])
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func get<T>(key: Data, keyspace: Data, _ closure: ((T?, DatabaseError?) -> T?)) -> T? where T : Decodable, T : Encodable {
        let id = makeId(key, keyspace)
        do {
            if let data = try query(sql: "SELECT value FROM Data WHERE id = ?", params: [id]).first, let objectData = data, let object = try? decoder.decode(T.self, from: objectData){
                return closure(object,nil)
            } else {
                return closure(nil,nil)
            }
        } catch {
            return closure(nil, nil)
        }
    }
    
    @discardableResult
    public func query<T>(keyspace: Data, params: [param]?, _ closure: (([T], DatabaseError?) -> [T]?)) -> [T]? where T : Decodable, T : Encodable {
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
            whereSql += " WHERE "
            var wheres: [String] = []
            for p in params ?? [] {
                switch p {
                case .where(let key, let op, let param):
                    switch op {
                    case .equals:
                        wheres.append("(key = ? AND value = ?)")
                        whereParams.append(key)
                        whereParams.append(param)
                    case .greater:
                        wheres.append("(key = ? AND value > ?)")
                        whereParams.append(key)
                        whereParams.append(param)
                    case .isnotnull:
                        wheres.append("(key = ? AND value IS NOT NULL)")
                        whereParams.append(key)
                        whereParams.append(param)
                    case .isnull:
                        wheres.append("(key = ? AND value IS NULL)")
                        whereParams.append(key)
                        whereParams.append(param)
                    case .less:
                        wheres.append("(key = ? AND value < ?)")
                        whereParams.append(key)
                        whereParams.append(param)
                    }
                    break;
                default:
                    break
                }
            }
            whereSql += wheres.joined(separator: " AND ")
        }
        do {
            let data = try query(sql: "SELECT value FROM Data WHERE id IN (SELECT id FROM QueriableData \(whereSql) );", params: [whereParams])
            for d in data {
                if let objectData = d, let object = try? decoder.decode(T.self, from: objectData) {
                    results.append(object)
                }
            }
            return closure(results,nil)
        } catch  {
            return closure([],nil)
        }
    }
    
    @discardableResult
    public func all<T>(keyspace: Data, _ closure: (([T], DatabaseError?) -> [T]?)) -> [T]? where T : Decodable, T : Encodable {
        var results: [T] = []
        do {
            let data = try query(sql: "SELECT value FROM Data WHERE id IN (SELECT id FROM Records WHERE keyspace = ?);", params: [keyspace])
            for d in data {
                if let objectData = d, let object = try? decoder.decode(T.self, from: objectData) {
                    results.append(object)
                }
            }
            return closure(results,nil)
        } catch  {
            return closure([],nil)
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
