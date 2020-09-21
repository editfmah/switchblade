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

    @discardableResult func put<T: Codable>(key: Data, keyspace: Data,_ object: T) -> Bool
    @discardableResult func delete(key: Data, keyspace: Data) -> Bool
    @discardableResult func get<T>(key: Data, keyspace: Data, _ closure: ((T?, DatabaseError?) -> T?)) -> T? where T : Decodable, T : Encodable
    @discardableResult func query<T: Codable>(keyspace: Data, params: [param]?, _ closure: ((_ results: [T],_ error: DatabaseError?) -> [T]?)) -> [T]?
    @discardableResult func all<T: Codable>(keyspace: Data, _ closure: ((_ results: [T],_ error: DatabaseError?) -> [T]?)) -> [T]?
    
}
