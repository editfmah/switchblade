//
//  TestsSqliteShards.swift
//  Switchblade
//
//  Created by Adrian on 20/10/2024.
//

import Foundation
import XCTest
@testable import Switchblade

fileprivate func initSQLiteShardDatabase(_ config: SwitchbladeConfig? = nil) -> Switchblade {
    
    let path = FileManager.default.currentDirectoryPath + "/" + UUID().uuidString
    print("Database(s) opened in: \(path)/")
    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    let db = Switchblade(provider: SQLiteShardProvider(path: "\(path)/"), configuration: config) { (success, provider, error) in
        XCTAssert(error == nil, "failed to initialiase")
    }
    return db
    
}

extension switchbladeTests {
    
    func testShardPersistObject() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistQueryObject() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistSingleObjectAndCheckAll() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    
    func testShardPersistMultipleObjectsAndCheckAll() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistMultipleObjectsAndFilterAll() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistMultipleObjectsMultiplePartitionsAndQuery() {
        
        let db = initSQLiteShardDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(partition: "partition1" , p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 38
            if db.put(partition: "partition2", p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(partition: "partition3", p3) {
                    let results: [Person] = db.query(partition: "partition1", keyspace: p1.keyspace) { person in
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
    
    func testShardPersistMultipleObjectsAndQuery() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistMultipleObjectsAndIds() {
        
        let db = initSQLiteShardDatabase()
        
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
                    let ids: [String] = db.ids(keyspace: p1.keyspace).map({ $0.uppercased() })
                    if ids.count == 3 {
                        if ids.contains(p1.PersonId.uuidString.uppercased()) && ids.contains(p2.PersonId.uuidString.uppercased()) && ids.contains(p3.PersonId.uuidString.uppercased()) {
                            return
                        }
                    }
                }
            }
        }
        XCTFail("did not retireve the correct IDs")
    }
    
    func testShardPersistMultipleObjectsAndIdsWithFilter() {
        
        let db = initSQLiteShardDatabase()
        
        let p1 = PersonFilterable()
        let p2 = PersonFilterable()
        let p3 = PersonFilterable()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 41
        if db.put(p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 38
            if db.put(p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(p3) {
                    let ps: [Person] = db.all(keyspace: p1.keyspace, filter: [.int(name: "age", value: 41)])
                    let ids: [String] = db.ids(keyspace: p1.keyspace, filter: [.int(name: "age", value: 41)]).map({ $0.uppercased() })
                    if ids.count == 1 {
                        if ids.contains(p1.PersonId.uuidString.uppercased()) {
                            return
                        }
                    }
                }
            }
        }
        XCTFail("did not retireve the correct IDs")
    }
    
    
    func testShardPersistMultipleObjectsAndQueryMultipleParams() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistAndQueryObjectEncrypted() {
        
        let config = SwitchbladeConfig()
        config.aes256encryptionKey = Data("big_sprouts".utf8)
        let db = initSQLiteShardDatabase(config)
        
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
    
    func testShardPersistAndQueryObjectEncryptedWrongSeed() {
        
        let config = SwitchbladeConfig()
        config.aes256encryptionKey = Data("big_sprouts".utf8)
        let db = initSQLiteShardDatabase(config)
        
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
    
    func testShardPersistAndQueryObjectPropertiesEncrypted() {
        
        let config = SwitchbladeConfig()
        config.aes256encryptionKey = Data("big_sprouts".utf8)
        config.hashQueriableProperties = true
        let db = initSQLiteShardDatabase(config)
        
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
    
    func testShardQueryParamEqualls() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardQueryParamGreaterThan() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardQueryParamLessThan() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardQueryParamIsNull() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardTransaction() {
        
        var pass = false
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardMultipleTransactions() {
        
        var pass = false
        
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardLoopedTransactions() {
        
        var pass = false
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardTransactionsInsertDelete() {
        
        var pass = false
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardTransactionRollback() {
        
        var pass = false
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardBindingsObject() {
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardBindingsKeyspace() {
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardBindingsQuery() {
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardBindingsObjectReference() {
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardResultFromBinding() {
        
        let db = initSQLiteShardDatabase()
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
    
    func testShardReadWriteFromUserDefaults() {
        
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
    
    func testShardPersistObjectCompositeKey() {
        
        let db = initSQLiteShardDatabase()
        
        let p1 = Person()
        let p2 = Person()
        let p3 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        if db.put(compositeKeys: ["ad",1,"testing123"],p1) {
            p2.Name = "Neil Bostrom"
            p2.Age = 37
            if db.put(compositeKeys: ["bozzer",2,"testing123"],p2) {
                p3.Name = "George Smith"
                p3.Age = 28
                if db.put(compositeKeys: ["george",3,"testing123"],p3) {
                    return
                }
            }
        }
        
        XCTFail("failed to write one of the records")
        
    }
    
    func testShardPersistQueryObjectCompositeKey() {
        
        let db = initSQLiteShardDatabase()
        
        let p1 = Person()
        
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        if db.put(compositeKeys: ["ad",1,123,"test",p1.PersonId],p1) {
            if let retrieved: Person = db.get(compositeKeys: ["ad",1,123,"test",p1.PersonId]) {
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
    
    func testShardPersistMultipleIterate() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardPersistMultipleIterateInspect() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardTTLTimeout() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardObjectMigration() {
        
        let db = initSQLiteShardDatabase()
        
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
    
    func testShardFilter() {

        let db = initSQLiteShardDatabase()

        let p1 = Person()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)], p1)

        let p2 = Person()
        p2.Name = "Adrian Herridge"
        p2.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)], p2)

        let p3 = Person()
        p3.Name = "Adrian Herridge"
        p3.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: false)], p3)

        let results: [Person] = db.all(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)])
        if results.count == 2 {
            return
        }

        XCTFail("failed to write one of the records")

    }

    func testShardFilterMultiple() {

        let db = initSQLiteShardDatabase()

        let p1 = Person()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true), .int(name: "extravar", value: 123)], p1)

        let p2 = Person()
        p2.Name = "Adrian Herridge"
        p2.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)], p2)

        let p3 = Person()
        p3.Name = "Adrian Herridge"
        p3.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: false)], p3)

        let results: [Person] = db.all(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)])
        if results.count == 2 {
            return
        }

        XCTFail("failed to write one of the records")

    }

    func testShardFilterMultipleAND() {

        let db = initSQLiteShardDatabase()

        let p1 = Person()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true), .int(name: "extravar", value: 123)], p1)

        let p2 = Person()
        p2.Name = "Adrian Herridge"
        p2.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)], p2)

        let p3 = Person()
        p3.Name = "Adrian Herridge"
        p3.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: false)], p3)

        let results: [Person] = db.all(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true), .int(name: "extravar", value: 123)])
        if results.count == 1 {
            return
        }

        XCTFail("failed to write one of the records")

    }

    func testShardFilterMultipleNegative() {

        let db = initSQLiteShardDatabase()

        let p1 = Person()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true), .int(name: "extravar", value: 1234)], p1)

        let p2 = Person()
        p2.Name = "Adrian Herridge"
        p2.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true)], p2)

        let p3 = Person()
        p3.Name = "Adrian Herridge"
        p3.Age = 40
        db.put(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: false)], p3)

        let results: [Person] = db.all(partition: "default", keyspace: p1.keyspace, filter: [.bool(name: "crazyvar", value: true), .int(name: "extravar", value: 123)])
        if results.count == 0 {
            return
        }

        XCTFail("failed to write one of the records")

    }

    func testShardFilterProtocolConformance() {

        let db = initSQLiteShardDatabase()

        let p1 = PersonFilterable()
        p1.Name = "Adrian Herridge"
        p1.Age = 40
        db.put(partition: "default", keyspace: "person", filter: [.int(name: "age", value: 40)], p1)

        let p2 = PersonFilterable()
        p2.Name = "Neil Bostrom"
        p2.Age = 40
        db.put(partition: "default", keyspace: "person", filter: [.int(name: "age", value: 40)], p2)

        let p3 = PersonFilterable()
        p3.Name = "Sarah Herridge"
        p3.Age = 40
        db.put(partition: "default", keyspace: "person", filter: [.int(name: "age", value: 40)], p3)

        let results: [PersonFilterable] = db.all(partition: "default", keyspace: "person", filter: [.int(name: "age", value: 40)])
        if results.count != 3 {
            XCTFail("failed to get the correct filtered records")
        }

        let results2: [PersonFilterable] = db.all(partition: "default", keyspace: "person", filter: [.string(name: "name", value: "Neil Bostrom")])
        if results2.count != 1 {
            XCTFail("failed to get the correct filtered records")
        }

    }
    
}

