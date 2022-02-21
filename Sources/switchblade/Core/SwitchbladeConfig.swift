//
//  SwitchbladeConfig.swift
//  Switchblade
//
//  Created by Adrian Herridge on 23/09/2020.
//

import Foundation

public class SwitchbladeConfig {
    var logDriver: SwitchbladeLogDriver?
    var hashQueriableProperties: Bool = false
    var aes256encryptionKey: Data? = nil
}
