//
//  ProviderInterface.swift
//  SwiftyShark
//
//  Created by Adrian Herridge on 08/05/2019.
//

import Foundation



public enum op {
    case equals
    case greater
    case less
    case isnull
    case isnotnull
}

public enum param: Equatable {
    
    public static func == (lhs: param, rhs: param) -> Bool {
        switch (lhs, rhs) {
        case (.where(_,_,_),.where(_,_,_)):
            return true
        case (.limit(_),.limit(_)):
            return true
//        case (.or(_),.or(_)):
//            return true
        case (.order(_),.order(_)):
            return true
        case (.offset(_),.offset(_)):
            return true
        default:
            return false
        }
    }
    
    case `where`(_ column: String,op,Any?)
    case limit(Int)
    case order(String)
    case offset(Int)
    // case or([param])
    
}


public protocol DataProvider {
    
    func open() throws
    func close() throws
    func create<T>(_ object: T, pk: String, auto: Bool, indexes: [String]) throws where T: Codable
    
    // async methods
    func put<T>(_ object: T, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable
    func query<T>(_ object: T, parameters: [param], completion: ((_ results: [T],_ error: DatabaseError?) -> Void)?) -> Void where T: Codable
    func delete<T>(_ object: T, parameters: [param], completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable
    func delete<T>(_ object: T, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable

    
}
