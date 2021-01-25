import XCTest
@testable import SwiftMP

final class MPQTests: XCTestCase {
    func testCreateMPQ() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = MPQ()
        a = 1
        let b: MPQ = 1
        XCTAssertEqual(a, b)

        a = MPQ(MPQ.mask)
        XCTAssertEqual(a, MPQ(MPQ.mask))

        a = 2.5e21
        let c = MPQ("2500000000000000000000")
        XCTAssertEqual(a, c)
    }

    func testConversion() {
        XCTAssertEqual(MPQ.isSigned, Int.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = MPQ(pA).signum()
        let sZZA = MPQ(zA).signum()
        let sNZA = MPQ(nA).signum()
        XCTAssertEqual(sPZA, MPQ(pA.signum()))
        XCTAssertEqual(sZZA, MPQ(zA.signum()))
        XCTAssertEqual(sNZA, MPQ(nA.signum()))
    }

    func testExpressibleByStringLiteral() {
        let a: MPQ = "12345678901234567890"
        let b = MPQ("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = MPQ(stringLiteral: str)
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
        let a = MPQ(stringLiteral: str)
        let b = -a
        XCTAssertEqual(MPQ(a.debugDescription)!.debugDescription, a.debugDescription)
        XCTAssertEqual(MPQ(b.debugDescription)!.debugDescription, b.debugDescription)
    }

    func testNegate() {
        let a: MPQ = 1
        let b = -a
        XCTAssertNotEqual(b, a)
        XCTAssertEqual(b, -1)

        let c: MPQ = "-12345678901234567890"
        let d = MPQ("12345678901234567890")
        XCTAssertNotEqual(c, d)
        XCTAssertEqual(c, -d)
    }

    func testCompare() {
        let a: MPQ = 1
        let b = -a
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: MPQ = "-12345678901234567890"
        let d = MPQ("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(MPQ(2) + MPQ(3), 5)
        XCTAssertEqual(MPQ(-2) + MPQ(3), 1)
        XCTAssertEqual(MPQ(2) + MPQ(-3), -1)
        XCTAssertEqual(MPQ(-2) + MPQ(-3), -5)
        let a = MPQ("12345678901234567890")
        let b = MPQ("-12345678901234567890")
        let c = a + b
        XCTAssertEqual(c, 0)
    }

    func testSub() {
        XCTAssertEqual(MPQ(2) - MPQ(3), -1)
        XCTAssertEqual(MPQ(-2) - MPQ(3), -5)
        XCTAssertEqual(MPQ(2) - MPQ(-3), 5)
        XCTAssertEqual(MPQ(-2) - MPQ(-3), 1)
        let a = MPQ("12345678901234567890")
        let b = MPQ("12345678901234567890")
        let c = a - b
        XCTAssertEqual(c, 0)
    }

    func testMul() {
        XCTAssertEqual(MPQ(153) * MPQ(131), MPQ(153 * 131))
        XCTAssertEqual(MPQ(-153) * MPQ(131), MPQ(-153 * 131))
        XCTAssertEqual(MPQ(153) * MPQ(-131), MPQ(153 * -131))
        XCTAssertEqual(MPQ(-153) * MPQ(-131), MPQ(-153 * -131))
    }

    func testDiv() {
        XCTAssertEqual(MPQ(153) / MPQ(131), MPQ(num: 153, den: 131))
        XCTAssertEqual(MPQ(-153) / MPQ(131), MPQ(num: -153, den: 131))
        XCTAssertEqual(MPQ(153) / MPQ(-131), MPQ(num: 153, den: -131))
        XCTAssertEqual(MPQ(-153) / MPQ(-131), MPQ(num: -153, den: -131))
    }

    func testShiftLeft() {
        let a = -12345678
        let b = a << 10
        let x = MPQ(a)
        let z = x << 10
        XCTAssertEqual(z, MPQ(b))
    }

    func testShiftRight() {
        let a = -12345678
        let x = MPQ(a)
        let z = x >> 10
        XCTAssertEqual(z, MPQ(num: a, den: 1 << 10))
    }

    func testMemory() {
        var a = MPQ.zero
        for i in 0..<1024 {
            let z = MPQ(num: 1, den: 1) << i
            a = a + z
        }
    }

    static var allTests = [
        ("testCreateMPQ", testCreateMPQ),
        ("testMemory", testMemory)
    ]
}
