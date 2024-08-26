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
    @discardableResult func all<T:Codable>(partition: String?, keyspace: String?, filter: [Filters]?) -> [T]
    @discardableResult func query<T:Codable>(partition: String?, keyspace: String?, filter: [Filters]?, _ where: ((T) -> Bool)) -> [T]
    func iterate<T: Codable>(partition: String?, keyspace: String?, filter: [Filters]?, _ closure: @escaping ((_ object: T) -> Void)) 
    
}
