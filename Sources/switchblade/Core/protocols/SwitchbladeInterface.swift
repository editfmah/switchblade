//
//  SwitchbladeInterface.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbladeInterface {
    init(provider: DataProvider, configuration: SwitchbladeConfig?) throws
    init(provider: DataProvider, configuration: SwitchbladeConfig?, completion:((_ success: Bool,_ provider: DataProvider, _ error: DatabaseError?) -> Void)?)
    func close() throws
    func close(completion:((_ success: Bool, _ error: DatabaseError?) -> Void)?)
}

