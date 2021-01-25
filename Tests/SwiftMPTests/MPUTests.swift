import XCTest
@testable import SwiftMP

final class MPUTests: XCTestCase {
    func testCreateMPU() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = MPU()
        a = 1
        let b: MPU = 1
        XCTAssertEqual(a, b)

        a = MPU(MPU.wordMask)
        XCTAssertEqual(a, MPU(MPU.wordMask))

        let c = MPU("25000")
        XCTAssertEqual(c, 25000)
    }

    func testBitWidth() {
        XCTAssertEqual(MPU.zero.bitWidth, 1)
        XCTAssertEqual(MPU(1).bitWidth, 1)
        let a = MPU(1 << 10)
        XCTAssertEqual(a.bitWidth, 11)
        let b = MPU(1) << 63
        XCTAssertEqual(b, 1 << 63)
        XCTAssertEqual(b.bitWidth, 64)
    }

    func testConversion() {
        XCTAssertEqual(MPU.isSigned, UInt.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = MPU(pA).signum()
        let sZZA = MPU(zA).signum()
        XCTAssertEqual(sPZA, MPU(pA.signum()))
        XCTAssertEqual(sZZA, MPU(zA.signum()))
        let t = MPU(truncatingIfNeeded: nA)
        let tMask = t.mask
        XCTAssertEqual(t, MPU(UInt(truncatingIfNeeded: nA)) & tMask)
        XCTAssertEqual(UInt(MPU(1024)), 1024)
        XCTAssertEqual(UInt16(MPU(1024)), 1024)
        XCTAssertEqual(MPU(1).nonzeroBitCount, UInt(1).nonzeroBitCount)
        XCTAssertEqual(MPU(truncatingIfNeeded: -1).nonzeroBitCount, 2)
        XCTAssertEqual(MPU(255).nonzeroBitCount, 8)
        let n = -128
        let nU = MPU(truncatingIfNeeded: n)
        let nu = UInt(truncatingIfNeeded: n)
        XCTAssertEqual(nU.bitWidth - nU.nonzeroBitCount,
                       nu.bitWidth - nu.nonzeroBitCount)
        let m = -255
        let mU = MPU(truncatingIfNeeded: m)
        let mu = UInt(truncatingIfNeeded: m)
        XCTAssertEqual(mU.bitWidth - mU.nonzeroBitCount, mu.bitWidth - mu.nonzeroBitCount)
    }

    func testExpressibleByStringLiteral() {
        let a: MPU = "12345678901234567890"
        let b = MPU("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = MPU(stringLiteral: str)
        XCTAssertEqual(a.description, str)
    }

    func testCustomDebugStringConvertible() {
        let str = "0x12345678901234567890"
        let a = MPU(stringLiteral: str)
        XCTAssertEqual(a.debugDescription, "0x12345678901234567890")
    }

    func testCompare() {
        let a: MPU = 1
        let b: MPU = 0
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: MPU = "0"
        let d = MPU("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(MPU(2) + MPU(3), 5)
        let a = MPU("12345678901234567890")
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
        XCTAssertEqual(MPU(153) * MPU(131), MPU(153 * 131))
    }

    func testDiv() {
        XCTAssertEqual(MPU(153) / MPU(131), MPU(153 / 131))
    }

    func testMod() {
        XCTAssertEqual(MPU(153) % MPU(131), MPU(153 % 131))
    }

    func testAnd() {
        XCTAssertEqual(MPU(153) & MPU(131), MPU(UInt(153) & UInt(131)))
    }

    func testOr() {
        XCTAssertEqual(MPU(153) | MPU(131), MPU(UInt(153) | UInt(131)))
    }

    func testXor() {
        XCTAssertEqual(MPU(153) ^ MPU(131), MPU(UInt(153) ^ UInt(131)))
    }

    func testShiftLeft() {
        let a = 12345678
        let b = a << 10
        let x = MPU(a)
        let z = x << 10
        XCTAssertEqual(z, MPU(b))
    }

    func testShiftRight() {
        let a = 12345678
        let b = a >> 10
        let x = MPU(a)
        let z = x >> 10
        XCTAssertEqual(z, MPU(b))
    }

    func testBit() {
        var a = MPU.zero
        a[1] = 1
        XCTAssertEqual(a, 2)
        a[128] = 1
        let b = (MPU(1) << 128) + 2
        XCTAssertEqual(a, b)
    }

    func testMemory() {
        var a = MPU.zero
        for i in 0..<1024 {
            let z = MPU(1) << i
            a = a + z
        }
    }

    static var allTests = [
        ("testCreateMPU", testCreateMPU),
        ("testBitWidth", testBitWidth)
    ]
}
