//
//  CompositeKey.swift
//  Switchblade
//
//  Created by Adrian Herridge on 24/05/2021.
//

import Foundation

internal func makeCompositeKey(_ components: [CompositeComponent]) -> String {
    
    var keys: [String] = []
    
    for k in components {
        if let key = k as? String {
            keys.append(key)
        }
        if let key = k as? Int {
            keys.append("\(key)")
        }
        if let key = k as? UUID {
            keys.append("\(key)")
        }
        if let key = k as? Date {
            keys.append("\(key.timeIntervalSince1970)")
        }
    }
    
    return keys.joined(separator: "|")
    
}

public protocol CompositeComponent {
    
}

extension String : CompositeComponent {}
extension Int : CompositeComponent {}
extension UUID : CompositeComponent {}
extension Date : CompositeComponent {}
