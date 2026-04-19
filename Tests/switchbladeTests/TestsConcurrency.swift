//
//  TestsConcurrency.swift
//  SwitchbladeTests
//
//  Stress tests covering multi-threaded use of the SQLite-backed providers.
//  These are designed to surface the SQLITE_MISUSE class of bugs that occur
//  when statement preparation/stepping/finalization is not properly serialized
//  against other threads using the same connection.
//

import Foundation
import XCTest
@testable import Switchblade

fileprivate func makeSQLite() -> Switchblade {
    let path = FileManager.default.currentDirectoryPath
    let id = UUID().uuidString
    return Switchblade(provider: SQLiteProvider(path: "\(path)/\(id).db"), configuration: nil) { _, _, _ in }
}

fileprivate func makeShard() -> Switchblade {
    let path = FileManager.default.currentDirectoryPath
    let id = UUID().uuidString
    return Switchblade(provider: SQLiteShardProvider(path: "\(path)/\(id)"), configuration: nil) { _, _, _ in }
}

extension switchbladeTests {

    func testConcurrentSQLiteReadsAndWrites() {
        let db = makeSQLite()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "sb.test.sqlite", attributes: .concurrent)
        let writers = 8
        let opsPerWorker = 100

        for w in 0..<writers {
            group.enter()
            queue.async {
                for i in 0..<opsPerWorker {
                    let p = Person()
                    p.Name = "W\(w)-\(i)"
                    p.Age = i
                    _ = db.put(p)
                    if i % 5 == 0 {
                        let _: [Person] = db.all(keyspace: "person")
                    }
                    if i % 7 == 0 {
                        let _: Person? = db.get(key: p.PersonId)
                    }
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success, "Concurrent SQLite workload timed out")

        // Sanity: verify all writes landed.
        let all: [Person] = db.all(keyspace: "person")
        XCTAssertEqual(all.count, writers * opsPerWorker)
    }

    func testConcurrentSQLiteIterateAndWrite() {
        // Iteration must hold the connection lock so concurrent writers don't
        // collide with prepare/step/finalize on the same handle.
        let db = makeSQLite()

        // Seed.
        for i in 0..<200 {
            let p = Person()
            p.Name = "Seed-\(i)"
            p.Age = i
            _ = db.put(p)
        }

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "sb.test.sqlite.iter", attributes: .concurrent)

        for _ in 0..<4 {
            group.enter()
            queue.async {
                for _ in 0..<25 {
                    db.iterate(keyspace: "person") { (_: Person) in
                        // no-op
                    }
                }
                group.leave()
            }
        }

        for w in 0..<4 {
            group.enter()
            queue.async {
                for i in 0..<100 {
                    let p = Person()
                    p.Name = "Hot-\(w)-\(i)"
                    p.Age = i
                    _ = db.put(p)
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success, "Concurrent iterate+write workload timed out")
    }

    func testConcurrentShardWritesAcrossKeyspaces() {
        // Per-shard locks should permit writes against different (partition,
        // keyspace) shards to proceed truly in parallel.
        let db = makeShard()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "sb.test.shard", attributes: .concurrent)
        let shardCount = 8
        let opsPerShard = 100

        for s in 0..<shardCount {
            group.enter()
            queue.async {
                // Use distinct partitions to land on distinct shards. (Person's
                // KeyspaceIdentifiable conformance fixes the keyspace, so we
                // distinguish shards via the partition instead.)
                let part = "part-\(s)"
                for i in 0..<opsPerShard {
                    let p = Person()
                    p.Name = "S\(s)-\(i)"
                    p.Age = i
                    _ = db.put(partition: part, p)
                }
                let all: [Person] = db.all(partition: part, keyspace: "person")
                XCTAssertEqual(all.count, opsPerShard)
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success, "Concurrent shard workload timed out")
    }

    func testConcurrentShardWritesSameShard() {
        // Multiple writers hitting the same shard should be serialized by the
        // shard's own lock without crashing or losing writes.
        let db = makeShard()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "sb.test.shard.same", attributes: .concurrent)
        let writers = 8
        let opsPerWorker = 100

        for w in 0..<writers {
            group.enter()
            queue.async {
                for i in 0..<opsPerWorker {
                    let p = Person()
                    p.Name = "W\(w)-\(i)"
                    p.Age = i
                    _ = db.put(p)
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 30)
        XCTAssertEqual(result, .success, "Same-shard concurrent workload timed out")

        let all: [Person] = db.all(keyspace: "person")
        XCTAssertEqual(all.count, writers * opsPerWorker)
    }

    func testConcurrentAtomicPerformAndWrites() {
        // perform() must serialize against ad-hoc writes from other threads —
        // otherwise BEGIN/COMMIT can interleave with their statements and
        // produce SQLITE_MISUSE.
        let db = makeSQLite()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "sb.test.sqlite.atomic", attributes: .concurrent)

        for t in 0..<4 {
            group.enter()
            queue.async {
                for batch in 0..<10 {
                    db.perform {
                        for i in 0..<25 {
                            let p = Person()
                            p.Name = "T\(t)-B\(batch)-\(i)"
                            p.Age = i
                            _ = db.put(p)
                        }
                    }
                }
                group.leave()
            }
        }

        for w in 0..<4 {
            group.enter()
            queue.async {
                for i in 0..<200 {
                    let p = Person()
                    p.Name = "Loose-\(w)-\(i)"
                    p.Age = i
                    _ = db.put(p)
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 60)
        XCTAssertEqual(result, .success, "Concurrent perform+write workload timed out")

        let all: [Person] = db.all(keyspace: "person")
        // 4 perform threads * 10 batches * 25 + 4 loose threads * 200
        XCTAssertEqual(all.count, 4 * 10 * 25 + 4 * 200)
    }

}
