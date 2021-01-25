import XCTest
@testable import SwiftMP

final class MPFRTests: XCTestCase {
    func testCreateMPFR() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = MPFR()
        a = 1
        let b: MPFR = 1
        XCTAssertEqual(a, b)

        a = MPFR(MPFR.mask)
        XCTAssertEqual(a, MPFR(MPFR.mask))

        a = 2.5e21
        let c = MPFR("2500000000000000000000")
        XCTAssertEqual(a, c)
    }

    func testConversion() {
        XCTAssertEqual(MPFR.isSigned, Int.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = MPFR(pA).signum()
        let sZZA = MPFR(zA).signum()
        let sNZA = MPFR(nA).signum()
        XCTAssertEqual(sPZA, MPFR(pA.signum()))
        XCTAssertEqual(sZZA, MPFR(zA.signum()))
        XCTAssertEqual(sNZA, MPFR(nA.signum()))
    }

    func testPrecission() {
        let sbc = MPFR.significandBitCount
        let z = (MPZ(-1) << (sbc-1))
        let u = MPU(truncatingIfNeeded: z)
        var f = MPFR(z)
        XCTAssertEqual(u, f.significandBitPattern)
        let prec = 100
        f.significandWidth = prec
        XCTAssertEqual(MPFR(z), f)
    }

    func testExpressibleByStringLiteral() {
        let a: MPFR = "12345678901234567890"
        let b = MPFR("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = MPFR(str)!
        let b = -a
        XCTAssertEqual(MPFR(a.description)!.description, a.description)
        XCTAssertEqual(MPFR(b.description)!.description, b.description)
    }

    func testCustomDebugStringConvertible() {
        let str = "0x12345678901234567890"
        let a = MPFR(stringLiteral: str)
        let b = -a
        XCTAssertEqual(MPFR(a.debugDescription)!.debugDescription, a.debugDescription)
        XCTAssertEqual(MPFR(b.debugDescription)!.debugDescription, b.debugDescription)
    }

    func testNegate() {
        let a: MPFR = 1
        let b = -a
        XCTAssertNotEqual(b, a)
        XCTAssertEqual(b, -1)

        let c: MPFR = "-12345678901234567890"
        let d = MPFR("12345678901234567890")
        XCTAssertNotEqual(c, d)
        XCTAssertEqual(c, -d)
    }

    func testCompare() {
        let a: MPFR = 1
        let b = -a
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: MPFR = "-12345678901234567890"
        let d = MPFR("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(MPFR(2) + MPFR(3), 5)
        XCTAssertEqual(MPFR(-2) + MPFR(3), 1)
        XCTAssertEqual(MPFR(2) + MPFR(-3), -1)
        XCTAssertEqual(MPFR(-2) + MPFR(-3), -5)
        let a = MPFR("12345678901234567890")
        let b = MPFR("-12345678901234567890")
        let c = a + b
        XCTAssertEqual(c, 0)
    }

    func testSub() {
        XCTAssertEqual(MPFR(2) - MPFR(3), -1)
        XCTAssertEqual(MPFR(-2) - MPFR(3), -5)
        XCTAssertEqual(MPFR(2) - MPFR(-3), 5)
        XCTAssertEqual(MPFR(-2) - MPFR(-3), 1)
        let a = MPFR("12345678901234567890")
        let b = MPFR("12345678901234567890")
        let c = a - b
        XCTAssertEqual(c, 0)
    }

    func testMul() {
        XCTAssertEqual(MPFR(153) * MPFR(131), MPFR(153 * 131))
        XCTAssertEqual(MPFR(-153) * MPFR(131), MPFR(-153 * 131))
        XCTAssertEqual(MPFR(153) * MPFR(-131), MPFR(153 * -131))
        XCTAssertEqual(MPFR(-153) * MPFR(-131), MPFR(-153 * -131))
    }

    func testDiv() {
        XCTAssertEqual(MPFR(153) / MPFR(131), MPFR(153.0 / 131))
        XCTAssertEqual(MPFR(-153) / MPFR(131), MPFR(-153.0 / 131))
        XCTAssertEqual(MPFR(153) / MPFR(-131), MPFR(153.0 / -131))
        XCTAssertEqual(MPFR(-153) / MPFR(-131), MPFR(-153.0 / -131))
    }

    func testShiftLeft() {
        let a = -12345678
        let b = a << 10
        let x = MPFR(a)
        let z = x << 10
        XCTAssertEqual(z, MPFR(b))
    }

    func testShiftRight() {
        let a = -12345678
        let x = MPFR(a)
        let z = x >> 10
        XCTAssertEqual(z, MPFR(a) / MPFR(1 << 10))
    }

    func testMemory() {
        var a = MPFR.zero
        for i in 0..<1024 {
            let z = MPFR(1) << i
            a = a + z
        }
    }

    func testCos() {
        let c = MPFR.cos(MPFR.pi)
        XCTAssertEqual(c, -1)
        let p = MPFR.acos(c)
        XCTAssertEqual(p, MPFR.pi)
    }

    func testSin() {
        let s = MPFR.sin(MPFR.pi/2)
        XCTAssertEqual(s, 1)
        let p = MPFR.asin(s)
        XCTAssertEqual(p, MPFR.pi/2)
    }

    static var allTests = [
        ("testCreateMPFR", testCreateMPFR),
        ("testMemory", testMemory)
    ]
}
