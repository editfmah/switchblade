//
//  File.swift
//  
//
//  Created by Adrian Herridge on 30/11/2022.
//

import Foundation

public protocol SwitchbladeVersioned {
    func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: @escaping ((FromType) -> ToType?)) where FromType : SchemaVersioned, ToType : SchemaVersioned
}

public protocol SchemaVersioned where Self: Codable {
    static var version: (objectName: String, version: Int) { get }
}
