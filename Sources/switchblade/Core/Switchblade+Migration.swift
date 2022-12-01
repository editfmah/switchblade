//
//  File.swift
//  
//
//  Created by Adrian Herridge on 30/11/2022.
//

import Foundation

extension Switchblade : SwitchbladeVersioned {
    public func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: ((FromType) -> ToType?)) where FromType : SWSchemaVersioned, ToType : SWSchemaVersioned {
        provider.migrate(from: from, to: to, migration: migration)
    }
}
