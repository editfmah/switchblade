//
//  Filterable.swift
//  
//
//  Created by Adrian Herridge on 27/12/2022.
//

import Foundation

public protocol Filterable {
    var filters: [String:String] { get }
}
