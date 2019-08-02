//
//  CassandraProvider.swift
//  Core
//
//  Created by Adrian Herridge on 19/07/2019.
//

import Foundation
import Kassandra
import CryptoSwift
#if os(Linux)
import CSQLiteLinux
#else
import CSQLiteDarwin
#endif
import Dispatch

public class CassandraProvider: DataProvider {
    
    var db: Kassandra!
    var ks: String
    var opened: Bool = false
    public var structure: [String:[String:DataType]] = [:]
    public var conversion: [String:[String:String]] = [:]
    public var pks: [String:String] = [:]
    public var idxs: [String:[String]] = [:]
    public var table_alias: [String:String] = [:]
    public init(keyspace: String, host: String, port: Int32) {
        
        db = Kassandra(host: host, port: port)
        ks = keyspace
        
    }
    
    public func open() throws {
        
        var error: DatabaseError?
        let waiter = DispatchSemaphore(value: 0)
        
        try? db.connect(oncompletion: { (result) in
            if result.success == false {
                error = DatabaseError.Init(DatabaseInitError.UnableToConnectToServer)
            } else {
                self.opened = true
            }
            waiter.signal()
        })
        
        waiter.wait()
        
        if error != nil {
            throw error!
        }
        
    }
    
    public func close() {
        db = nil
    }
    
    private func bindParametersIntoStatement(_ sql: String, params: [Value]) -> String {
        
        //  go through the statement and insert the parameters
        // TODO:  Ensure no insertion attacks can happen
        var values = params
        var compiled = ""
        for c in sql {
            if c == "?" {
                if values.count > 0 {
                    let p = values.remove(at: 0)
                    switch p.type {
                    case .String:
                        let s = p.stringValue!
                        compiled += "'\(s.replacingOccurrences(of: "'", with: ""))'"
                    case .UUID:
                        let s = p.uuidValue!.uuidString
                        compiled += s
                    case .Null:
                        compiled += "NULL"
                    case .Blob:
                        let d = p.blobValue
                        compiled += "0x\(d!.toHexString().uppercased())"
                    case .Double:
                        compiled += "\(p.numericValue.doubleValue)"
                    case .Int:
                        compiled += "\(p.numericValue.int64Value)"
                    }
                }
            } else {
                compiled += "\(c)"
            }
        }
        
        return compiled
        
    }
    
    public func execute(sql: String, params:[Any?], silenceErrors: Bool, completion: ((_ success: Bool, _ error: DatabaseError?) -> Void)?) -> Void {
        
        var values: [Value] = []
        for o in params {
            values.append(Value(o))
        }
        
        let statement = bindParametersIntoStatement(sql, params: values)
        db.execute(statement) { (result) in
            if result.success == false {
                completion?(false, DatabaseError.Execute(.SyntaxError("\(result)\nFrom CQL\n\(statement)")))
            } else {
                completion?(true, nil)
            }
        }
        
    }
    
    public func executeSync(sql: String, params:[Any?], silenceErrors: Bool) throws -> Bool {
        
        var err: DatabaseError?
        
        var values: [Value] = []
        for o in params {
            values.append(Value(o))
        }
        
        let statement = bindParametersIntoStatement(sql, params: values)
        let waiter = DispatchSemaphore(value: 0)
        db.execute(statement) { (result) in
            if result.success == false {
                
                if silenceErrors {
                    err = nil
                } else {
                    err = DatabaseError.Execute(.SyntaxError("\(result)"))
                }
                
            } else {
                err = nil
            }
            waiter.signal()
        }
        waiter.wait()
        
        if err != nil {
            throw err!
        }
        
        return true
        
    }
    
