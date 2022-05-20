//
//  Switchblade+Query.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "default"
fileprivate var default_partition = "default"

extension Switchblade : SwitchbadeRetriever {
    
    public func get<T>(key: PrimaryKeyType) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: default_partition, key: key.key(), keyspace: default_keyspace)
        return result
    }
    
    public func get<T>(partition: String, key: PrimaryKeyType) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: partition, key: key.key(), keyspace: default_keyspace)
        return result
    }
    
    public func get<T>(key: PrimaryKeyType, keyspace: String) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: default_partition, key: key.key(), keyspace: keyspace)
        return result
    }
    
    public func get<T>(partition: String, key: PrimaryKeyType, keyspace: String) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: partition, key: key.key(), keyspace: keyspace)
        return result
    }
    
    public func all<T>() -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: default_partition, keyspace: default_keyspace)
        return result
    }
    
    public func all<T>(partition: String) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: default_partition, keyspace: default_keyspace)
        return result
    }
    
    public func all<T>(keyspace: String) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: default_partition, keyspace: keyspace)
        return result
    }
    
    public func all<T>(partition: String, keyspace: String) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: partition, keyspace: keyspace)
        return result
    }
    
    public func query<T>(_ where: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: default_partition, keyspace: default_keyspace, map: `where`)
        return result
    }
    
    public func query<T>(partition: String,_ where: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: partition, keyspace: default_keyspace, map: `where`)
        return result
    }
    
    public func query<T>(keyspace: String,_ where: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: default_partition, keyspace: keyspace, map: `where`)
        return result
    }
    
    public func query<T>(partition: String, keyspace: String,_ where: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: partition, keyspace: keyspace, map: `where`)
        return result
    }
    
    public func get<T>(_ compositeKeys: [CompositeComponent]) -> T? where T : Decodable, T : Encodable {
        let key = makeCompositeKey(compositeKeys)
        let result: T? = provider.get(partition: default_partition, key: key.key(), keyspace: default_keyspace)
        return result
    }
    
    public func get<T>(partition: String, _ compositeKeys: [CompositeComponent]) -> T? where T : Decodable, T : Encodable {
        let key = makeCompositeKey(compositeKeys)
        let result: T? = provider.get(partition: partition, key: key.key(), keyspace: default_keyspace)
        return result
    }
    
    public func iterate<T: Codable>(_ closure: @escaping ((T) -> Void))  {
        provider.iterate(partition: default_partition, keyspace: default_keyspace, iterator: closure)
    }
    
    public func iterate<T: Codable>(keyspace: String, _ closure: @escaping ((T) -> Void)) {
        provider.iterate(partition: default_partition, keyspace: keyspace, iterator: closure)
    }
    
    public func iterate<T: Codable>(partition: String, _ closure: @escaping ((T) -> Void))  {
        provider.iterate(partition: partition, keyspace: default_keyspace, iterator: closure)
    }
    
    public func iterate<T: Codable>(partition: String, keyspace: String, _ closure: @escaping ((T) -> Void)) {
        provider.iterate(partition: partition, keyspace: keyspace, iterator: closure)
    }
    
}
