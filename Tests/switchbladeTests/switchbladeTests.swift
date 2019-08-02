import XCTest
@testable import Switchblade

final class switchbladeTests: XCTestCase {
    
    
    // SQLite
    func testSQLitePersist() {
        testPersist(initSQLiteDatabase())
    }
    func testSQLiteQuery() {
        testQuery(initSQLiteDatabase())
    }
    func testSQLiteQueryAsync() {
        testQueryAsync(initSQLiteDatabase())
    }
    func testSQLiteDeleteAsync() {
        testDeleteAsync(initSQLiteDatabase())
    }
    func testSQLiteUpdateAsync() {
        testUpdateAsync(initSQLiteDatabase())
    }
    func testSQLitePersistAsync() {
        testPersistAsync(initSQLiteDatabase())
    }
    func testSQLiteQueryActions() {
        testQueryActionsAsync(initSQLiteDatabase())
    }
    func testSQLiteCRUD() {
        testCRUDAsync(initSQLiteDatabase())
    }
    
    // Cassandra
    func testCassandraPersist() {
            testPersist(initCassandraDatabase())
    }
    func testCassandraQuery() {
            testQuery(initCassandraDatabase())
    }
    func testCassandraQueryAsync() {
            testQueryAsync(initCassandraDatabase())
    }
    func testCassandraDeleteAsync() {
            testDeleteAsync(initCassandraDatabase())
    }
    func testCassandraUpdateAsync() {
            testUpdateAsync(initCassandraDatabase())
    }
    func testCassandraPersistAsync() {
        testPersistAsync(initCassandraDatabase())
    }
    func testCassandraQueryActions() {
        testQueryActionsAsync(initCassandraDatabase())
    }
    func testCassandraCRUD() {
        testCRUDAsync(initCassandraDatabase())
    }
    
    static var allTests = [
        ("testSQLitePersist",testSQLitePersist),
        ("testSQLiteQuery",testSQLiteQuery),
        ("testSQLiteQueryAsync",testSQLiteQueryAsync),
        ("testSQLiteUpdateAsync",testSQLiteUpdateAsync),
        ("testCassandraPersist",testCassandraPersist),
        ("testCassandraQuery",testCassandraQuery),
        ("testCassandraQueryAsync",testCassandraQueryAsync),
        ("testCassandraDeleteAsync",testCassandraDeleteAsync),
        ("testCassandraUpdateAsync",testCassandraUpdateAsync),
        ("testCassandraPersistAsync",testCassandraPersistAsync),
        ("testSQLitePersistAsync",testSQLitePersistAsync),
        ("testCassandraQueryActions",testCassandraQueryActions),
        ("testSQLiteQueryActions",testSQLiteQueryActions),
        ("testSQLiteCRUD",testSQLiteCRUD),
        ("testCassandraCRUD",testCassandraCRUD)
    ]
}