    public func create<T>(_ object: T, pk: String, auto: Bool, indexes: [String]) throws where T: Codable {
        
        if !opened {
            throw DatabaseError.Init(.UnableToConnectToServer)
        }
        
        let mirror = Mirror(reflecting: object)
        var name = "\("\(mirror)".split(separator: " ").last!)"
        if table_alias[name] != nil {
            name = table_alias[name]!
        }
        
        // find the pk, examine the type and create the table
        for c in mirror.children {
            if c.label != nil {
                if c.label! == pk {
                    
                    let propMirror = Mirror(reflecting: c.value)
                    if propMirror.subjectType == String?.self {
                        _ = try self.executeSync(sql: "CREATE COLUMNFAMILY IF NOT EXISTS \(ks).\(name) (\(pk) text, PRIMARY KEY(\(pk)));", params: [], silenceErrors: true)
                    } else if (propMirror.subjectType == UUID?.self || propMirror.subjectType == UUID.self){
                        _ = try self.executeSync(sql: "CREATE COLUMNFAMILY IF NOT EXISTS \(ks).\(name) (\(pk) uuid, PRIMARY KEY(\(pk)));", params: [], silenceErrors: true)
                    } else if propMirror.subjectType == Int?.self {
                        _ = try self.executeSync(sql: "CREATE COLUMNFAMILY IF NOT EXISTS \(ks).\(name) (\(pk) bigint, PRIMARY KEY(\(pk)));", params: [], silenceErrors: true)
                    }
                    
                    pks[name] = pk
                    structure[name] = [:]
                    conversion[name] = [:]
                    idxs[name] = [pk.lowercased()]
                    
                }
            }
        }
        
        for c in mirror.children {
            
            if c.label != nil {
                
                conversion[name]!["\(c.label!.lowercased())"] = c.label!
                
                let propMirror = Mirror(reflecting: c.value)
                if propMirror.subjectType == String?.self {
                    structure[name]!["\(c.label!)"] = .String
                    _ = try self.executeSync(sql: "ALTER TABLE \(ks).\(name) ADD (\(c.label!) text);", params: [], silenceErrors:true)
                } else if propMirror.subjectType == Int?.self || propMirror.subjectType == UInt64?.self || propMirror.subjectType == UInt?.self || propMirror.subjectType == Int64?.self {
                    structure[name]!["\(c.label!)"] = .Int
                    _ = try self.executeSync(sql: "ALTER TABLE \(ks).\(name) ADD (\(c.label!) bigint)", params: [], silenceErrors:true)
                } else if propMirror.subjectType == Double?.self {
                    structure[name]!["\(c.label!)"] = .Double
                    _ = try self.executeSync(sql: "ALTER TABLE \(ks).\(name) ADD (\(c.label!) double)", params: [], silenceErrors:true)
                } else if propMirror.subjectType == Data?.self {
                    structure[name]!["\(c.label!)"] = .Blob
                    _ = try self.executeSync(sql: "ALTER TABLE \(ks).\(name) ADD (\(c.label!) blob)", params: [], silenceErrors:true)
                } else if propMirror.subjectType == UUID?.self {
                    structure[name]!["\(c.label!)"] = .UUID
                    _ = try self.executeSync(sql: "ALTER TABLE \(ks).\(name) ADD (\(c.label!) uuid)", params: [], silenceErrors:true)
                }
            }
            
        }
        
        for i in indexes {
            idxs[name]?.append(i.lowercased())
            _ = try self.executeSync(sql: "CREATE INDEX IF NOT EXISTS idx_\(name)_\(i.replacingOccurrences(of: ",", with: "_")) ON \(ks).\(name) (\(i));", params: [], silenceErrors:true)
        }
        
    }
    
    public func put<T>(_ object: T, completion: ((Bool, DatabaseError?) -> Void)?) where T : Decodable, T : Encodable {
        
        if !opened {
            completion?(false, DatabaseError.Init(.UnableToConnectToServer))
            return
        }
        
        let mirror = Mirror(reflecting: object)
        var name = "\("\(mirror)".split(separator: " ").last!)"
        if table_alias[name] != nil {
            name = table_alias[name]!
        }
        
        var placeholders: [String] = []
        var columns: [String] = []
        var params: [Any?] = []
        let types: [Any.Type] = [String?.self, String.self,Int?.self,Int.self,UInt64?.self,UInt64.self,UInt?.self,UInt.self,Int64?.self,Int64.self,Double?.self,Double.self,Data?.self,Data.self,UUID.self,UUID?.self]
        
        // find the pk, examine the type and create the table
        for c in mirror.children {
            if c.label != nil {
                let propMirror = Mirror(reflecting: c.value)
                for t in types {
                    if t == propMirror.subjectType {
                        
                        placeholders.append("?")
                        params.append(unwrap(c.value))
                        columns.append(c.label!)
                    }
                }
            }
        }
        
        self.execute(sql: "INSERT INTO \(ks).\(name) (\(columns.joined(separator: ","))) VALUES (\(placeholders.joined(separator: ",")))", params: params, silenceErrors: false) { (success, error) in
            completion?(success, error)
            
        }
        
    }
    
