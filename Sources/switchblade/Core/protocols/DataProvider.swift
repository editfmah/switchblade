//
//  ProviderInterface.swift
//  SwiftyShark
//
//  Created by Adrian Herridge on 08/05/2019.
//

import Foundation


public protocol DataProvider {
    
    var table_alias: [String:String] { get set }
    func open() throws
    func close() throws
    func create<T>(_ object: T, pk: String, auto: Bool, indexes: [String]) throws where T: Codable
    
    // async methods
    func put<T>(_ object: T, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable
    func query<T>(_ object: T, parameters: [param], completion: ((_ results: [T],_ error: DatabaseError?) -> Void)?) -> Void where T: Codable
    func delete<T>(_ object: T, parameters: [param], completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable
    func delete<T>(_ object: T, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable

    
}
