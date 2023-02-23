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
    
    @discardableResult func put<T: Codable>(partition: Data, key: Data, keyspace: Data, ttl: Int, filter: String, _ object: T) -> Bool
    @discardableResult func delete(partition: Data, key: Data, keyspace: Data) -> Bool
    @discardableResult func get<T:Codable>(partition: Data, key: Data, keyspace: Data) -> T?
    @discardableResult func query<T: Codable>(partition: Data, keyspace: Data, filter: [String:String]?, map: ((T) -> Bool)) -> [T]
    @discardableResult func all<T: Codable>(partition: Data, keyspace: Data, filter: [String:String]?) -> [T]
    
    func iterate<T: Codable>(partition: Data, keyspace: Data, filter: [String:String]?, iterator: ((T) -> Void))
    func migrate<FromType: SchemaVersioned, ToType: SchemaVersioned>(from: FromType.Type, to: ToType.Type, migration: ((FromType) -> ToType?))
    
    var config: SwitchbladeConfig! { get set }
    var blade: Switchblade! { get set }
    
}
