import XCTest
@testable import Switchblade

final class switchbladeTests: XCTestCase {
    
    static var allTests = [
        ("testPersistObject",testPersistObject),
        ("testPersistQueryObject",testPersistQueryObject),
        ("testPersistMultipleObjectsAndCheckAll", testPersistMultipleObjectsAndCheckAll),
        ("testPersistMultipleObjectsAndFilterAll",testPersistMultipleObjectsAndFilterAll),
        ("testPersistMultipleObjectsAndQuery",testPersistMultipleObjectsAndQuery),
        ("testPersistMultipleObjectsAndQueryMultipleParams", testPersistMultipleObjectsAndQueryMultipleParams),
        ("testPersistMultipleObjectsAndCheckAllClosure", testPersistMultipleObjectsAndCheckAllClosure)
    ]
}
