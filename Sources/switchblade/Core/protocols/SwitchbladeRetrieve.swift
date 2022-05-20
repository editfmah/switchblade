//
//  SwitchbladeGetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public typealias QueryResultsClosure<T:Codable> = ((_ results: [T]) -> [T])
public typealias QueryResultClosure<T:Codable> = ((_ result: T?) -> T?)

public protocol SwitchbadeRetriever {
    
    // typed by expected return/assignment value
    @discardableResult func get<T:Codable>(key: PrimaryKeyType) -> T?
    @discardableResult func get<T:Codable>(key: PrimaryKeyType, keyspace: String) -> T?
    @discardableResult func all<T:Codable>() -> [T]
    @discardableResult func all<T:Codable>(keyspace: String) -> [T]
    @discardableResult func all<T:Codable>(partition: String) -> [T]
    @discardableResult func all<T:Codable>(partition: String, keyspace: String) -> [T]
    @discardableResult func query<T:Codable>(_ where: ((T) -> Bool)) -> [T]
    @discardableResult func query<T:Codable>(keyspace: String, _ where: ((T) -> Bool)) -> [T]
    @discardableResult func get<T:Codable>(_ compositeKeys: [CompositeComponent]) -> T?
    @discardableResult func get<T:Codable>(partition: String, key: PrimaryKeyType) -> T?
    @discardableResult func get<T:Codable>(partition: String, key: PrimaryKeyType, keyspace: String) -> T?
    @discardableResult func query<T:Codable>(partition: String, _  where: ((T) -> Bool)) -> [T]
    @discardableResult func query<T:Codable>(partition: String, keyspace: String, _ where: ((T) -> Bool)) -> [T]
    @discardableResult func get<T:Codable>(partition: String, _ compositeKeys: [CompositeComponent]) -> T?
    
    func iterate<T: Codable>(_ closure: @escaping ((_ object: T) -> Void))
    func iterate<T: Codable>(keyspace: String, _ closure: @escaping ((_ object: T) -> Void))
    func iterate<T: Codable>(partition: String, _ closure: @escaping ((_ object: T) -> Void))
    func iterate<T: Codable>(partition: String, keyspace: String, _ closure: @escaping ((_ object: T) -> Void)) 
    
}
