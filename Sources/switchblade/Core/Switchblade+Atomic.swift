//
//  Switchblade+Atomic.swift
//  Switchblade
//
//  Created by Adrian Herridge on 27/09/2020.
//

import Foundation

extension Switchblade: Atomic {
    
    @discardableResult public func perform(_ closure: () -> ()) -> AtomicPostAction {
        // Delegate to the provider so the entire BEGIN / closure / COMMIT
        // sequence executes under the provider's own serialization lock.
        // Locking `Switchblade.lock` here would not prevent other threads
        // from hitting the underlying SQLite connection between BEGIN and
        // COMMIT (which produced SQLITE_MISUSE under load).
        let success = provider.performTransaction(closure)
        return AtomicPostAction(self, success)
    }
    
    public func failTransaction() {
        
    }
    
}
