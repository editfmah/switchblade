//
//  SQLiteShardProvider.swift
//  Switchblade
//
//  Created by Adrian on 20/10/2024.
//

import Foundation

import Dispatch
import CryptoSwift

public class SQLiteShardProvider: DataProvider {

    public var config: SwitchbladeConfig!
    public weak var blade: Switchblade!
    
    fileprivate var lock = Mutex()
    fileprivate var dbs: [String : SQLiteProvider] = [:]

    fileprivate func provider(_ partition: String) -> SQLiteProvider {
        var provider: SQLiteProvider!
        lock.mutex {
            if let p = dbs[partition.md5()] {
                provider = p
            } else {
                provider = SQLiteProvider(path: "\(path!)/\(partition).sqlite")
                provider.config = config
                provider.blade = blade
                try? provider.open()
                dbs[partition.md5()] = provider
            }
        }
        return provider
    }
    
    fileprivate func providers() -> [SQLiteProvider] {
        var providers: [SQLiteProvider] = []
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
                let provider = SQLiteProvider(path: "\(path!)/\(file)")
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
        return provider(partition).put(partition: partition, key: key, keyspace: keyspace, ttl: ttl, filter: filter, object)
    }
    
    public func delete(partition: String, key: String, keyspace: String) -> Bool {
        return provider(partition).delete(partition: partition, key: key, keyspace: keyspace)
    }
    
    public func get<T>(partition: String, key: String, keyspace: String) -> T? where T : Decodable, T : Encodable {
        return provider(partition).get(partition: partition, key: key, keyspace: keyspace)
    }
    
    public func query<T>(partition: String, keyspace: String, filter: [String : String]?, map: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        return provider(partition).query(partition: partition, keyspace: keyspace, filter: filter, map: map)
    }
    
    public func all<T>(partition: String, keyspace: String, filter: [String : String]?) -> [T] where T : Decodable, T : Encodable {
        return provider(partition).all(partition: partition, keyspace: keyspace, filter: filter)
    }
    
    public func iterate<T>(partition: String, keyspace: String, filter: [String : String]?, iterator: ((T) -> Void)) where T : Decodable, T : Encodable {
        return provider(partition).iterate(partition: partition, keyspace: keyspace, filter: filter, iterator: iterator)
    }
    
    public func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: @escaping ((FromType) -> ToType?)) where FromType : SchemaVersioned, ToType : SchemaVersioned {
        // this is a migration of all. And in paralell as well
        for provider in providers() {
            provider.migrate(from: from, to: to, migration: migration)
        }
    }
    
    public func ids(partition: String, keyspace: String, filter: [String : String]?) -> [String] {
        return provider(partition).ids(partition: partition, keyspace: keyspace, filter: filter)
    }
    
}

