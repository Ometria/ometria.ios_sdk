import XCTest
@testable import Ometria

final class OmetriaTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ometria_sdk_ios().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
