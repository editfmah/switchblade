//
//  Execute.swift
//  Switchblade
//
//  Created by Adrian Herridge on 02/12/2020.
//

import Foundation
import Dispatch

public class Execute {
    
    public class func backgroundAfter(after: Double, _ closure:@escaping (()->())) {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + after, execute: {
           closure()
        })
    }
    
    public class func background(_ closure:@escaping (()->())) {
        DispatchQueue.global(qos: .default).async {
            closure()
        }
    }
    
    public class func forever(_ closure:@escaping (()->())) {
        while true  {
            let waiter = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .default).async {
                closure()
                waiter.signal()
            }
            waiter.wait()
        }
    }
    
    public class func serial(_ closure:@escaping (()->())) {
        DispatchQueue.global(qos: .background).sync {
            closure()
        }
    }
    
    public class func main(_ closure:@escaping (()->())) {
        DispatchQueue.main.async {
            closure()
        }
    }
    
}
