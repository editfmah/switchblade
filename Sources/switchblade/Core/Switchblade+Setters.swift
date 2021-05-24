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
            if provider.put(key: object.key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!, object) {
                notify(key: object.key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.put(key: object.key.key(), keyspace: default_keyspace, object) {
                notify(key: object.key, keyspace: "_default_")
                return true
            }
        }
        return false
    }
    
    @discardableResult public func put<T>(keyspace: String, _ object: T) -> Bool where T : Decodable, T : Encodable, T : Identifiable {
        if provider.put(key: object.key.key(), keyspace: keyspace.data(using: .utf8)!, object) {
            notify(key: object.key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func put<T>(key: KeyType, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if let keyspaceObject = object as? KeyspaceIdentifiable {
            if provider.put(key: key.key(), keyspace: keyspaceObject.keyspace.data(using: .utf8)!, object) {
                notify(key: key, keyspace: keyspaceObject.keyspace)
                return true
            }
        } else {
            if provider.put(key: key.key(), keyspace: default_keyspace, object) {
                notify(key: key, keyspace: "_default_")
                return true
            }
        }
        return false
    }
    
    @discardableResult public func put<T>(key: KeyType, keyspace: String, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if provider.put(key: key.key(), keyspace: keyspace.data(using: .utf8)!, object) {
            notify(key: key, keyspace: keyspace)
            return true
        }
        return false
    }
    
    @discardableResult public func put<T>(_ compositeKeys: [CompositeComponent], _ object: T) -> Bool where T : Decodable, T : Encodable {
        let key = makeCompositeKey(compositeKeys)
        if provider.put(key: key.key(), keyspace: default_keyspace, object) {
            notify(key: key, keyspace: "_default_")
            return true
        }
        return false
    }

}