    public func query<T>(_ object: T, parameters: [param], completion: (([T], DatabaseError?) -> Void)?) where T : Decodable, T : Encodable {
        
        if !opened {
            completion?([], DatabaseError.Init(.UnableToConnectToServer))
            return
        }
        
        let mirror = Mirror(reflecting: object)
        var name = "\("\(mirror)".split(separator: " ").last!)"
        if table_alias[name] != nil {
            name = table_alias[name]!
        }
        
        let memSqliteProvider = Switchblade(provider: SQLiteProvider(path: ":memory:")) { (success, provider, error) in
            var prov = provider
            prov.table_alias = self.table_alias
        }
        // now create the table
        _ = try? memSqliteProvider.create(object, pk: pks[name]!, auto: false, indexes: [])
        
        var params: [Any?] = []
        
        // build the conditionals
        var sql = "SELECT * FROM \(ks).\(name) "
        
        // loop to see if there are any where conditions
        var foundWhere = false
        for p in parameters {
            switch p {
            case .where(_, _, _):
                foundWhere = true
                break;
            default:
                break
            }
        }
        
        if foundWhere {
            
            var wheres: [String] = []
            
            // first off, start with primary key or indexed values only
            
            for p in parameters {
                switch p {
                case .where(let column, let op, let param):
                    switch op {
                    case .equals:
                        //debugPrint("query constructed: looking for column '\(column.lowercased())'")
                        if idxs[name]!.contains(column.lowercased()) {
                            //debugPrint("query constructed: found where clause which is indexed")
                            if wheres.count == 0 {
                                //debugPrint("query constructed: adding primary lookup")
                                wheres.append("\(column) = ?")
                                params.append(param)
                            } else {
                                //debugPrint("query constructed: indexed where clause already found")
                            }
                        }
                        break;
                    default:
                        break
                    }
                default:
                    break
                }
            }
            if wheres.count > 0 {
                sql += " WHERE "
                sql += wheres.joined(separator: " AND ")
            }
            
        } else {
            
            //debugPrint("query constructed: where clause not found")
            //debugPrint("query constructed: count of params, \(parameters.count)")
            
        }
        
        sql += ";"
        
        // now call the async methods and nest the processing of responses
        
        query(sql: sql, params: params) { (result, error) in
            
            if error != nil {
                
                completion?([], error)
                
            } else {
                
                let r = result
                
                var results: [T] = []
                
                for record in r.results {
                    
                    //debugPrint("query constructed: found record match")
                    //debugPrint("query constructed: \(record)")
                    
                    let decoder = JSONDecoder()
                    decoder.dataDecodingStrategy = .base64
                    
                    var row: [String] = []
                    
                    for k in record.keys {
                        
                        let kp = self.conversion[name]![k.lowercased()]!
                        
                        switch record[k]!.getType() {
                        case .Null:
                            row.append("\"\(kp)\" : null")
                            break
                        case .Blob:
                            row.append("\"\(kp)\" : \"\(record[k]!.asData()!.base64EncodedString())\"")
                            break
                        case .Double:
                            row.append("\"\(kp)\" : \(unwrap(record[k]!.asDouble())!)")
                            break
                        case .Int:
                            row.append("\"\(kp)\" : \(unwrap(record[k]!.asInt())!)")
                            break
                        case .String:
                            row.append("\"\(kp)\" : \"\(unwrap(record[k]!.asString())!)\"")
                            break
                        case .UUID:
                            row.append("\"\(kp)\" : \"\(unwrap(record[k]!.asString())!)\"")
                            break
                        }
                    }
                    
                    var jsonString = "{\(row.joined(separator: ","))}"
                    
                    //print("json: \(jsonString)")
                    
                    do {
                        let rowObject: T = try decoder.decode(T.self, from: Data(Array(jsonString.utf8)))
                        results.append(rowObject)
                    } catch {
                        //print("JSON causing the issue: \n\n\(jsonString)\n")
                        print(error)
                    }
                    
                    
                }
                
                // now we have the results, jam this into a memory SQLITE database to get all the sorting, filtering & limiting sorted out
                for r in results {
                    _ = try? memSqliteProvider.put(r)
                }
                
                memSqliteProvider.query(object, parameters, completion: { (tObjects, error) in
                    completion?(tObjects,error)
                })

            }
            
        }
        
    }
    
