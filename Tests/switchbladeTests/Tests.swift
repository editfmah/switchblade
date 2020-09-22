//
//  Tests.swift
//  SwitchbladeTests
//
//  Created by Adrian Herridge on 02/08/2019.
//

import Foundation
import XCTest
@testable import Switchblade

func initSQLiteDatabase() -> Switchblade {

    let path = FileManager.default.currentDirectoryPath
    let id = UUID().uuidString
    print("Database Opened: \(path)/\(id).db")
    let db = Switchblade(provider: SQLiteProvider(path: "\(path)/\(id).db")) { (success, provider, error) in
        XCTAssert(error == nil, "failed to initialiase")
    }
    return db
    
}


func testPersistObject(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    if db.put(p1) {
        p2.Name = "Neil Bostrom"
        p2.Age = 37
        if db.put(p2) {
            p3.Name = "George Smith"
            p3.Age = 28
            if db.put(p3) {
                return
            }
        }
    }
    
    XCTFail("failed to write one of the records")
    
}

func testPersistQueryObject(_ db: Switchblade) {
    
    let p1 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    if db.put(p1) {
        
    }
    
    XCTFail("failed to write one of the records")
    
}
