//
//  Switchblade+Setters.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "_default_".data(using: .utf8)!

extension Switchblade: SwitchbadePutter {
    
    @discardableResult public func put<T>(_ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            return provider.put(key: object.key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!, object)
        } else {
            return provider.put(key: object.key.key(), keyspace: default_keyspace, object)
        }
    }
    
    @discardableResult public func put<T>(keyspace: String, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        return provider.put(key: object.key.key(), keyspace: keyspace.data(using: .utf8)!, object)
    }
    
    @discardableResult public func put<T>(key: KeyType, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            return provider.put(key: key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!, object)
        } else {
            return provider.put(key: key.key(), keyspace: default_keyspace, object)
        }
    }
    
    @discardableResult public func put<T>(key: KeyType, keyspace: String, _ object: T) -> Bool where T : Decodable, T : Encodable {
        return provider.put(key: key.key(), keyspace: keyspace.data(using: .utf8)!, object)
    }

}