    public func delete<T>(_ object: T, parameters: [param], completion: ((Bool, DatabaseError?) -> Void)?) where T : Decodable, T : Encodable {
        
        query(object, parameters: parameters) { (results, error) in
            for m in results {
                _ = self.delete(m, completion: nil)
            }
        }
        
    }
    
    public func delete<T>(_ object: T, completion: ((Bool, DatabaseError?) -> Void)?) where T : Decodable, T : Encodable {
        
        if !opened {
            return
        }
        
        let mirror = Mirror(reflecting: object)
        var name = "\("\(mirror)".split(separator: " ").last!)"
        if table_alias[name] != nil {
            name = table_alias[name]!
        }
        let n = name
        let pk = pks[n]!
        var pkValue: Any?
        
        let types: [Any.Type] = [String?.self, String.self,Int?.self,Int.self,UInt64?.self,UInt64.self,UInt?.self,UInt.self,Int64?.self,Int64.self,Double?.self,Double.self,Data?.self,Data.self,UUID.self,UUID?.self]
        
        // find the pk, examine the type and create the table
        for c in mirror.children {
            if c.label != nil {
                let propMirror = Mirror(reflecting: c.value)
                for t in types {
                    if t == propMirror.subjectType {
                        
                        if pk.lowercased() == c.label!.lowercased() {
                            // this is the pk
                            pkValue = unwrap(c.value)
                        }
                        
                    }
                }
            }
        }
        
        self.execute(sql: "DELETE FROM \(ks).\(n) WHERE \(pk) = ?", params: [pkValue], silenceErrors: false) { (success, error) in
            completion?(success,error)
        }
        
    }

    
    public func query(sql: String, params:[Any?], completion: ((_ results: Result, _ error: DatabaseError?) -> Void)?) {
        
        if !opened {
            completion?(Result(), DatabaseError.Init(.UnableToConnectToServer))
            return
        }
        
        let aggResult = Result()
        
        var values: [Value] = []
        for o in params {
            values.append(Value(o))
        }
        
        let statement = bindParametersIntoStatement(sql, params: values)
        
        db.execute(statement) { (result) in
            
            var results: [Record] = []
            
            if result.success == false {
                
                completion?(aggResult, DatabaseError.Unknown)
                
            } else {
                
                for r: Row in result.asRows ?? [] {
                    
                    var rowData: Record = [:]
                    
                    for columnName in r.keys {
                        if r[columnName] != nil {
                            let mirror = Mirror(reflecting: r[columnName]!)
                            //print(mirror)
                            if mirror.subjectType == String.self {
                                let s = r[columnName] as! String
                                if s == "NULL" {
                                    rowData[columnName] = Value(NSNull())
                                } else {
                                    rowData[columnName] = Value(r[columnName])
                                }
                            } else {
                                rowData[columnName] = Value(r[columnName])
                            }
                        } else {
                            rowData[columnName] = Value(NSNull())
                        }
                        
                    }
                    
                    results.append(rowData)
                }
                
                aggResult.results = results
                completion?(aggResult, nil)
                
            }
        }
        
    }
    
}
