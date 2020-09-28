//
//  PublicEnums.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public enum transaction {
    case begin
    case commit
    case rollback
}

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
        case (.order(_),.order(_)):
            return true
        case (.offset(_),.offset(_)):
            return true
        default:
            return false
        }
    }
    
    case `where`(_ key: String,op,Any?)
    case limit(Int)
    case order(String)
    case offset(Int)
    
}
