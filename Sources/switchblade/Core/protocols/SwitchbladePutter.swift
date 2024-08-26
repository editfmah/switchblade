//
//  SwitchbladeSetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate var default_keyspace = "default"
fileprivate var default_partition = "default"
fileprivate var default_ttl = -1

public protocol SwitchbadePutter {
    
    @discardableResult func put<T:Codable>(partition: String?, keyspace: String?, key: PrimaryKeyType?, compositeKeys: [CompositeComponent]?, ttl: Int?, filter: [Filters]?, _ object: T) -> Bool
    
}
