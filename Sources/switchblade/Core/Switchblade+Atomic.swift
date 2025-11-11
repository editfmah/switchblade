//
//  Switchblade+Atomic.swift
//  Switchblade
//
//  Created by Adrian Herridge on 27/09/2020.
//

import Foundation

extension Switchblade: Atomic {
    
    @discardableResult public func perform(_ closure: () -> ()) -> AtomicPostAction {
        lock.mutex {
            provider.transact(.begin)
            closure()
            provider.transact(.commit)
        }
        return AtomicPostAction(self, true)
    }
    
    public func failTransaction() {
        
    }
    
}
