import XCTest
@testable import SwiftMP

final class SwiftMPTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftMP().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
