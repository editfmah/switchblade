//
//  Binding.swift
//  Switchblade
//
//  Created by Adrian Herridge on 01/12/2020.
//

import Foundation

fileprivate var default_keyspace = "default"
fileprivate var default_partition = "default"

public class SWBinding<T:Codable> : SwitchbladeBinding {
    
    public func signal() {
        // application asking for the closure to be executed
        self.closure?(result)
    }
    
    func notify() {
        // notification from ORM for potential update to graph
        update(false)
    }
    
    public var count: Int {
        return result == nil ? 0 : 1
    }
    
    public func data(index: Int) -> T? {
        return result
    }
    
    public var object: T? {
        return result
    }
    
    internal var id: UUID = UUID()
    private var blade: Switchblade
    internal var key: PrimaryKeyType?
    internal var keyspace: String?
    private var result: T?
    private var closure: ((T?)->Void)?
    
    public init(_ switchblade: Switchblade, key: PrimaryKeyType, keyspace: String? = nil,_ onChange: ((T?)->Void)? = nil) {
        self.blade = switchblade
        self.key = key
        self.keyspace = keyspace ?? default_keyspace
        self.closure = onChange
        blade.registerBinding(self)
        update(true)
    }
    
    public init(_ switchblade: Switchblade, object: T,_ onChange: ((T?)->Void)? = nil) {
        self.blade = switchblade
        if let identifiable = object as? Identifiable {
            self.key = identifiable.key
        }
        if let identifiable = object as? KeyspaceIdentifiable {
            self.keyspace = identifiable.keyspace
        } else {
            self.keyspace = default_keyspace
        }
        self.closure = onChange
        blade.registerBinding(self)
        update(true)
    }
    
    public func setAction(_ onAction: ((T?)->Void)? = nil) {
        closure = onAction
    }
    
    public func setKey(key: PrimaryKeyType, keyspace: String? = nil) {
        self.key = key
        if let keyspace = keyspace {
            self.keyspace = keyspace
        }
        update(false)
    }
    
    fileprivate func update(_ initial: Bool) {
        // work out which kind of update we are after Key, Keyspace, Key & Keyspace
        if let key = key, let keyspace = keyspace {
            // record
            result = blade.get(key: key, keyspace: keyspace)
            if !initial {
                self.closure?(result)
            }
        } else {
            // all
            self.result = nil
            if !initial {
                self.closure?(result)
            }
        }
    }
    
    deinit {
        blade.deregisterBinding(self)
    }
}

public class SWBindingCollection<T:Codable> : SwitchbladeBinding {
    
    public func signal() {
        // application asking for the closure to be executed
        self.closure?(result)
    }
    
    public var count: Int {
        return result.count
    }
    
    public func data(index: Int) -> T? {
        if index < result.count {
            return result[index]
        }
        return nil
    }
    
    public var object: [T] {
        return result
    }
    
    public func notify() {
        // notification from ORM for potential update to graph
        update(false)
    }
    
    internal var id: UUID = UUID()
    private var blade: Switchblade
    internal var key: PrimaryKeyType?
    internal var keyspace: String?
    private var result: [T] = []
    private var closure: (([T])->Void)?
    private var `where`: ((T) -> Bool)?
    
    init(_ switchblade: Switchblade, keyspace: String? = nil,_ onChange: (([T])->Void)? = nil) {
        self.blade = switchblade
        self.keyspace = keyspace ?? default_keyspace
        self.closure = onChange
        blade.registerBinding(self)
        update(true)
    }
    
    public init(_ switchblade: Switchblade, keyspace: String, where: ((T) -> Bool)? = nil,_ onChange: (([T])->Void)? = nil) {
        self.blade = switchblade
        self.keyspace = keyspace
        self.where = `where`
        self.closure = onChange
        blade.registerBinding(self)
        update(true)
    }
    
    public init(_ switchblade: Switchblade, where: @escaping ((T) -> Bool), _ onChange: (([T])->Void)? = nil) {
        self.blade = switchblade
        self.where = `where`
        self.keyspace = keyspace ?? default_keyspace
        self.closure = onChange
        blade.registerBinding(self)
        update(true)
    }
    
    public func setAction(_ onAction: (([T])->Void)? = nil) {
        closure = onAction
    }
    
    public func setKeyspace(keyspace: String? = nil, where: ((T) -> Bool)? = nil) {
        self.keyspace = keyspace ?? default_keyspace
        if let `where` = `where` {
            self.where = `where`
        }
        update(false)
    }
    
    fileprivate func update(_ initial: Bool) {
        // work out which kind of update we are after Key, Keyspace, Key & Keyspace
        if let `where` = self.where {
            // parameter query for keyspace
            result = blade.query(keyspace: keyspace ?? default_keyspace, `where`)
            if !initial {
                self.closure?(result)
            }
        } else if let keyspace = keyspace {
            // records in keyspace
            result = blade.all(keyspace: keyspace)
            if !initial {
                self.closure?(result)
            }
        }  else {
            // all
            self.result = blade.all()
            if !initial {
                self.closure?(result)
            }
        }
    }
    
    deinit {
        blade.deregisterBinding(self)
    }
}
