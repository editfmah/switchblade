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
    
    @discardableResult
    public func put<T>(partition: String? = nil, keyspace: String? = nil, key: PrimaryKeyType? = nil, compositeKeys: [CompositeComponent]? = nil, ttl: Int? = nil, filter: [Filters]? = nil, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        let p = partition ?? default_partition
        var ks = keyspace ?? default_keyspace
        var k: PrimaryKeyType? = key ?? nil
        let comp = compositeKeys ?? []
        let t = ttl ?? default_ttl
        var filters: [String:String] = [:]
        
        // check for filterable conformance
        if let filterable = object as? Filterable {
            filters = filterable.filters.dictionary
        }
        
        if let filter = filter, filter.isEmpty == false {
            for f in filter {
                let this = [f].dictionary
                for (k,v) in this {
                    filters[k] = v
                }
            }
        }
        
        // check for composite keys
        if comp.isEmpty == false {
            k = makeCompositeKey(comp)
        } else {
            // composite keys must use default partitions & keyspaces
            if let identify = object as? Identifiable {
                k = identify.key
            }
            
            if let keyspaceable = object as? KeyspaceIdentifiable {
                ks = keyspaceable.keyspace
            }
        }
        
        if k == nil {
            assertionFailure("key cannot be nil for a write operation")
            return false
        }
        
        if provider.put(partition: p, key: k!.key(), keyspace: ks, ttl: t, filter: filters, object) {
            notify(key: k!, keyspace: ks)
            return true
        }
        
        return false
        
    }

}
