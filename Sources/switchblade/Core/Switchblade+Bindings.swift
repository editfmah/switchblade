//
//  Switchblade+Bindings.swift
//  Switchblade
//
//  Created by Adrian Herridge on 01/12/2020.
//

import Foundation

extension Switchblade : SwitchbadeBinder {

    public func bind<T>(where: @escaping ((T) -> Bool), _ onChange: (([T]) -> Void)?) -> SWBindingCollection<T> where T : Decodable, T : Encodable {
        return SWBindingCollection<T>(self, where: `where`, onChange)
    }
    
    public func bind<T>(keyspace: String, where: @escaping ((T) -> Bool), _ onChange: (([T]) -> Void)?) -> SWBindingCollection<T> where T : Decodable, T : Encodable {
        return SWBindingCollection<T>(self, keyspace: keyspace, where: `where`, onChange)
    }
    
    // object getters/updaters
    public func bind<T>(key: PrimaryKeyType,_ onChange: ((T?)->Void)? = nil) -> SWBinding<T> where T : Decodable, T : Encodable {
        return SWBinding<T>(self, key: key, onChange)
    }
    
    public func bind<T>(_ object: T, _ onChange: ((T?) -> Void)? = nil) -> SWBinding<T> where T : Decodable, T : Encodable {
        return SWBinding<T>(self, object: object, onChange)
    }
    
    public func bind<T>(key: PrimaryKeyType, keyspace: String,_ onChange: ((T?)->Void)? = nil) -> SWBinding<T> where T : Decodable, T : Encodable {
        return SWBinding<T>(self, key: key, keyspace: keyspace, onChange)
    }
    
    // group bindings
    public func bind<T>(_ onChange: (([T]) -> Void)? = nil) -> SWBindingCollection<T> where T : Decodable, T : Encodable {
        return SWBindingCollection<T>(self, onChange)
    }
    
    public func bind<T>(keyspace: String, _ onChange: (([T]) -> Void)? = nil) -> SWBindingCollection<T> where T : Decodable, T : Encodable {
        return SWBindingCollection<T>(self, keyspace: keyspace, onChange)
    }
    
    // notifiers
    internal func notify(key: PrimaryKeyType, keyspace: String) {
        // cleanup
        bindings.removeAll(where: { $0.value == nil })
        
        // filter
        bindings.forEach({
            if let weakBinding = ($0.value as? SwitchbladeBinding), weakBinding.key?.key() == key.key() && weakBinding.keyspace == keyspace {
                // we have a hit
                weakBinding.notify()
            }
        })
        
        // now notify the keyspace
        notify(keyspace: keyspace)
        
    }
    
    internal func notify(keyspace: String) {
        // cleanup
        bindings.removeAll(where: { $0.value == nil })
        
        // filter
        bindings.forEach({
            if let weakBinding = ($0.value as? SwitchbladeBinding),weakBinding.key == nil && weakBinding.keyspace == keyspace {
                // we have a hit
                weakBinding.notify()
            }
        })
    }
    
    internal func registerBinding(_ binding: AnyObject) {
        if let _ = binding as? SwitchbladeBinding {
            bindings.append(WeakContainer(binding))
        }
    }
    
    internal func deregisterBinding(_ binding: SwitchbladeBinding) {
        bindings.removeAll(where: { $0.id == binding.id })
    }
    
}
