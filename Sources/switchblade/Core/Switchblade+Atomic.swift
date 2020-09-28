//
//  Switchblade+Atomic.swift
//  Switchblade
//
//  Created by Adrian Herridge on 27/09/2020.
//

import Foundation

extension Switchblade: Atomic {
    
    func perform(_ closure: () -> ()) -> AtomicPostAction {
        var succeed = true
        if let mutex = Switchblade.locks[instance] {
            mutex.mutex {
                Switchblade.errors[instance] = false
                provider.transact(.begin)
                closure()
                if let errors = Switchblade.errors[instance] {
                    if errors {
                        provider.transact(.rollback)
                        succeed = false
                    } else {
                        provider.transact(.commit)
                    }
                }
            }
        }
        return AtomicPostAction(self, succeed)
    }
    
}
