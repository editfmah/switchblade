//
//  Switchblade+Delete.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "_default_".data(using: .utf8)!

extension Switchblade: SwitchbadeRemove {
    
    @discardableResult public func remove<T>(_ object: T) -> Bool where T : Identifiable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            return provider.delete(key: object.key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!)
        } else {
            return provider.delete(key: object.key.key(), keyspace: default_keyspace)
        }
    }
    
    @discardableResult public func remove<T>(keyspace: String, _ object: T) -> Bool where T : Identifiable {
        return provider.delete(key: object.key.key(), keyspace: keyspace.data(using: .utf8)!)
    }
    
    @discardableResult public func remove(key: KeyType) -> Bool {
        return provider.delete(key: key.key(), keyspace: default_keyspace)
    }
    
    @discardableResult public func remove(key: KeyType, keyspace: String) -> Bool {
        return provider.delete(key: key.key(), keyspace: keyspace.data(using: .utf8)!)
    }
    
}
