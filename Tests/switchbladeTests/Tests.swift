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
    
    let db = Switchblade(provider: SQLiteProvider(path: "\(UUID().uuidString).db")) { (success, provider, error) in
        XCTAssert(error == nil, "failed to initialiase")
    }
    
    db.create(Person(), pk: "PersonId", auto: false, indexes: []) { (success, error) in
    }
    
    db.create(Department(), pk: "DepartmentId", auto: false, indexes: []) { (success, error) in
    }
    
    return db
    
}

func initCassandraDatabase() -> Switchblade {
    
    let id = "\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8))"

    let db = Switchblade(provider:  CassandraProvider(keyspace: "unit_tests", host: "159.65.51.108", port: 9042)) { (success, provider, error) in
        XCTAssert(error == nil, "failed to initialiase")
        var prov = provider
        prov.table_alias["Person"] = "Person_\(id)"
        prov.table_alias["Department"] = "Department_\(id)"
    }
    
    db.create(Person(), pk: "PersonId", auto: false, indexes: []) { (success, error) in
    }
    
    db.create(Department(), pk: "DepartmentId", auto: false, indexes: []) { (success, error) in
    }
    
    // we need to give the eventual consistency time to replicate
    Thread.sleep(forTimeInterval: 1)
    
    return db
    
}


func testPersist(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    _ = try! db.put(p1)
    
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    _ = try! db.put(p2)
    
    p3.Name = "George Smith"
    p3.Age = 28
    _ = try! db.put(p3)
    
}

func testPersistAsync(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    p3.Name = "George Smith"
    p3.Age = 28

    let waiter = DispatchSemaphore(value: 0)
    db.put(p1) { (success, error) in
        XCTAssert(error == nil, "failed to write `Person` object")
        db.put(p2) { (success, error) in
            XCTAssert(error == nil, "failed to write `Person` object")
            db.put(p3) { (success, error) in
                XCTAssert(error == nil, "failed to write `Person` object")
                waiter.signal()
            }
        }
    }
    waiter.wait()
}

func testQuery(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    _ = try? db.put(p1)
    
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    _ = try? db.put(p2)
    
    p3.Name = "George Smith"
    p3.Age = 28
    _ = try? db.put(p3)
    let waiter = DispatchSemaphore(value: 0)
    db.query(Person(), []) { (results, error) in
        XCTAssert(error == nil, "failed to query `Person` object")
        XCTAssert(results.count == 3, "incorrect number of results")
        waiter.signal()
    }
    waiter.wait()
}

func testQueryAsync(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    p3.Name = "George Smith"
    p3.Age = 28
    
    let waiter = DispatchSemaphore(value: 0)
    
    db.put(p1) { (success, error) in
        XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
        db.put(p2) { (success, error) in
            XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
            db.put(p3) { (success, error) in
                XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
                db.query(Person(), []) { (results, error) in
                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                    XCTAssert(results.count == 3, "incorrect number of results with error '\(error!)")
                    waiter.signal()
                }
            }
        }
    }
    
    waiter.wait()
}

func testDeleteAsync(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    p3.Name = "George Smith"
    p3.Age = 28
    
    let waiter = DispatchSemaphore(value: 0)
    
    db.put(p1) { (success, error) in
        XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
        db.put(p2) { (success, error) in
            XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
            db.put(p3) { (success, error) in
                XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
                db.query(Person(), []) { (results, error) in
                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                    XCTAssert(results.count == 3, "incorrect number of results")
                    
                    // now delete these items, individually
                    db.delete(p1, completion: { (success, error) in
                        XCTAssert(error == nil, "failed to delete `Person` object with error '\(error!)")
                        db.delete(p2, completion: { (success, error) in
                            XCTAssert(error == nil, "failed to delete `Person` object with error '\(error!)")
                            db.delete(p3, completion: { (success, error) in
                                XCTAssert(error == nil, "failed to delete `Person` object with error '\(error!)'")
                                
                                // now query to check 0 in db
                                db.query(Person(), []) { (results, error) in
                                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                    XCTAssert(results.count == 0, "incorrect number of results")
                                    waiter.signal()
                                }
                                
                            })
                        })
                    })
                    
                    
                }
            }
        }
    }
    
    waiter.wait()
    
}

