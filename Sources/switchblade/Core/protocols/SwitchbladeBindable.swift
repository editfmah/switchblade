//
//  SwitchbladeBindable.swift
//  Switchblade
//
//  Created by Adrian Herridge on 01/12/2020.
//

import Foundation

public protocol SwitchbadeBinder {
    
    @discardableResult func bind<T: Codable>(key: KeyType,_ onChange: ((T?)->Void)?) -> Binding<T>
    @discardableResult func bind<T: Codable>(_ object: T,_ onChange: ((T?)->Void)?) -> Binding<T>
    @discardableResult func bind<T: Codable>(key: KeyType, keyspace: String,_ onChange: ((T?)->Void)?) -> Binding<T>
    @discardableResult func bind<T: Codable>(_ onChange: (([T])->Void)?) -> BindingCollection<T>
    @discardableResult func bind<T: Codable>(keyspace: String,_ onChange: (([T])->Void)?) -> BindingCollection<T>
    @discardableResult func bind<T: Codable>(parameters:[param],_ onChange: (([T])->Void)?) -> BindingCollection<T>
    @discardableResult func bind<T: Codable>(keyspace: String, parameters:[param],_ onChange: (([T])->Void)?) -> BindingCollection<T>
    
}

internal protocol SwitchbladeBinding {
    var id: UUID { get }
    var key: KeyType? { get }
    var keyspace: String? { get }
    var count: Int { get }
    func notify()
}
