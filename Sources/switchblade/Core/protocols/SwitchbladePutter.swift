//
//  SwitchbladeSetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

fileprivate let default_keyspace = "default"
fileprivate let default_partition = "default"
fileprivate let default_ttl = -1

public protocol SwitchbadePutter {
    
    @discardableResult func put<T:Codable>(partition: String?, keyspace: String?, key: PrimaryKeyType?, compositeKeys: [CompositeComponent]?, ttl: Int?, filter: [Filters]?, _ object: T) -> Bool
    
}
