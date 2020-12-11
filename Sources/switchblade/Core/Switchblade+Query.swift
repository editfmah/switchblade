//
//  Switchblade+Query.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "_default_".data(using: .utf8)!

extension Switchblade : SwitchbadeRetriever {

    public func all<T>(type: T, _ closure: (([T]) -> Void)) where T : Decodable, T : Encodable {
        let result: [T] = provider.all(keyspace: default_keyspace)
        closure(result)
    }
    
    
    public func get<T>(key: KeyType) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(key: key.key(), keyspace: default_keyspace)
        return result
    }
    
    public func get<T>(key: KeyType, keyspace: String) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(key: key.key(), keyspace: keyspace.data(using: .utf8)!)
        return result
    }
    
    public func all<T>() -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(keyspace: default_keyspace)
        return result
    }
    
    public func all<T>(keyspace: String) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(keyspace: keyspace.data(using: .utf8)!)
        return result
    }
    
    public func query<T>(parameters: [param]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(keyspace: default_keyspace, params: parameters)
        return result
    }
    
    public func query<T>(keyspace: String, parameters: [param]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(keyspace: keyspace.data(using: .utf8)!, params: parameters)
        return result
    }
    
    public func get<T>(key: KeyType, _ closure: (T?) -> T?) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(key: key.key(), keyspace: default_keyspace)
        return closure(result)
    }
    
    public func get<T>(key: KeyType, keyspace: String, _ closure: (T?) -> T?) -> T? where T : Decodable, T : Encodable {
        let result: T? = provider.get(key: key.key(), keyspace: keyspace.data(using: .utf8)!)
        return closure(result)
    }
    
    public func all<T>(_ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(keyspace: default_keyspace)
        return closure(result)
    }
    
    public func all<T>(keyspace: String, _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.all(keyspace: keyspace.data(using: .utf8)!)
        return closure(result)
    }
    
    public func query<T>(parameters: [param], _ closure: ([T]) -> [T]) -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(keyspace: default_keyspace, params: parameters)
        return closure(result)
    }
    
    public func query<T>(keyspace: String, parameters: [param], _ closure: ([T]) -> [T])  -> [T] where T : Decodable, T : Encodable {
        let result: [T] = provider.query(keyspace: keyspace.data(using: .utf8)!, params: parameters)
        return closure(result)
    }
    
}
