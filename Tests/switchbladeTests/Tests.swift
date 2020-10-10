//
//  Tests.swift
//  SwitchbladeTests
//
//  Created by Adrian Herridge on 02/08/2019.
//

import Foundation
import XCTest
@testable import Switchblade

func initSQLiteDatabase(_ config: SwitchbladeConfig? = nil) -> Switchblade {
    
    let path = FileManager.default.currentDirectoryPath
    let id = UUID().uuidString
    print("Database Opened: \(path)/\(id).db")
    let db = Switchblade(provider: SQLiteProvider(path: "\(path)/\(id).db"), configuration: config) { (success, provider, error) in
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
    
    func testPersistAndQueryObjectEncrypted() {
        
        let config = SwitchbladeConfig()
        config.aes256encryptionKey = Data("big_sprouts".utf8)
        let db = initSQLiteDatabase(config)
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            if let retrieved: Person = db.get(key: p1.key, keyspace: p1.keyspace) {
                
            } else {
                XCTFail("failed to retrieve one of the records")
            }
        } else {
            XCTFail("failed to write one of the records")
        }
    }
    
    func testPersistAndQueryObjectEncryptedWrongSeed() {
        
        let config = SwitchbladeConfig()
        config.aes256encryptionKey = Data("big_sprouts".utf8)
        let db = initSQLiteDatabase(config)
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            config.aes256encryptionKey = Data("small_sprouts".utf8)
            if let retrieved: Person = db.get(key: p1.key, keyspace: p1.keyspace) {
                XCTFail("failed to retrieve one of the records")
            } else {
                
            }
        } else {
            XCTFail("failed to write one of the records")
        }
    }
    
    func testPersistAndQueryObjectPropertiesEncrypted() {
        
        let config = SwitchbladeConfig()
        config.aes256encryptionKey = Data("big_sprouts".utf8)
        config.hashQueriableProperties = true
        let db = initSQLiteDatabase(config)
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            if let retrieved: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .equals, 41)]) {
                if retrieved.count == 1 {
                    
                } else {
                    XCTFail("failed to retrieve one of the records")
                }
            } else {
                XCTFail("failed to retrieve one of the records")
            }
        } else {
            XCTFail("failed to write one of the records")
        }
    }
    
    func testQueryParamEqualls() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        db.put(p1)
        p2.Name = "Neil Bostrom"
        p2.Age = 38
        db.put(p2)
        p3.Name = "George Smith"
        p3.Age = 28
        db.put(p3)
        
        if let results: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .equals, 41)]) {
            if results.count == 1 {
                if let result = results.first, result.Name == "Adrian Herridge" {
                    return
                }
            }
        }
        
        XCTFail("failed to write one of the recordss")
    }
    
    func testQueryParamGreaterThan() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        db.put(p1)
        p2.Name = "Neil Bostrom"
        p2.Age = 38
        db.put(p2)
        p3.Name = "George Smith"
        p3.Age = 28
        db.put(p3)
        
        if let results: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .greater, 30)]) {
            if results.count == 2 {
                return
            }
        }
        
        XCTFail("failed to write one of the recordss")
    }
    
    func testQueryParamLessThan() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        db.put(p1)
        p2.Name = "Neil Bostrom"
        p2.Age = 38
        db.put(p2)
        p3.Name = "George Smith"
        p3.Age = 28
        db.put(p3)
        
        if let results: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .less, 40)]) {
            if results.count == 2 {
                return
            }
        }
        
        XCTFail("failed to write one of the recordss")
    }
    
    func testQueryParamIsNull() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        db.put(p1)
        p2.Name = "Neil Bostrom"
        p2.Age = nil
        db.put(p2)
        p3.Name = "George Smith"
        p3.Age = 28
        db.put(p3)
        
        if let results: [Person] = db.query(keyspace: p1.keyspace, parameters: [.where("age", .isnull, nil),.where("name", .equals, "Neil Bostrom")]) {
            if results.count == 1 {
                if let result = results.first, result.Name == "Neil Bostrom" {
                    return
                }
            }
        }
        
        XCTFail("failed to write one of the recordss")
    }
    
    func testTransaction() {
        
        var pass = false
        
        
        let db = initSQLiteDatabase()
        db.perform {
            let p1 = Person()
            p1.Name = "Adrian Herridge"
            p1.Age = 41
            db.put(p1)
        }.finally {
            if let results: [Person] = db.query(keyspace: "person", parameters: [.where("age", .equals, 41)]) {
                if results.count == 1 {
                    if let result = results.first, result.Name == "Adrian Herridge" {
                        pass = true
                    }
                }
            }
        }
        
        if !pass {
            XCTFail("failed to write one of the recordss")
        }
        
    }
    
    func testMultipleTransactions() {
        
        var pass = false
        
        
        let db = initSQLiteDatabase()
        db.perform {
            let p1 = Person()
            p1.Name = "Adrian Herridge"
            p1.Age = 41
            db.put(p1)
        }
        
        db.perform {
            let p = Person()
            p.Name = "Neil Bostrom"
            p.Age = 38
            db.put(p)
        }.finally {
            if let results: [Person] = db.all(keyspace: "person") {
                if results.count == 2 {
                    pass = true
                }
            }
        }
        
        if !pass {
            XCTFail("failed to write one of the recordss")
        }
        
    }
    
    func testLoopedTransactions() {
        
        var pass = false
        
        let db = initSQLiteDatabase()
        db.perform {
            for idx in 1...10 {
                let p = Person()
                p.Name = "Person \(idx)"
                p.Age = idx
                db.put(p)
            }
        }.finally {
            if let results: [Person] = db.all(keyspace: "person") {
                if results.count == 10 {
                    pass = true
                }
            }
        }
        
        if !pass {
            XCTFail("failed to write one of the recordss")
        }
        
    }
    
    func testTransactionsInsertDelete() {
        
        var pass = false
        
        let db = initSQLiteDatabase()
        db.perform {
            for idx in 1...10 {
                let p = Person()
                p.Name = "Person \(idx)"
                p.Age = idx
                db.put(p)
                db.remove(p)
            }
        }.finally {
            if let results: [Person] = db.all(keyspace: "person") {
                if results.count == 0 {
                    pass = true
                }
            }
        }
        
        if !pass {
            XCTFail("failed to write one of the recordss")
        }
        
    }
    
    func testTransactionRollback() {
        
        var pass = false
        
        let db = initSQLiteDatabase()
        db.perform {
            for idx in 1...100 {
                let p = Person()
                p.Name = "Person \(idx)"
                p.Age = idx
                db.put(p)
            }
            if let results: [Person] = db.all(keyspace: "person") {
                if results.count == 100 {
                    pass = true
                }
            }
            db.failTransaction()
        }.success {
            pass = false
        }.failure {
            pass = false
            if let results: [Person] = db.all(keyspace: "person") {
                if results.count == 0 {
                    pass = true
                }
            }
        }
        
        if !pass {
            XCTFail("failed to write one of the recordss")
        }
        
    }
    
}

