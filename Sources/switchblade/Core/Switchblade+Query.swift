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
    
    public func get<T>(partition: String? = nil, key: PrimaryKeyType? = nil, keyspace: String? = nil, compositeKeys: [CompositeComponent]? = nil) -> T? where T : Decodable, T : Encodable {
        
        let p = partition ?? default_partition
        let ks = keyspace ?? default_keyspace
        var k = key?.key()
        
        if let composite = compositeKeys {
            k = makeCompositeKey(composite)
        }
        
        if k == nil {
            assertionFailure("key cannot be nil")
            return nil
        }
        
        return provider.get(partition: p, key: k!, keyspace: ks)
        
    }
    
    public func all<T>(partition: String? = nil, keyspace: String? = nil, filter: [Filters]? = nil) -> [T] where T : Decodable, T : Encodable {
        
        let p = partition ?? default_partition
        let ks = keyspace ?? default_keyspace
        
        return provider.all(partition: p, keyspace: ks, filter: filter?.dictionary)
        
    }
    
    public func query<T>(partition: String? = nil, keyspace: String? = nil, filter: [Filters]? = nil, _ where: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        
        let p = partition ?? default_partition
        let ks = keyspace ?? default_keyspace
        
        return provider.query(partition: p, keyspace: ks, filter: filter?.dictionary, map: `where`)
        
    }
    
    public func iterate<T>(partition: String? = nil, keyspace: String? = nil, filter: [Filters]? = nil, _ closure: @escaping ((T) -> Void)) where T : Decodable, T : Encodable {
        
        let p = partition ?? default_partition
        let ks = keyspace ?? default_keyspace
        
        return provider.iterate(partition: p, keyspace: ks, filter: filter?.dictionary, iterator: closure)
        
    }
    
    public func ids(partition: String? = nil, keyspace: String? = nil, filter: [Filters]? = nil) -> [String] {
        
        let p = partition ?? default_partition
        let ks = keyspace ?? default_keyspace
        
        return provider.ids(partition: p, keyspace: ks, filter: filter?.dictionary)
        
    }
    
}
