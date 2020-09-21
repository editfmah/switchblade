//
//  SwitchObject+Queryable.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

protocol Queryable {
    var queryableItems: [String:Any?] { get }
}
