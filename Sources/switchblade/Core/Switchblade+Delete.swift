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
            if provider.delete(key: object.key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!) {
                notify(key: object.key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.delete(key: object.key.key(), keyspace: default_keyspace) {
                notify(key: object.key, keyspace: "_default_")
                return true
            }
        }
        return false
    }
    
    @discardableResult public func remove<T>(keyspace: String, _ object: T) -> Bool where T : Identifiable {
        if provider.delete(key: object.key.key(), keyspace: keyspace.data(using: .utf8)!) {
            notify(key: object.key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(key: KeyType) -> Bool {
        if provider.delete(key: key.key(), keyspace: default_keyspace) {
            notify(key: key, keyspace: "_default_")
            return true
        }
        return false
    }
    
    @discardableResult public func remove(key: KeyType, keyspace: String) -> Bool {
        if provider.delete(key: key.key(), keyspace: keyspace.data(using: .utf8)!) {
            notify(key: key, keyspace: keyspace)
            return true
        }
        return false
    }
    
}
