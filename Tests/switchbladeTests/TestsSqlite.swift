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
    
    func testPersistSingleObjectAndCheckAll() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            let results: [Person] = db.all(keyspace: p1.keyspace)
            if results.count == 1 {
                return
            } else {
                XCTFail("failed to read back the correct number of records")
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
                    let results: [Person] = db.all(keyspace: p1.keyspace)
                    if results.count == 3 {
                        return
                    } else {
                        XCTFail("failed to read back the correct number of records")
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
                    if let _ : Person = db.all(keyspace: p1.keyspace).first(where: { $0.Age == 41 && $0.Name == "Adrian Herridge" }) {
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
                    let results: [Person] = db.query(keyspace: p1.keyspace) { person in
                        return person.Age == 41
                    }
                    if results.count == 1 {
                        if let result = results.first, result.Name == "Adrian Herridge" {
                            return
                        } else {
                            XCTFail("failed to read back the correct record")
                        }
                    } else {
                        XCTFail("failed to read back the correct record")
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
                    let results: [Person] = db.query(keyspace: p1.keyspace) { result in
                        return result.Age == 41 && result.Name == "Adrian Herridge"
                    }
                    if results.count == 1 {
                        if let result = results.first, result.Name == "Adrian Herridge" {
                            return
                        } else {
                            XCTFail("failed to read back the correct record")
                        }
                    } else {
                        XCTFail("failed to read back the correct record")
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
            if let _: Person = db.get(key: p1.key, keyspace: p1.keyspace) {
                
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
            let retrieved: [Person] = db.query(keyspace: p1.keyspace) { result in
                return result.Age == 41
            }
            if retrieved.count == 1 {
                
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
        
        let results: [Person] = db.query(keyspace: p1.keyspace) { result in
            return result.Age == 41
        }
        if results.count == 1 {
            if let result = results.first, result.Name == "Adrian Herridge" {
                return
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
        
        let results: [Person] = db.query(keyspace: p1.keyspace) { p in
            return p.Age ?? 0 > 30
        }
        if results.count == 2 {
            return
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
        
        let results: [Person] = db.query(keyspace: p1.keyspace) { p in
            if let age = p.Age {
                return age < 40
            }
            return false
        }
        if results.count == 2 {
            return
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
        
        let results: [Person] = db.query(keyspace: p1.keyspace) { p in
            return p.Name == "Neil Bostrom" && p.Age == nil
        }
        if results.count == 1 {
            if let result = results.first, result.Name == "Neil Bostrom" {
                return
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
            let results: [Person] = db.query(keyspace: "person") { p in
                return p.Age == 41
            }
            if results.count == 1 {
                if let result = results.first, result.Name == "Adrian Herridge" {
                    pass = true
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
            let results: [Person] = db.all(keyspace: "person")
            if results.count == 2 {
                pass = true
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
            let results: [Person] = db.all(keyspace: "person")
            if results.count == 10 {
                pass = true
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
            let results: [Person] = db.all(keyspace: "person")
            if results.count == 0 {
                pass = true
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
            let results: [Person] = db.all(keyspace: "person")
            if results.count == 100 {
                pass = true
            }
            db.failTransaction()
        }.success {
            pass = false
        }.failure {
            pass = false
            let results: [Person] = db.all(keyspace: "person")
            if results.count == 0 {
                pass = true
            }
        }
        
        if !pass {
            XCTFail("failed to write one of the recordss")
        }
        
    }
    
    func testBindingsObject() {
        
        let db = initSQLiteDatabase()
        let p1 = Person()
        var pass = false
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(p1)
        let binding = db.bind(key: p1.key, keyspace: p1.keyspace) { (person: Person?) in
            print("binding updated for Person object")
            pass = true
        }
        if pass {
            XCTFail("failed state in binding")
        }
        p1.Age = 41
        db.put(p1)
        
        if !pass {
            XCTFail("failed state in binding")
        }
        
    }
    
    func testBindingsKeyspace() {
        
        let db = initSQLiteDatabase()
        let p1 = Person()
        var pass = false
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(p1)
        
        let binding = db.bind(keyspace: p1.keyspace) { (results: [Person]?) in
            if let results = results {
                if results.count == 2 {
                    pass = true
                }
            }
        }
        
        if pass {
            XCTFail("failed state in binding")
        }
        
        let p2 = Person()
        p2.Name = "Sunjay Kalsi"
        p2.Age = 43
        db.put(p2)
        
        if !pass {
            XCTFail("failed state in binding")
        }
        
    }
    
    func testBindingsQuery() {
        
        let db = initSQLiteDatabase()
        let p1 = Person()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(p1)
        
        let binding = SWBindingCollection<Person>(db, keyspace: p1.keyspace) { (p: Person) in
            return p.Age == 40
        }
        
        if binding.count != 1 {
            XCTFail("failed state in binding")
        }
        
        let p2 = Person()
        p2.Name = "Sunjay Kalsi"
        p2.Age = 40
        db.put(p2)
        
        if binding.count != 2 {
            XCTFail("failed state in binding")
        }
        
    }
    
    func testBindingsObjectReference() {
        
        let db = initSQLiteDatabase()
        let p1 = Person()
        var pass = false
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(p1)
        let binding = db.bind(p1) { (person: Person?) in
            print("binding updated for Person object")
            pass = true
        }
        if pass {
            XCTFail("failed state in binding")
        }
        p1.Age = 41
        db.put(p1)
        if !pass {
            XCTFail("failed state in binding")
        }
        
    }
    
    func testResultFromBinding() {
        
        let db = initSQLiteDatabase()
        let p1 = Person()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(p1)
        let binding = db.bind(p1)
        
        if binding.count != 1 {
            XCTFail("failed state in binding")
        }
        
        if let boundPerson: Person = binding.data(index: 0) {
            if boundPerson.Name != "Adrian Herridge" {
                XCTFail("failed state in binding")
            }
        }
        
        p1.Name = "Sunjay Kalsi"
        p1.Age = 43
        db.put(p1)
        
        if let boundPerson: Person = binding.data(index: 0) {
            if boundPerson.Name != "Sunjay Kalsi" {
                XCTFail("failed state in binding")
            }
        }
        
        if let boundPerson = binding.object {
            if boundPerson.Name != "Sunjay Kalsi" {
                XCTFail("failed state in binding")
            }
        }
        
    }
    
    func testReadWriteFromUserDefaults() {
        
        let db = try! Switchblade(provider: UserDefaultsProvider())
        
        let p1 = Person()
        p1.Name = "Sunjay Kalsi"
        p1.Age = 43
        db.put(p1)
        
        if let _: Person = db.get(key: p1.key, keyspace: p1.keyspace) {
            
        } else {
            XCTFail("failed to get object from provider")
        }
        
        let db2 = try! Switchblade(provider: UserDefaultsProvider())
        if let p2: Person = db2.get(key: p1.key, keyspace: p1.keyspace) {
            print("retrieved record for '\(p2.Name ?? "")'")
        } else {
            XCTFail("failed to get object from provider")
        }
        
    }
    
    func testPersistObjectCompositeKey() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        if db.put(["ad",1,"testing123"],p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 37
            if db.put(["bozzer",2,"testing123"],p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(["george",3,"testing123"],p3) {
                    return
                }
            }
        }
        
        XCTFail("failed to write one of the records")
        
    }
    
    func testPersistQueryObjectCompositeKey() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        if db.put(["ad",1,123,"test",p1.PersonId],p1) {
            if let retrieved: Person = db.get(["ad",1,123,"test",p1.PersonId]) {
                print("retrieved item with id \(retrieved.PersonId)")
                if retrieved.PersonId == p1.PersonId {
                    return
                }
            } else {
                XCTFail("failed to retrieve object")
            }
        }
        
        XCTFail("failed to write one of the records")
        
    }
    
    func testPersistMultipleIterate() {
        
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
                    var results: [Person] = []
                    db.iterate(keyspace: p1.keyspace) { (person: Person) in
                        results.append(person)
                    }
                    if results.count == 3 {
                        return
                    } else {
                        XCTFail("failed to read back the correct number of records")
                    }
                }
            }
        }
        XCTFail("failed to write one of the records")
    }
    
    func testPersistMultipleIterateInspect() {
        
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
                    var results: [Person] = []
                    db.iterate(keyspace: p1.keyspace) { (person: Person) in
                        if person.Age == 38 {
                            results.append(person)
                        }
                    }
                    if results.count == 1 {
                        return
                    } else {
                        XCTFail("failed to read back the correct number of records")
                    }
                }
            }
        }
        XCTFail("failed to write one of the records")
    }
    
    func testTTLTimeout() {
        
        let db = initSQLiteDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        
        p2.Name = "Neil Bostrom"
        p2.Age = 38
        
        p3.Name = "George Smith"
        p3.Age = 28
        
        let _ = db.put(ttl: 1, p1)
        let _ = db.put(ttl: 60, p2)
        let _ = db.put(p3)
        
        Thread.sleep(forTimeInterval: 2.0)
        
        let results: [Person] = db.all(keyspace: p1.keyspace)
        
        if results.count == 2 {
            return
        } else {
            XCTFail("failed to read back the correct number of records")
        }
        
        XCTFail("failed to write one of the records")
    }
    
    func testObjectMigration() {
        
        let db = initSQLiteDatabase()
        
        let id = UUID()
        
        let p1 = PersonVersion1()
        p1.id = id
        p1.name = "Adrian Herridge"
        p1.age = 40
        
        if db.put(key: id, p1) {
            if let _: PersonVersion1 = db.get(key: id) {
                db.migrate(from: PersonVersion1.self, to: PersonVersion2.self) { old in
                    
                    let new = PersonVersion2()
                    
                    new.id = old.id
                    new.age = old.age
                    
                    let components = old.name?.components(separatedBy: " ")
                    new.forename = components?.first
                    new.surname = components?.last
                    
                    return new
                }
                if let updated: PersonVersion2 = db.get(key: id) {
                    if updated.forename == "Adrian" && updated.surname == "Herridge" {
                        return
                    }
                }
            }
        }
        
        XCTFail("failed to write one of the records")
        
    }
    
}

