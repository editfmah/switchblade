import XCTest
@testable import switchblade

final class switchbladeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(switchblade().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
