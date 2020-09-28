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
    @discardableResult func put<T: Codable>(key: Data, keyspace: Data,_ object: T) -> Bool
    @discardableResult func delete(key: Data, keyspace: Data) -> Bool
    @discardableResult func get<T:Codable>(key: Data, keyspace: Data) -> T?
    @discardableResult func query<T: Codable>(keyspace: Data, params: [param]?) -> [T]?
    @discardableResult func all<T: Codable>(keyspace: Data) -> [T]?
    
    var config: SwitchbladeConfig! { get set }
    var blade: Switchblade! { get set }
    
}
