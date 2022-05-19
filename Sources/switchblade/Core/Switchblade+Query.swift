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

    public func all<T>(type: T, _ closure: (([T]) -> Void)) where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: default_partition, keyspace: default_keyspace)
        closure(result)
    }
    
    public func all<T>(partition: String, type: T, _ closure: (([T]) -> Void)) where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: partition, keyspace: default_keyspace)
        closure(result)
    }
    
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
    
    public func query<T>(parameters: [param]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: default_partition, keyspace: default_keyspace, params: parameters)
        return result
    }
    
    public func query<T>(partition: String, parameters: [param]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: partition, keyspace: default_keyspace, params: parameters)
        return result
    }
    
    public func query<T>(keyspace: String, parameters: [param]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: default_partition, keyspace: keyspace, params: parameters)
        return result
    }
    
    public func query<T>(partition: String, keyspace: String, parameters: [param]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: partition, keyspace: keyspace, params: parameters)
        return result
    }
    
    public func get<T>(key: PrimaryKeyType, _ closure: (T?) -> T?) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: default_partition, key: key.key(), keyspace: default_keyspace)
        return closure(result)
    }
    
    public func get<T>(partition: String, key: PrimaryKeyType, _ closure: (T?) -> T?) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: partition, key: key.key(), keyspace: default_keyspace)
        return closure(result)
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
    
    public func get<T>(key: PrimaryKeyType, keyspace: String, _ closure: (T?) -> T?) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: default_partition, key: key.key(), keyspace: keyspace)
        return closure(result)
    }
    
    public func get<T>(partition: String, key: PrimaryKeyType, keyspace: String, _ closure: (T?) -> T?) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(partition: partition, key: key.key(), keyspace: keyspace)
        return closure(result)
    }
    
    public func all<T>(_ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: default_partition, keyspace: default_keyspace)
        return closure(result)
    }
    
    public func all<T>(partition: String, _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: partition, keyspace: default_keyspace)
        return closure(result)
    }
    
    public func all<T>(keyspace: String, _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: default_partition, keyspace: keyspace)
        return closure(result)
    }
    
    public func all<T>(partition: String, keyspace: String, _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(partition: partition, keyspace: keyspace)
        return closure(result)
    }
    
    public func query<T>(parameters: [param], _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: default_partition, keyspace: default_keyspace, params: parameters)
        return closure(result)
    }
    
    public func query<T>(partition: String, parameters: [param], _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: partition, keyspace: default_keyspace, params: parameters)
        return closure(result)
    }
    
    public func query<T>(keyspace: String, parameters: [param], _ closure: ([T]) -> [T])  -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: default_partition, keyspace: keyspace, params: parameters)
        return closure(result)
    }
    
    public func query<T>(partition: String, keyspace: String, parameters: [param], _ closure: ([T]) -> [T])  -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(partition: partition, keyspace: keyspace, params: parameters)
        return closure(result)
    }
    
}