func testUpdateAsync(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    p3.Name = "George Smith"
    p3.Age = 28
    
    let waiter = DispatchSemaphore(value: 0)
    db.put(p1) { (success, error) in
        XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
        db.put(p2) { (success, error) in
            XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
            db.put(p3) { (success, error) in
                XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
                db.query(Person(), []) { (results, error) in
                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                    XCTAssert(results.count == 3, "incorrect number of results")
                    
                    // now update these items, individually
                    p2.Age = 40
                    db.put(p2, completion: { (success, error) in
                        XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
                        db.query(Person(), [.where("Age", .equals, 40)]) { (results, error) in
                            XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                            XCTAssert(results.count == 2, "incorrect number of results")
                            waiter.signal()
                        }
                        
                    })
                    
                }
            }
        }
    }
    waiter.wait()
    
}

func testQueryActionsAsync(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    p3.Name = "George Smith"
    p3.Age = 28
    
    let waiter = DispatchSemaphore(value: 0)
    
    db.put(p1) { (success, error) in
        XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
        db.put(p2) { (success, error) in
            XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
            db.put(p3) { (success, error) in
                XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
                db.query(Person(), []) { (results, error) in
                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                    XCTAssert(results.count == 3, "incorrect number of results")
                    
                    // now query these items in a number if different ways
                    db.query(Person(), .where("Age", .equals, 40), completion: { (results, error) in
                        XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                        XCTAssert(results.count == 1, "incorrect number of results")
                        db.query(Person(), .where("Age", .equals, 37), completion: { (results, error) in
                            XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                            XCTAssert(results.count == 1, "incorrect number of results")
                            db.query(Person(), .where("Age", .greater, 1), completion: { (results, error) in
                                XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                XCTAssert(results.count == 3, "incorrect number of results")
                                db.query(Person(), .where("Age", .less, 38), completion: { (results, error) in
                                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                    XCTAssert(results.count == 2, "incorrect number of results")
                                    db.query(Person(), .where("Age", .isnotnull, nil), completion: { (results, error) in
                                        XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                        XCTAssert(results.count == 3, "incorrect number of results")
                                        db.query(Person(), [.where("Age", .equals, 40),.where("Name", .equals, "Adrian Herridge")], completion: { (results, error) in
                                            XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                            XCTAssert(results.count == 1, "incorrect number of results")
                                            db.query(Person(), [.where("Age", .equals, 40),.where("Name", .equals, "Adrian Herridg")], completion: { (results, error) in
                                                XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                                XCTAssert(results.count == 0, "incorrect number of results")
                                                waiter.signal()
                                            })
                                        })
                                    })
                                })
                            })
                        })
                    })
                    
                }
            }
        }
    }
    
    waiter.wait()
    
}

func testCRUDAsync(_ db: Switchblade) {
    
    let p1 = Person()
    let p2 = Person()
    let p3 = Person()
    
    p1.Name = "Adrian Herridge"
    p1.Age = 40
    p2.Name = "Neil Bostrom"
    p2.Age = 37
    p3.Name = "George Smith"
    p3.Age = 28
    
    let waiter = DispatchSemaphore(value: 0)
    
    db.put(p1) { (success, error) in
        XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
        db.put(p2) { (success, error) in
            XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
            db.put(p3) { (success, error) in
                XCTAssert(error == nil, "failed to write `Person` object with error '\(error!)")
                db.query(Person(), []) { (results, error) in
                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                    XCTAssert(results.count == 3, "incorrect number of results")
                    // now query these items in a number if different ways
                    db.delete(p1, completion: { (success, error) in
                        XCTAssert(error == nil, "failed to delete `Person` object with error '\(error!)")
                        db.query(Person(), []) { (results, error) in
                            XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                            XCTAssert(results.count == 2, "incorrect number of results")
                            p2.Age = 28
                            db.put(p2, completion: { (success, error) in
                                XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                db.query(Person(), [.where("Age", .equals, 28)]) { (results, error) in
                                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                    XCTAssert(results.count == 2, "incorrect number of results")
                                    db.query(Person(), [.where("Age", .equals, 37)]) { (results, error) in
                                        XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                        XCTAssert(results.count == 0, "incorrect number of results")
                                        p2.Age = 37
                                        db.put(p2, completion: { (success, error) in
                                            XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                            db.query(Person(), [.where("Age", .equals, 28)]) { (results, error) in
                                                XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                                XCTAssert(results.count == 1, "incorrect number of results")
                                                db.query(Person(), [.where("Age", .equals, 37)]) { (results, error) in
                                                    XCTAssert(error == nil, "failed to query `Person` object with error '\(error!)")
                                                    XCTAssert(results.count == 1, "incorrect number of results")
                                                    waiter.signal()
                                                }
                                            }
                                        })
                                    }
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    
    waiter.wait()
    
}

