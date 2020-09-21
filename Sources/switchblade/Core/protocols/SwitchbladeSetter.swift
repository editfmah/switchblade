//
//  SwitchbladeSetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbadeSetter {
    @discardableResult func put(key: String, _ object: Codable) -> Bool
}
