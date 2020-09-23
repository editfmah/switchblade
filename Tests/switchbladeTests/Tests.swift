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

extension switchbladeTests {
    func testPersistObject() {
        
        let db = initSQLiteDatabase()
        
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
    
    func testPersistQueryObject() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        if db.put(p1) {
            if let retrieved: Person = db.get(key: p1.key, keyspace: p1.keyspace) {
                print("retrieved item with id \(retrieved.PersonId)")
                return
            } else {
                XCTFail("failed to retrieve object")
            }
        }
        
        XCTFail("failed to write one of the records")
        
    }
    
    func testPersistMultipleObjectsAndCheckAll() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 38
            if db.put(p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(p3) {
                    if let results: [Person] = db.all(keyspace: p1.keyspace) {
                        if results.count == 3 {
                            return
                        } else {
                            XCTFail("failed to read back the correct number of records")
                        }
                    } else {
                        XCTFail("failed to read back the records")
                    }
                }
            }
        }
        XCTFail("failed to write one of the records")
    }
    
    func testPersistMultipleObjectsAndFilterAll() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 38
            if db.put(p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(p3) {
                    if let _ : Person = db.all(keyspace: p1.keyspace)?.first(where: { $0.Age == 41 && $0.Name == "Adrian Herridge" }) {
                        return
                    } else {
                        XCTFail("failed to read back the correct records")
                    }
                }
            }
        }
        XCTFail("failed to write one of the records")
    }
    
    func testPersistMultipleObjectsAndQuery() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 38
            if db.put(p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(p3) {
                    if let results: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .equals, 41)]) {
                        if results.count == 1 {
                            if let result = results.first, result.Name == "Adrian Herridge" {
                                return
                            } else {
                                XCTFail("failed to read back the correct record")
                            }
                        } else {
                            XCTFail("failed to read back the correct record")
                        }
                    } else {
                        XCTFail("failed to read back the correct records")
                    }
                }
            }
        }
        XCTFail("failed to write one of the records")
    }
    
    func testPersistMultipleObjectsAndQueryMultipleParams() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 41
            if db.put(p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(p3) {
                    if let results: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .equals, 41),.where("name", .equals, "Adrian Herridge")]) {
                        if results.count == 1 {
                            if let result = results.first, result.Name == "Adrian Herridge" {
                                return
                            } else {
                                XCTFail("failed to read back the correct record")
                            }
                        } else {
                            XCTFail("failed to read back the correct record")
                        }
                    } else {
                        XCTFail("failed to read back the correct records")
                    }
                }
            }
        }
        XCTFail("failed to write one of the records")
    }
    
    func testPersistMultipleObjectsAndCheckAllClosure() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 38
            if db.put(p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(p3) {
                    _ = db.all(keyspace: p1.keyspace) { (results) -> [Person]? in
                        return results
                    }
                }
            }
        }
    }
    
}

