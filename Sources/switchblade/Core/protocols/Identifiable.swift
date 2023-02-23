//
//  SwitchbladeIdentifiable.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol PrimaryKeyType {
    func key() -> String
}

extension Int : PrimaryKeyType {
    public func key() -> String {
        return "\(self)"
    }
}

extension UUID : PrimaryKeyType {
    public func key() -> String {
        return self.uuidString.lowercased()
    }
}

extension String : PrimaryKeyType {
    public func key() -> String {
        return self
    }
}

public protocol Identifiable {
    var key: PrimaryKeyType { get }
}
