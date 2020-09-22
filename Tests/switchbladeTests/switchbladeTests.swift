import XCTest
@testable import Switchblade

final class switchbladeTests: XCTestCase {
    
    
    // SQLite
    func testSQLitePersist() {
        testPersistObject(initSQLiteDatabase())
    }
    
    static var allTests = [
        ("testSQLitePersist",testSQLitePersist),
    ]
}
