////
////  PostgresTerminalClient.swift
////  Switchblade
////
////  Created by Adrian Herridge on 17/10/2021.
////
//
//import Foundation
//
//import Dispatch
//import CryptoSwift
//
//public class PostgresTerminalProvider: DataProvider, DataProviderPrivate {
//    
//    public var config: SwitchbladeConfig!
//    public weak var blade: Switchblade!
//    
//    fileprivate var connectionString: String!
//    
//    let decoder: JSONDecoder = JSONDecoder()
//    
//    public init(connectionString: String)  {
//        self.connectionString = connectionString
//    }
//    
//    @discardableResult func shell(_ command: String) -> (String?, Int32) {
//        let task = Process()
//
//        task.launchPath = "/bin/bash"
//        task.arguments = ["-c", command]
//
//        let pipe = Pipe()
//        task.standardOutput = pipe
//        task.standardError = pipe
//        task.launch()
//
//        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: data, encoding: .utf8)
//        task.waitUntilExit()
//        return (output, task.terminationStatus)
//    }
//    
//    // psql --command="SELECT * FROM data;" "postgresql://doadmin:JZU4M03tW8YwtCM0@db-postgresql-sfo3-90118-do-user-2007468-0.b.db.ondigitalocean.com:25060/test?sslmode=require" > output.txt
//    
//    
//    
//    fileprivate func ttyQuery(sql: String) -> Bool {
//        return false
//    }
//    
//    public func open() throws {
//        
//        try execute(sql: "CREAT TABLE IF NOT EXISTS Data (id bytea PRIMARY KEY, value bytea);", params: [])
//        try execute(sql: "CREATE TABLE IF NOT EXISTS Records (id bytea PRIMARY KEY, keyspace bytea);", params: [])
//        try execute(sql: "CREATE TABLE IF NOT EXISTS QueryableData (recid bytea PRIMARY KEY, id bytea, keyspace bytea, key TEXT, value bytea);", params: [])
//        
//    }
//    
//    public func close() throws {
//        
//    }
//    
//    fileprivate func makeId(_ key: Data,_ keyspace: Data) -> Data {
//        var id = Data(key)
//        id.append(keyspace)
//        return id.sha224()
//    }
//    
//    fileprivate func hashParam(_ key: Data,_ paramValue: Any?) -> Data {
//        var hash = key
//        if let value = paramValue as? Date {
//            hash += Data("\(value.timeIntervalSince1970)".bytes)
//        } else if let value = paramValue {
//            hash += Data("\(value)".bytes)
//        }
//        return hash.sha256()
//    }
//    
//    public func execute(sql: String, params:[Any?]) throws {
//        
//        ttyExecute(sql: sql)
//        
//        //        var values: [PostgresValueConvertible?] = []
//        //        for o in params {
//        //            if let value = o as? PostgresValueConvertible {
//        //                values.append(value)
//        //            } else if let value = o as? Data {
//        //                let postgresData = PostgresByteA(data: value)
//        //                values.append(postgresData)
//        //            } else {
//        //                values.append(nil)
//        //            }
//        //        }
//        //
//        //        do {
//        //            let statement = try connection!.prepareStatement(text: sql)
//        //            defer { statement.close() }
//        //
//        //            let cursor = try statement.execute(parameterValues: values)
//        //            defer { cursor.close() }
//        //
//        //        } catch {
//        //            print(error)
//        //            Switchblade.errors[blade.instance] = true
//        //            throw DatabaseError.Execute(.SyntaxError("\(error)"))
//        //        }
//        
//    }
//    
//    fileprivate func query(sql: String, params:[Any?]) throws -> [Data?] {
//        
//        var results: [Data?] = []
//        
//        //        var values: [PostgresValueConvertible?] = []
//        //        for o in params {
//        //            if let value = o as? PostgresValueConvertible {
//        //                values.append(value)
//        //            } else if let value = o as? Data {
//        //                let postgresData = PostgresByteA(data: value)
//        //                values.append(postgresData)
//        //            } else {
//        //                values.append(nil)
//        //            }
//        //        }
//        //
//        //        do {
//        //            let statement = try connection!.prepareStatement(text: sql)
//        //            defer { statement.close() }
//        //
//        //            let cursor = try statement.execute(parameterValues: values)
//        //            defer { cursor.close() }
//        //
//        //            for row in cursor {
//        //                let columns = try row.get().columns
//        //                let data = try columns[0].optionalByteA()?.data
//        //                results.append(data)
//        //            }
//        //
//        //        } catch {
//        //            print(error)
//        //            Switchblade.errors[blade.instance] = true
//        //            throw DatabaseError.Execute(.SyntaxError("\(error)"))
//        //        }
//        
//        return results
//        
//    }
//    
//    public func transact(_ mode: transaction) -> Bool {
//        return true
//    }
//    
//    /*
//     *      insert into dummy(id, name, size) values(1, 'new_name', 3)
//     on conflict(id)
//     do update set name = 'new_name', size = 3;
//     */
//    
//    func put(key: Data, keyspace: Data, object: Data?, queryKeys: [Data]?) -> Bool {
//        
//        let id = makeId(key, keyspace)
//        do {
//            if config.aes256encryptionKey == nil {
//                try execute(sql: "INSERT INTO Data (id,value) VALUES ($1,$2) ON CONFLICT(id) DO UPDATE SET value = $3;", params: [id,object,object])
//            } else {
//                // this data is to be stored encrypted
//                if let encKey = config.aes256encryptionKey {
//                    let key = encKey.sha256()
//                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
//                    do {
//                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
//                        // look at dealing with null assignment here
//                        let encryptedData = Data(try aes.encrypt(object!.bytes))
//                        try execute(sql: "INSERT INTO Data (id,value) VALUES ($1,$2) ON CONFLICT(id) DO UPDATE SET value = $3;", params: [id,encryptedData,encryptedData])
//                    } catch {
//                        assertionFailure("encryption error: \(error)")
//                    }
//                }
//            }
//            
//            try execute(sql: "INSERT INTO Records (id,keyspace) VALUES ($1,$2) ON CONFLICT(id) DO UPDATE SET keyspace = $3;", params: [id,keyspace, keyspace])
//            if let queryKeys = queryKeys {
//                //QueriableData (id BLOB PRIMARY KEY, keyspace BLOB, key TEXT, value TEXT)
//                try? execute(sql: "DELETE FROM QueryableData WHERE id = $1;", params: [id])
//                for k in queryKeys {
//                    try? execute(sql: "INSERT INTO QueryableData (recid,id,keyspace,key) VALUES ($1,$2,$3,$4);", params: [UUID().asData(),id,keyspace,k])
//                }
//            }
//            return true
//        } catch {
//            return false
//        }
//        
//    }
//    
//    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
//        
//        if let jsonObject = try? JSONEncoder().encode(object) {
//            let id = makeId(key, keyspace)
//            do {
//                if config.aes256encryptionKey == nil {
//                    try execute(sql: "INSERT INTO Data (id,value) VALUES ($1,$2) ON CONFLICT(id) DO UPDATE SET value = $3;", params: [id,jsonObject,jsonObject])
//                } else {
//                    // this data is to be stored encrypted
//                    if let encKey = config.aes256encryptionKey {
//                        let key = encKey.sha256()
//                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
//                        do {
//                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
//                            let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
//                            try execute(sql: "INSERT INTO Data (id,value) VALUES ($1,$1) ON CONFLICT(id) DO UPDATE SET value = $3;", params: [id,encryptedData,encryptedData])
//                        } catch {
//                            print("encryption error: \(error)")
//                        }
//                    }
//                }
//                
//                try execute(sql: "INSERT INTO Records (id,keyspace) VALUES ($1,$2) ON CONFLICT(id) DO UPDATE SET keyspace = $3;", params: [id,keyspace, keyspace])
//                if let queryableObject = object as? Queryable {
//                    //QueriableData (id BLOB PRIMARY KEY, keyspace BLOB, key TEXT, value TEXT)
//                    try? execute(sql: "DELETE FROM QueryableData WHERE id = $1;", params: [id])
//                    for kv in queryableObject.queryableItems {
//                        if config.hashQueriableProperties == false {
//                            try? execute(sql: "INSERT INTO QueryableData (recid,id,keyspace,key,value) VALUES ($1,$2,$3,$4,$5);", params: [UUID().asData(),id,keyspace,kv.key, kv.value])
//                        } else {
//                            // hash the key and value together so data can be queried, but remains anonymous
//                            let keyHash = hashParam(kv.key.data(using: .utf8)!, kv.value)
//                            try? execute(sql: "INSERT INTO QueryableData (recid,id,keyspace,key) VALUES ($1,$2,$3,$4);", params: [UUID().asData(),id,keyspace,keyHash])
//                        }
//                    }
//                }
//                return true
//            } catch {
//                return false
//            }
//        }
//        return false
//    }
//    
//    public func delete(key: Data, keyspace: Data) -> Bool {
//        let id = makeId(key, keyspace)
//        do {
//            try execute(sql: "DELETE FROM QueryableData WHERE id = $1;", params: [id])
//            try execute(sql: "DELETE FROM Data WHERE id = $1;", params: [id])
//            try execute(sql: "DELETE FROM Records WHERE id = $1;", params: [id])
//            return true
//        } catch {
//            return false
//        }
//    }
//    
//    @discardableResult
//    public func get<T>(key: Data, keyspace: Data) -> T? where T : Decodable, T : Encodable {
//        let id = makeId(key, keyspace)
//        do {
//            if config.aes256encryptionKey == nil {
//                if let data = try query(sql: "SELECT value FROM Data WHERE id = $1;", params: [id]).first, let objectData = data {
//                    let object = try decoder.decode(T.self, from: objectData)
//                    return object
//                }
//            } else {
//                if let data = try query(sql: "SELECT value FROM Data WHERE id = $1", params: [id]).first, let objectData = data, let encKey = config.aes256encryptionKey {
//                    let key = encKey.sha256()
//                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
//                    do {
//                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
//                        let decryptedBytes = try aes.decrypt(objectData.bytes)
//                        let decryptedData = Data(decryptedBytes)
//                        let object = try decoder.decode(T.self, from: decryptedData)
//                        return object
//                    } catch {
//                        print("encryption error: \(error)")
//                    }
//                }
//            }
//        } catch {
//            debugPrint("SQLiteProvider Error:  Failed to decode stored object into type: \(T.self)")
//            debugPrint("Error:")
//            debugPrint(error)
//            if let data = try? query(sql: "SELECT value FROM Data WHERE id = $1", params: [id]).first, let objectData = data, let body = String(data: objectData, encoding: .utf8) {
//                
//                debugPrint("Object data:")
//                debugPrint(body)
//                
//            }
//        }
//        return nil
//    }
//    
//    @discardableResult
//    public func query<T>(keyspace: Data, params: [param]?) -> [T] where T : Decodable, T : Encodable {
//        var results: [T] = []
//        var whereParams: [Any?] = []
//        // loop to see if there are any where conditions
//        var foundWhere = false
//        for p in params ?? [] {
//            switch p {
//            case .where(_, _, _):
//                foundWhere = true
//                break;
//            default:
//                break
//            }
//        }
//        var whereSql = ""
//        if foundWhere {
//            whereSql += " QueryableData AS QD0 "
//            var wheres: [String] = []
//            var idx = 0
//            for p in params ?? [] {
//                switch p {
//                case .where(let key, let op, let param):
//                    if idx > 0 {
//                        whereSql += " JOIN QueryableData AS QD\(idx) on QD\(idx-1).id = QD\(idx).id "
//                    }
//                    switch op {
//                    case .equals:
//                        if config.hashQueriableProperties {
//                            wheres.append("(QD\(idx).key = ?)")
//                            whereParams.append(hashParam(key.data(using: .utf8)!, param))
//                        } else {
//                            wheres.append("(QD\(idx).key = ? AND QD\(idx).value = ?)")
//                            whereParams.append(key)
//                            whereParams.append(param)
//                        }
//                    case .greater:
//                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value > ?)")
//                        whereParams.append(key)
//                        whereParams.append(param)
//                    case .isnotnull:
//                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value IS NOT NULL)")
//                        whereParams.append(key)
//                    case .isnull:
//                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value IS NULL)")
//                        whereParams.append(key)
//                    case .less:
//                        wheres.append("(QD\(idx).key = ? AND QD\(idx).value < ?)")
//                        whereParams.append(key)
//                        whereParams.append(param)
//                    }
//                    idx += 1
//                    break;
//                default:
//                    break
//                }
//            }
//            
//            whereSql += " WHERE "
//            whereSql += wheres.joined(separator: " AND ")
//        }
//        do {
//            // urgh, this is complex, but works well in fact
//            // SELECT QD1.recid FROM QueriableData as QD1 JOIN QueriableData AS QD2 on QD1.recid = QD2.recid JOIN QueriableData AS QD3 on QD2.recid = QD3.recid WHERE (QD1.key = "age" AND QD1.value = 40) AND (QD2."key" = "name" AND QD2.value = "adrian") AND (QD3.key = "surname" AND QD3.value = "herridge")
//            let data = try query(sql: "SELECT value FROM Data WHERE id IN (SELECT QD0.id FROM \(whereSql) );", params: whereParams)
//            for d in data {
//                if config.aes256encryptionKey == nil {
//                    if let objectData = d, let object = try? decoder.decode(T.self, from: objectData) {
//                        results.append(object)
//                    }
//                } else {
//                    // this data is to be stored encrypted
//                    if let encKey = config.aes256encryptionKey {
//                        let key = encKey.sha256()
//                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
//                        do {
//                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
//                            if let encryptedData = d {
//                                let objectData = try aes.decrypt(encryptedData.bytes)
//                                let object = try decoder.decode(T.self, from: Data(objectData))
//                                results.append(object)
//                            }
//                        } catch {
//                            print("encryption error: \(error)")
//                        }
//                    }
//                }
//            }
//            return results
//        } catch  {
//            return []
//        }
//    }
//    
//    @discardableResult
//    public func all<T>(keyspace: Data) -> [T] where T : Decodable, T : Encodable {
//        do {
//            let data = try query(sql: "SELECT value FROM Data WHERE id IN (SELECT id FROM Records WHERE keyspace = $1);", params: [keyspace])
//            var aggregation: [Data] = []
//            for d in data {
//                if config.aes256encryptionKey == nil {
//                    if let objectData = d {
//                        aggregation.append(objectData)
//                    }
//                } else {
//                    // this data is to be stored encrypted
//                    if let encKey = config.aes256encryptionKey {
//                        let key = encKey.sha256()
//                        let iv = (encKey + Data(kSaltValue.bytes)).md5()
//                        do {
//                            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
//                            if let encryptedData = d {
//                                let objectData = try aes.decrypt(encryptedData.bytes)
//                                aggregation.append(Data(objectData))
//                            }
//                        } catch {
//                            print("encryption error: \(error)")
//                        }
//                    }
//                }
//            }
//            let opener = "[".data(using: .utf8)!
//            let closer = "]".data(using: .utf8)!
//            let separater = ",".data(using: .utf8)!
//            var fullData = opener
//            fullData.append(contentsOf: aggregation.joined(separator: separater))
//            fullData.append(closer)
//            if let results = try? JSONDecoder().decode([T].self, from: fullData) {
//                return results
//            } else {
//                var results: [T] = []
//                for v in aggregation {
//                    if let object = try? JSONDecoder().decode(T.self, from: v) {
//                        results.append(object)
//                    }
//                }
//                return results
//            }
//        } catch  {
//            return []
//        }
//    }
//    
//}
