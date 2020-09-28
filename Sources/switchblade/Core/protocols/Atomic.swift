//
//  Atomic.swift
//  Switchblade
//
//  Created by Adrian Herridge on 27/09/2020.
//

import Foundation

typealias AtomicClosure = (()->())

protocol Atomic {
    @discardableResult func perform(_ closure: AtomicClosure) -> AtomicPostAction
}

class AtomicPostAction {
    
    let blade: Switchblade!
    let succeeded: Bool!
    
    init(_ blade: Switchblade,_ succeeded: Bool) {
        self.blade = blade
        self.succeeded = succeeded
    }
    
    @discardableResult func failure(_ closure: AtomicClosure) -> AtomicPostAction {
        if succeeded == false {
            closure()
        }
        return self
    }
    
    @discardableResult func success(_ closure: AtomicClosure) -> AtomicPostAction {
        if succeeded == true {
            closure()
        }
        return self
    }
    
    func finally(_ closure: AtomicClosure) {
        closure()
    }
}


