//
//  SwitchbladeDeleter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbadeDeleter {
    @discardableResult func remove<T:SwitchbladeIdentifiable>(_ object: T) -> Bool
    @discardableResult func remove<T:SwitchbladeIdentifiable>(keyspace: String, _ object: T) -> Bool
    @discardableResult func remove(key: KeyType) -> Bool
    @discardableResult func remove(key: KeyType, keyspace: String) -> Bool
}
