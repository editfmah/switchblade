//
//  Switchblade+Setters.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "default"
fileprivate var default_partition = "default"
fileprivate var default_ttl = -1

extension Switchblade: SwitchbadePutter {
    
    public func put<T>(keyspace: String, ttl: Int?, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        if provider.put(partition: default_partition, key: object.key.key(), keyspace: keyspace, ttl: ttl ?? -1, object) {
            notify(key: object.key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    public func put<T>(partition: String, ttl: Int?, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.put(partition: partition, key: object.key.key(), keyspace: keyspaceObject.keyspace, ttl: ttl ?? -1, object) {
                notify(key: object.key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.put(partition: partition, key: object.key.key(), keyspace: default_keyspace, ttl: ttl ?? -1, object) {
                notify(key: object.key, keyspace: default_keyspace)
                return true
            }
        }
        return false
    }
    
    
    public func put<T>(ttl: Int?, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.put(partition: default_partition, key: object.key.key(), keyspace: keyspaceObject.keyspace, ttl: ttl ?? -1, object) {
                notify(key: object.key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.put(partition: default_partition, key: object.key.key(), keyspace: default_keyspace, ttl: ttl ?? -1, object) {
                notify(key: object.key, keyspace: default_keyspace)
                return true
            }
        }
        return false
    }
    
    public func put<T>(key: PrimaryKeyType, ttl: Int?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.put(partition: default_partition, key: key.key(), keyspace: keyspaceObject.keyspace, ttl: ttl ?? -1, object) {
                notify(key: key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.put(partition: default_partition, key: key.key(), keyspace: default_keyspace, ttl: ttl ?? -1, object) {
                notify(key: key, keyspace: default_partition)
                return true
            }
        }
        return false
    }
    
    public func put<T>(key: PrimaryKeyType, keyspace: String, ttl: Int?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if provider.put(partition: default_partition, key: key.key(), keyspace: keyspace, ttl: ttl ?? -1, object) {
            notify(key: key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    public func put<T>(_ compositeKeys: [CompositeComponent], ttl: Int?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        let key = makeCompositeKey(compositeKeys)
        if provider.put(partition: default_partition, key: key.key(), keyspace: default_keyspace, ttl: ttl ?? -1, object) {
            notify(key: key, keyspace: default_partition)
            return true
        }
        return false
    }
    
    
    @discardableResult public func put<T>(_ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        return put(ttl: nil, object)
    }
    
    
    @discardableResult public func put<T>(keyspace: String, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        put(keyspace: keyspace, ttl: nil, object)
    }
    
    @discardableResult public func put<T>(partition: String, keyspace: String, ttl: Int? = nil, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        if provider.put(partition: partition, key: object.key.key(), keyspace: keyspace, ttl: ttl ?? -1, object) {
            notify(key: object.key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func put<T>(key: PrimaryKeyType, _ object: T) -> Bool where T : Decodable, T : Encodable {
        put(key: key, ttl: nil, object)
    }
    
    @discardableResult public func put<T>(partition: String, key: PrimaryKeyType, ttl: Int? = nil, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.put(partition: partition, key: key.key(), keyspace: keyspaceObject.keyspace, ttl: ttl ?? -1, object) {
                notify(key: key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.put(partition: partition, key: key.key(), keyspace: default_keyspace, ttl: ttl ?? -1, object) {
                notify(key: key, keyspace: default_partition)
                return true
            }
        }
        return false
    }
    
    @discardableResult public func put<T>(key: PrimaryKeyType, keyspace: String, _ object: T) -> Bool where T : Decodable, T : Encodable {
        return put(key: key, keyspace: keyspace, ttl: nil, object)
    }
    
    @discardableResult public func put<T>(partition: String, key: PrimaryKeyType, keyspace: String, ttl: Int? = nil, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if provider.put(partition: partition, key: key.key(), keyspace: keyspace, ttl: ttl ?? -1, object) {
            notify(key: key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func put<T>(_ compositeKeys: [CompositeComponent], _ object: T) -> Bool where T : Decodable, T : Encodable {
        return put(compositeKeys, ttl: nil, object)
    }
    
    @discardableResult public func put<T>(partition: String, _ compositeKeys: [CompositeComponent], ttl: Int? = nil, _ object: T) -> Bool where T : Decodable, T : Encodable {
        let key = makeCompositeKey(compositeKeys)
        if provider.put(partition: default_partition, key: key.key(), keyspace: default_keyspace, ttl: ttl ?? -1, object) {
            notify(key: key, keyspace: default_partition)
            return true
        }
        return false
    }

}
