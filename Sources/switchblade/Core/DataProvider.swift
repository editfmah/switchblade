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
    
    @discardableResult func put<T: Codable>(partition: String, key: String, keyspace: String, ttl: Int, filter: [String:String]?, _ object: T) -> Bool
    @discardableResult func delete(partition: String, key: String, keyspace: String) -> Bool
    @discardableResult func get<T:Codable>(partition: String, key: String, keyspace: String) -> T?
    @discardableResult func query<T: Codable>(partition: String, keyspace: String, filter: [String:String]?, map: ((T) -> Bool)) -> [T]
    @discardableResult func all<T: Codable>(partition: String, keyspace: String, filter: [String:String]?) -> [T]
    
    func iterate<T: Codable>(partition: String, keyspace: String, filter: [String:String]?, iterator: ((T) -> Void))
    func migrate<FromType: SchemaVersioned, ToType: SchemaVersioned>(from: FromType.Type, to: ToType.Type, migration: @escaping ((FromType) -> ToType?))
    @discardableResult func ids(partition: String, keyspace: String, filter: [String:String]?) -> [String]
    
    var config: SwitchbladeConfig! { get set }
    var blade: Switchblade! { get set }
    
}

public extension DataProvider {
    /// Run `closure` such that, where the underlying provider supports it, all
    /// data operations performed by `closure` execute atomically as a single
    /// transaction and are serialized against any other concurrent provider
    /// operations.
    ///
    /// The default implementation simply runs the closure (suitable for
    /// providers that do not support transactional semantics, such as the
    /// shard provider — transactions cannot span shards). Concrete providers
    /// backed by a single SQLite connection should override this to take
    /// their internal lock and wrap `closure` in BEGIN/COMMIT.
    @discardableResult
    func performTransaction(_ closure: () -> Void) -> Bool {
        closure()
        return true
    }
}
