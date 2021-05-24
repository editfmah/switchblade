//
//  SwitchbladeDeleter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbadeRemove {
    @discardableResult func remove<T:Identifiable>(_ object: T) -> Bool
    @discardableResult func remove<T:Identifiable>(keyspace: String, _ object: T) -> Bool
    @discardableResult func remove(key: KeyType) -> Bool
    @discardableResult func remove(key: KeyType, keyspace: String) -> Bool
    @discardableResult func remove(_ compositeKeys: [CompositeComponent]) -> Bool
}
