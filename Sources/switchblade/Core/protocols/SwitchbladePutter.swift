//
//  SwitchbladeSetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbadePutter {
    @discardableResult func put<T:Codable>(_ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(keyspace: String, _ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(key: KeyType, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(key: KeyType, keyspace: String, _ object: T) -> Bool
}
