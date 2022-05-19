//
//  Switchblade+Delete.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "default"
fileprivate var default_partition = "default"

extension Switchblade: SwitchbadeRemove {
    
    @discardableResult public func remove<T>(_ object: T) -> Bool where T : Identifiable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.delete(partition: default_partition, key: object.key.key(), keyspace: keyspaceObject.keyspace) {
                notify(key: object.key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.delete(partition: default_partition, key: object.key.key(), keyspace: default_keyspace) {
                notify(key: object.key, keyspace: default_keyspace)
                return true
            }
        }
        return false
    }
    
    @discardableResult public func remove<T>(partition: String, _ object: T) -> Bool where T : Identifiable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.delete(partition: partition, key: object.key.key(), keyspace: keyspaceObject.keyspace) {
                notify(key: object.key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.delete(partition: partition, key: object.key.key(), keyspace: default_keyspace) {
                notify(key: object.key, keyspace: default_keyspace)
                return true
            }
        }
        return false
    }
    
    @discardableResult public func remove<T>(keyspace: String, _ object: T) -> Bool where T : Identifiable {
        if provider.delete(partition: default_partition, key: object.key.key(), keyspace: keyspace) {
            notify(key: object.key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove<T>(partition: String, keyspace: String, _ object: T) -> Bool where T : Identifiable {
        if provider.delete(partition: partition, key: object.key.key(), keyspace: keyspace) {
            notify(key: object.key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(key: PrimaryKeyType) -> Bool {
        if provider.delete(partition: default_partition, key: key.key(), keyspace: default_keyspace) {
            notify(key: key, keyspace: default_keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(partition: String, key: PrimaryKeyType) -> Bool {
        if provider.delete(partition: partition, key: key.key(), keyspace: default_keyspace) {
            notify(key: key, keyspace: default_keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(key: PrimaryKeyType, keyspace: String) -> Bool {
        if provider.delete(partition: default_partition, key: key.key(), keyspace: keyspace) {
            notify(key: key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(partition: String, key: PrimaryKeyType, keyspace: String) -> Bool {
        if provider.delete(partition: partition, key: key.key(), keyspace: keyspace) {
            notify(key: key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(_ compositeKeys: [CompositeComponent]) -> Bool {
        let key = makeCompositeKey(compositeKeys)
        if provider.delete(partition: default_partition, key: key.key(), keyspace: default_keyspace) {
            notify(key: key, keyspace: default_keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func remove(partition: String, _ compositeKeys: [CompositeComponent]) -> Bool {
        let key = makeCompositeKey(compositeKeys)
        if provider.delete(partition: partition, key: key.key(), keyspace: default_keyspace) {
            notify(key: key, keyspace: default_keyspace)
            return true
        }
        return false
    }
    
}
