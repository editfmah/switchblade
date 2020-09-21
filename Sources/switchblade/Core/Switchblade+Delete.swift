//
//  Switchblade+Delete.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "_default_".data(using: .utf8)!

extension Switchblade: SwitchbadeDeleter {
    
    public func remove<T>(_ object: T) -> Bool where T : SwitchbladeIdentifiable {
        if let keyspaceObject = object as? SwitchbladeKeyspace {
            return provider.delete(key: object.key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!)
        } else {
            return provider.delete(key: object.key.key(), keyspace: default_keyspace)
        }
    }
    
    public func remove<T>(keyspace: String, _ object: T) -> Bool where T : SwitchbladeIdentifiable {
        return provider.delete(key: object.key.key(), keyspace: keyspace.data(using: .utf8)!)
    }
    
    public func remove(key: KeyType) -> Bool {
        return provider.delete(key: key.key(), keyspace: default_keyspace)
    }
    
    public func remove(key: KeyType, keyspace: String) -> Bool {
        return provider.delete(key: key.key(), keyspace: keyspace.data(using: .utf8)!)
    }
    
}
