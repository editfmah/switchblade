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
    @discardableResult func get<T:Codable>(partition: String?, key: PrimaryKeyType?, keyspace: String?, compositeKeys: [CompositeComponent]?) -> T?
    @discardableResult func all<T:Codable>(partition: String?, keyspace: String?, filter: [String:String]?) -> [T]
    @discardableResult func query<T:Codable>(partition: String?, keyspace: String?, filter: [String:String]?, _ where: ((T) -> Bool)) -> [T]
    func iterate<T: Codable>(partition: String?, keyspace: String?, filter: [String:String]?, _ closure: @escaping ((_ object: T) -> Void)) 
    /* NOTE: special instructions to pop an item from a table.
            Returns the first match only whilst deleting the original item from the table.
            This operation is ATOMIC so can be deployed in a busy environment and safely used
     */
    @discardableResult func pop<T:Codable>(partition: String, keyspace: String, filter: [String:String]?) -> T?
    
}
