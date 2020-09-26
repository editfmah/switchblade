//
//  SwitchbladeIdentifiable.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol KeyType {
    func key() -> Data
}

extension Int : KeyType {
    public func key() -> Data {
        return "\(self)".data(using: .utf8) ?? Data()
    }
}

extension UUID : KeyType {
    public func key() -> Data {
        return "\(self)".data(using: .utf8) ?? Data()
    }
}

extension String : KeyType {
    public func key() -> Data {
        return self.data(using: .utf8) ?? Data()
    }
}

public protocol Identifiable {
    var key: KeyType { get }
}
