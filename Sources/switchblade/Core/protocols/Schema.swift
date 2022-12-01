//
//  File.swift
//  
//
//  Created by Adrian Herridge on 30/11/2022.
//

import Foundation

public protocol SwitchbladeVersioned {
    func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: ((FromType) -> ToType?)) where FromType : SWSchemaVersioned, ToType : SWSchemaVersioned
}

public protocol SWSchemaVersioned where Self: Codable {
    static var version: (objectName: String, version: Int) { get }
}
