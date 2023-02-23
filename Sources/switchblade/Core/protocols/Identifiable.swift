//
//  SwitchbladeIdentifiable.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol PrimaryKeyType {
    func key() -> Data
}

extension Int : PrimaryKeyType {
    public func key() -> Data {
        return "\(self)".md5Data
    }
}

extension UUID : PrimaryKeyType {
    public func key() -> Data {
        return self.uuidString.lowercased().md5Data
    }
}

extension String : PrimaryKeyType {
    public func key() -> Data {
        return self.md5Data
    }
}

public protocol Identifiable {
    var key: PrimaryKeyType { get }
}
