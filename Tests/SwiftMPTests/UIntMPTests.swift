import XCTest
@testable import SwiftMP

final class UIntMPTests: XCTestCase {
    func testCreateUIntMP() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = UIntMP()
        a = 1
        let b: UIntMP = 1
        XCTAssertEqual(a, b)

        a = UIntMP(UIntMP.wordMask)
        XCTAssertEqual(a, UIntMP(UIntMP.wordMask))

        let c = UIntMP("25000")
        XCTAssertEqual(c, 25000)
    }

    func testBitWidth() {
        XCTAssertEqual(UIntMP.zero.bitWidth, 1)
        XCTAssertEqual(UIntMP(1).bitWidth, 1)
        let a = UIntMP(1 << 10)
        XCTAssertEqual(a.bitWidth, 11)
        let b = UIntMP(1) << 63
        XCTAssertEqual(b, 1 << 63)
        XCTAssertEqual(b.bitWidth, 64)
    }

    func testConversion() {
        XCTAssertEqual(UIntMP.isSigned, UInt.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = UIntMP(pA).signum()
        let sZZA = UIntMP(zA).signum()
        XCTAssertEqual(sPZA, UIntMP(pA.signum()))
        XCTAssertEqual(sZZA, UIntMP(zA.signum()))
        let t = UIntMP(truncatingIfNeeded: nA)
        let tMask = t.mask
        XCTAssertEqual(t, UIntMP(UInt(truncatingIfNeeded: nA)) & tMask)
        XCTAssertEqual(UInt(UIntMP(1024)), 1024)
        XCTAssertEqual(UInt16(UIntMP(1024)), 1024)
        XCTAssertEqual(UIntMP(1).nonzeroBitCount, UInt(1).nonzeroBitCount)
        XCTAssertEqual(UIntMP(truncatingIfNeeded: -1).nonzeroBitCount, 2)
        XCTAssertEqual(UIntMP(255).nonzeroBitCount, 8)
        let n = -128
        let nU = UIntMP(truncatingIfNeeded: n)
        let nu = UInt(truncatingIfNeeded: n)
        XCTAssertEqual(nU.bitWidth - nU.nonzeroBitCount,
                       nu.bitWidth - nu.nonzeroBitCount)
        let m = -255
        let mU = UIntMP(truncatingIfNeeded: m)
        let mu = UInt(truncatingIfNeeded: m)
        XCTAssertEqual(mU.bitWidth - mU.nonzeroBitCount, mu.bitWidth - mu.nonzeroBitCount)
    }

    func testExpressibleByStringLiteral() {
        let a: UIntMP = "12345678901234567890"
        let b = UIntMP("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = UIntMP(stringLiteral: str)
        XCTAssertEqual(a.description, str)
    }

    func testCustomDebugStringConvertible() {
        let str = "0x12345678901234567890"
        let a = UIntMP(stringLiteral: str)
        XCTAssertEqual(a.debugDescription, "0x12345678901234567890")
    }

    func testCompare() {
        let a: UIntMP = 1
        let b: UIntMP = 0
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: UIntMP = "0"
        let d = UIntMP("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(UIntMP(2) + UIntMP(3), 5)
        let a = UIntMP("12345678901234567890")
        let c = a + a
        XCTAssertEqual(c, a * 2)
    }

    /*
    func testSub() {
        let a = 2
        let b = 3
        XCTAssertThrowsError(MPU(a) - MPU(b))
        XCTAssertEqual(MPU(-a) - MPU(b), MPU(UInt(-a) - UInt(b)))
        XCTAssertEqual(MPU(a) - MPU(-b), MPU(UInt(a) - UInt(-b)))
        XCTAssertEqual(MPU(-a) - MPU(-b), MPU(UInt(-a) - UInt(-b)))
        let d = MPU("12345678901234567890")
        let e = MPU("12345678901234567890")
        let c = d - e
        XCTAssertEqual(c, 0)
    }
*/
    func testMul() {
        XCTAssertEqual(UIntMP(153) * UIntMP(131), UIntMP(153 * 131))
    }

    func testDiv() {
        XCTAssertEqual(UIntMP(153) / UIntMP(131), UIntMP(153 / 131))
    }

    func testMod() {
        XCTAssertEqual(UIntMP(153) % UIntMP(131), UIntMP(153 % 131))
    }

    func testAnd() {
        XCTAssertEqual(UIntMP(153) & UIntMP(131), UIntMP(UInt(153) & UInt(131)))
    }

    func testOr() {
        XCTAssertEqual(UIntMP(153) | UIntMP(131), UIntMP(UInt(153) | UInt(131)))
    }

    func testXor() {
        XCTAssertEqual(UIntMP(153) ^ UIntMP(131), UIntMP(UInt(153) ^ UInt(131)))
    }

    func testShiftLeft() {
        let a = 12345678
        let b = a << 10
        let x = UIntMP(a)
        let z = x << 10
        XCTAssertEqual(z, UIntMP(b))
    }

    func testShiftRight() {
        let a = 12345678
        let b = a >> 10
        let x = UIntMP(a)
        let z = x >> 10
        XCTAssertEqual(z, UIntMP(b))
    }

    func testBit() {
        var a = UIntMP.zero
        a[1] = 1
        XCTAssertEqual(a, 2)
        a[128] = 1
        let b = (UIntMP(1) << 128) + 2
        XCTAssertEqual(a, b)
    }

    func testMemory() {
        var a = UIntMP.zero
        for i in 0..<1024 {
            let z = UIntMP(1) << i
            a = a + z
        }
    }

    static var allTests = [
        ("testCreateUIntMP", testCreateUIntMP),
        ("testBitWidth", testBitWidth)
    ]
}
