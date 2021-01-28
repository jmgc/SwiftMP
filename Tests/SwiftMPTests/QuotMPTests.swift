import XCTest
@testable import SwiftMP

final class QuotMPTests: XCTestCase {
    func testCreateQuotMP() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = QuotMP()
        a = 1
        let b: QuotMP = 1
        XCTAssertEqual(a, b)

        a = QuotMP(QuotMP.mask)
        XCTAssertEqual(a, QuotMP(QuotMP.mask))

        a = 2.5e21
        let c = QuotMP("2500000000000000000000")
        XCTAssertEqual(a, c)
    }

    func testConversion() {
        XCTAssertEqual(QuotMP.isSigned, Int.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = QuotMP(pA).signum()
        let sZZA = QuotMP(zA).signum()
        let sNZA = QuotMP(nA).signum()
        XCTAssertEqual(sPZA, QuotMP(pA.signum()))
        XCTAssertEqual(sZZA, QuotMP(zA.signum()))
        XCTAssertEqual(sNZA, QuotMP(nA.signum()))
    }

    func testExpressibleByStringLiteral() {
        let a: QuotMP = "12345678901234567890"
        let b = QuotMP("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = QuotMP(stringLiteral: str)
        let b = -a
        XCTAssertEqual(a.description, str)
        let description = b.description
        var idx = description.startIndex
        XCTAssertEqual(description[idx], "-")
        idx = description.utf8.index(after: idx)
        XCTAssertEqual(String(description.utf8[idx...]), str)
    }

    func testCustomDebugStringConvertible() {
        let str = "0x12345678901234567890"
        let a = QuotMP(stringLiteral: str)
        let b = -a
        XCTAssertEqual(QuotMP(a.debugDescription)!.debugDescription, a.debugDescription)
        XCTAssertEqual(QuotMP(b.debugDescription)!.debugDescription, b.debugDescription)
    }

    func testNegate() {
        let a: QuotMP = 1
        let b = -a
        XCTAssertNotEqual(b, a)
        XCTAssertEqual(b, -1)

        let c: QuotMP = "-12345678901234567890"
        let d = QuotMP("12345678901234567890")
        XCTAssertNotEqual(c, d)
        XCTAssertEqual(c, -d)
    }

    func testCompare() {
        let a: QuotMP = 1
        let b = -a
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: QuotMP = "-12345678901234567890"
        let d = QuotMP("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(QuotMP(2) + QuotMP(3), 5)
        XCTAssertEqual(QuotMP(-2) + QuotMP(3), 1)
        XCTAssertEqual(QuotMP(2) + QuotMP(-3), -1)
        XCTAssertEqual(QuotMP(-2) + QuotMP(-3), -5)
        let a = QuotMP("12345678901234567890")
        let b = QuotMP("-12345678901234567890")
        let c = a + b
        XCTAssertEqual(c, 0)
    }

    func testSub() {
        XCTAssertEqual(QuotMP(2) - QuotMP(3), -1)
        XCTAssertEqual(QuotMP(-2) - QuotMP(3), -5)
        XCTAssertEqual(QuotMP(2) - QuotMP(-3), 5)
        XCTAssertEqual(QuotMP(-2) - QuotMP(-3), 1)
        let a = QuotMP("12345678901234567890")
        let b = QuotMP("12345678901234567890")
        let c = a - b
        XCTAssertEqual(c, 0)
    }

    func testMul() {
        XCTAssertEqual(QuotMP(153) * QuotMP(131), QuotMP(153 * 131))
        XCTAssertEqual(QuotMP(-153) * QuotMP(131), QuotMP(-153 * 131))
        XCTAssertEqual(QuotMP(153) * QuotMP(-131), QuotMP(153 * -131))
        XCTAssertEqual(QuotMP(-153) * QuotMP(-131), QuotMP(-153 * -131))
    }

    func testDiv() {
        XCTAssertEqual(QuotMP(153) / QuotMP(131), QuotMP(num: 153, den: 131))
        XCTAssertEqual(QuotMP(-153) / QuotMP(131), QuotMP(num: -153, den: 131))
        XCTAssertEqual(QuotMP(153) / QuotMP(-131), QuotMP(num: 153, den: -131))
        XCTAssertEqual(QuotMP(-153) / QuotMP(-131), QuotMP(num: -153, den: -131))
    }

    func testShiftLeft() {
        let a = -12345678
        let b = a << 10
        let x = QuotMP(a)
        let z = x << 10
        XCTAssertEqual(z, QuotMP(b))
    }

    func testShiftRight() {
        let a = -12345678
        let x = QuotMP(a)
        let z = x >> 10
        XCTAssertEqual(z, QuotMP(num: a, den: 1 << 10))
    }

    func testMemory() {
        var a = QuotMP.zero
        for i in 0..<1024 {
            let z = QuotMP(num: 1, den: 1) << i
            a = a + z
        }
    }

    static var allTests = [
        ("testCreateQuotMP", testCreateQuotMP),
        ("testMemory", testMemory)
    ]
}
