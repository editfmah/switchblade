//
//  SwitchbladeGetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbadeGetter {
    // typed by expected return/assignment value
    @discardableResult func get<T:Codable>(key: KeyType) -> T?
    @discardableResult func get<T:Codable>(key: KeyType, keyspace: String) -> T?
    @discardableResult func all<T:Codable>() -> [T]?
    @discardableResult func all<T:Codable>(keyspace: String) -> [T]?
    @discardableResult func query<T:Codable>(parameters:[param]) -> [T]?
    @discardableResult func query<T:Codable>(keyspace: String, parameters:[param]) -> [T]?
    // closure typed results
    func get<T:Codable>(key: KeyType, _ closure: ((_ object: T?) -> Void))
    func get<T:Codable>(key: KeyType, keyspace: String, _ closure: ((_ object: T?) -> Void))
    func all<T:Codable>(_ closure: ((_ results: [T]?) -> Void))
    func all<T:Codable>(keyspace: String, _ closure: ((_ results: [T]?) -> Void))
    func query<T:Codable>(parameters:[param], _ closure: ((_ results: [T]?) -> Void))
    func query<T:Codable>(keyspace: String, parameters:[param], _ closure: ((_ results: [T]?) -> Void))
}
