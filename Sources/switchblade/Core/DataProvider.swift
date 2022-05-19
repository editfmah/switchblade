//
//  ProviderInterface.swift
//  SwiftyShark
//
//  Created by Adrian Herridge on 08/05/2019.
//

import Foundation

public protocol DataProvider {
    
    func open() throws
    func close() throws

    @discardableResult func transact(_ mode: transaction) -> Bool
    
    @discardableResult func put<T: Codable>(partition: String, key: String, keyspace: String, ttl: Int, _ object: T) -> Bool
    @discardableResult func delete(partition: String, key: String, keyspace: String) -> Bool
    @discardableResult func get<T:Codable>(partition: String, key: String, keyspace: String) -> T?
    @discardableResult func query<T: Codable>(partition: String, keyspace: String, params: [param]?) -> [T]
    @discardableResult func all<T: Codable>(partition: String, keyspace: String) -> [T]

    var config: SwitchbladeConfig! { get set }
    var blade: Switchblade! { get set }
    
}

internal protocol DataProviderPrivate {
    @discardableResult func put(partition: String, key: String, keyspace: String, object: Data?, queryKeys: [Data]?, ttl: Int) -> Bool
}
