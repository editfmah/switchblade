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
    public func put<T>(partition: String? = nil, keyspace: String? = nil, key: PrimaryKeyType? = nil, compositeKeys: [CompositeComponent]? = nil, ttl: Int? = nil, filter: [String : String]? = nil, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        let p = partition ?? default_partition
        var ks = keyspace ?? default_keyspace
        var k: PrimaryKeyType? = key ?? nil
        let comp = compositeKeys ?? []
        let t = ttl ?? default_ttl
        var filters: [String] = []
        
        if let filter = filter, filter.isEmpty == false {
            for kvp in filter {
                filters.append("\(kvp.key)=\(kvp.value)".md5())
            }
        } else {
            // check for filterable conformance
            if let filterable = object as? Filterable {
                for kvp in filterable.filters {
                    filters.append("\(kvp.key)=\(kvp.value)".md5())
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
        
        if provider.put(partition: p.md5Data, key: k!.key(), keyspace: ks.md5Data, ttl: t, filter: filters.joined(separator: ","), object) {
            notify(key: k!, keyspace: ks)
            return true
        }
        
        return false
        
    }

}
