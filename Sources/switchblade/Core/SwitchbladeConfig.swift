//
//  SwitchbladeConfig.swift
//  Switchblade
//
//  Created by Adrian Herridge on 23/09/2020.
//

import Foundation

public class SwitchbladeConfig {
    public var logDriver: SwitchbladeLogDriver?
    public var hashQueriableProperties: Bool = false
    public var aes256encryptionKey: Data? = nil
    public var randomiseDataTableName: Bool = false
}
