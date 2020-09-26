//
//  SwitchbladeGetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public typealias QueryResultsClosure<T:Codable> = ((_ results: [T]?) -> [T]?)
public typealias QueryResultClosure<T:Codable> = ((_ result: T?) -> T?)

public protocol SwitchbadeRetriever {
    
    // typed by expected return/assignment value
    @discardableResult func get<T:Codable>(key: KeyType) -> T?
    @discardableResult func get<T:Codable>(key: KeyType, keyspace: String) -> T?
    @discardableResult func all<T:Codable>() -> [T]?
    @discardableResult func all<T:Codable>(keyspace: String) -> [T]?
    @discardableResult func query<T:Codable>(parameters:[param]) -> [T]?
    @discardableResult func query<T:Codable>(keyspace: String, parameters:[param]) -> [T]?
    
    // closure typed results
    func get<T:Codable>(key: KeyType, _ closure: QueryResultClosure<T>) -> T?
    func get<T:Codable>(key: KeyType, keyspace: String, _ closure: QueryResultClosure<T>) -> T?
    func all<T:Codable>(_ closure: QueryResultsClosure<T>) -> [T]?
    func all<T:Codable>(keyspace: String, _ closure: QueryResultsClosure<T>) -> [T]?
    func query<T:Codable>(parameters:[param], _ closure: QueryResultsClosure<T>) -> [T]?
    func query<T:Codable>(keyspace: String, parameters:[param], _ closure: QueryResultsClosure<T>) -> [T]?
    
}