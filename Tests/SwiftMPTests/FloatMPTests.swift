import XCTest
@testable import SwiftMP

final class FloatMPTests: XCTestCase {
    func testCreateFloatMP() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = FloatMP()
        a = 1
        let b: FloatMP = 1
        XCTAssertEqual(a, b)

        a = FloatMP(FloatMP.mask)
        XCTAssertEqual(a, FloatMP(FloatMP.mask))

        a = 2.5e21
        let c = FloatMP("2500000000000000000000")
        XCTAssertEqual(a, c)
    }

    func testConversion() {
        XCTAssertEqual(FloatMP.isSigned, Int.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = FloatMP(pA).signum()
        let sZZA = FloatMP(zA).signum()
        let sNZA = FloatMP(nA).signum()
        XCTAssertEqual(sPZA, FloatMP(pA.signum()))
        XCTAssertEqual(sZZA, FloatMP(zA.signum()))
        XCTAssertEqual(sNZA, FloatMP(nA.signum()))
    }

    func testPrecission() {
        let sbc = FloatMP.significandBitCount
        let z = (IntMP(-1) << (sbc-1))
        let u = UIntMP(truncatingIfNeeded: z)
        var f = FloatMP(z)
        XCTAssertEqual(u, f.significandBitPattern)
        let prec = 100
        f.significandWidth = prec
        XCTAssertEqual(FloatMP(z), f)
    }

    func testExpressibleByStringLiteral() {
        let a: FloatMP = "12345678901234567890"
        let b = FloatMP("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = FloatMP(str)!
        let b = -a
        XCTAssertEqual(FloatMP(a.description)!.description, a.description)
        XCTAssertEqual(FloatMP(b.description)!.description, b.description)
    }

    func testCustomDebugStringConvertible() {
        let str = "0x12345678901234567890"
        let a = FloatMP(stringLiteral: str)
        let b = -a
        XCTAssertEqual(FloatMP(a.debugDescription)!.debugDescription, a.debugDescription)
        XCTAssertEqual(FloatMP(b.debugDescription)!.debugDescription, b.debugDescription)
    }

    func testNegate() {
        let a: FloatMP = 1
        let b = -a
        XCTAssertNotEqual(b, a)
        XCTAssertEqual(b, -1)

        let c: FloatMP = "-12345678901234567890"
        let d = FloatMP("12345678901234567890")
        XCTAssertNotEqual(c, d)
        XCTAssertEqual(c, -d)
    }

    func testCompare() {
        let a: FloatMP = 1
        let b = -a
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: FloatMP = "-12345678901234567890"
        let d = FloatMP("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(FloatMP(2) + FloatMP(3), 5)
        XCTAssertEqual(FloatMP(-2) + FloatMP(3), 1)
        XCTAssertEqual(FloatMP(2) + FloatMP(-3), -1)
        XCTAssertEqual(FloatMP(-2) + FloatMP(-3), -5)
        let a = FloatMP("12345678901234567890")
        let b = FloatMP("-12345678901234567890")
        let c = a + b
        XCTAssertEqual(c, 0)
    }

    func testSub() {
        XCTAssertEqual(FloatMP(2) - FloatMP(3), -1)
        XCTAssertEqual(FloatMP(-2) - FloatMP(3), -5)
        XCTAssertEqual(FloatMP(2) - FloatMP(-3), 5)
        XCTAssertEqual(FloatMP(-2) - FloatMP(-3), 1)
        let a = FloatMP("12345678901234567890")
        let b = FloatMP("12345678901234567890")
        let c = a - b
        XCTAssertEqual(c, 0)
    }

    func testMul() {
        XCTAssertEqual(FloatMP(153) * FloatMP(131), FloatMP(153 * 131))
        XCTAssertEqual(FloatMP(-153) * FloatMP(131), FloatMP(-153 * 131))
        XCTAssertEqual(FloatMP(153) * FloatMP(-131), FloatMP(153 * -131))
        XCTAssertEqual(FloatMP(-153) * FloatMP(-131), FloatMP(-153 * -131))
    }

    func testDiv() {
        XCTAssertEqual(FloatMP(153) / FloatMP(131), FloatMP(153.0 / 131))
        XCTAssertEqual(FloatMP(-153) / FloatMP(131), FloatMP(-153.0 / 131))
        XCTAssertEqual(FloatMP(153) / FloatMP(-131), FloatMP(153.0 / -131))
        XCTAssertEqual(FloatMP(-153) / FloatMP(-131), FloatMP(-153.0 / -131))
    }

    func testShiftLeft() {
        let a = -12345678
        let b = a << 10
        let x = FloatMP(a)
        let z = x << 10
        XCTAssertEqual(z, FloatMP(b))
    }

    func testShiftRight() {
        let a = -12345678
        let x = FloatMP(a)
        let z = x >> 10
        XCTAssertEqual(z, FloatMP(a) / FloatMP(1 << 10))
    }

    func testMemory() {
        var a = FloatMP.zero
        for i in 0..<1024 {
            let z = FloatMP(1) << i
            a = a + z
        }
    }

    func testCos() {
        let c = FloatMP.cos(FloatMP.pi)
        XCTAssertEqual(c, -1)
        let p = FloatMP.acos(c)
        XCTAssertEqual(p, FloatMP.pi)
    }

    func testSin() {
        let s = FloatMP.sin(FloatMP.pi/2)
        XCTAssertEqual(s, 1)
        let p = FloatMP.asin(s)
        XCTAssertEqual(p, FloatMP.pi/2)
    }

    static var allTests = [
        ("testCreateFloatMP", testCreateFloatMP),
        ("testMemory", testMemory)
    ]
}
