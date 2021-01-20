import XCTest
@testable import SwiftMP

final class MPZTests: XCTestCase {
    func testCreateMPZ() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = MPZ()
        a = 1
        let b: MPZ = 1
        XCTAssertEqual(a, b)

        a = MPZ(MPZ.mask)
        XCTAssertEqual(a, MPZ(MPZ.mask))

        a = 2.5e21
        let c = MPZ("2500000000000000000000")
        XCTAssertEqual(a, c)
    }

    func testBitWidth() {
        XCTAssertEqual(MPZ.zero.bitWidth, 1)
        XCTAssertEqual(MPZ(1).bitWidth, 2)
        XCTAssertEqual(MPZ(-1).bitWidth, 2)
        let a = MPZ(1 << 10)
        XCTAssertEqual(a.bitWidth, 12)
        let b = MPZ(1) << 63
        XCTAssertEqual(b, 1 << 63)
        XCTAssertEqual(b.bitWidth, 65)
        let c = MPZ(-1) << 63
        XCTAssertEqual(c, (-1) << 63)
        XCTAssertEqual(c.bitWidth, 65)
        XCTAssertEqual(0, (-1 << 64))
        XCTAssertEqual((MPZ(-1) << 64).bitWidth, 66)
    }

    func testConversion() {
        XCTAssertEqual(MPZ.isSigned, Int.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = MPZ(pA).signum()
        let sZZA = MPZ(zA).signum()
        let sNZA = MPZ(nA).signum()
        XCTAssertEqual(sPZA, MPZ(pA.signum()))
        XCTAssertEqual(sZZA, MPZ(zA.signum()))
        XCTAssertEqual(sNZA, MPZ(nA.signum()))
        XCTAssertEqual(Int(MPZ(-1024)), -1024)
        XCTAssertEqual(Int16(MPZ(-1024)), -1024)
        XCTAssertEqual(UInt(MPZ(1024)), 1024)
        XCTAssertEqual(UInt16(MPZ(1024)), 1024)
        XCTAssertEqual(MPZ(1).nonzeroBitCount, 1)
        XCTAssertEqual(MPZ(-1).nonzeroBitCount, 2)
        XCTAssertEqual(MPZ(255).nonzeroBitCount, 8)
        let n = -128
        let nZ = MPZ(n)
        XCTAssertEqual(nZ.bitWidth - nZ.nonzeroBitCount, n.bitWidth - n.nonzeroBitCount)
        let m = -255
        let mZ = MPZ(m)
        XCTAssertEqual(mZ.bitWidth - mZ.nonzeroBitCount, m.bitWidth - m.nonzeroBitCount)
    }

    func testExpressibleByStringLiteral() {
        let a: MPZ = "12345678901234567890"
        let b = MPZ("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = MPZ(stringLiteral: str)
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
        let a = MPZ(stringLiteral: str)
        let b = -a
        XCTAssertEqual(a.debugDescription, "MPZ(\"0x12345678901234567890\")")
        let description = b.debugDescription
        XCTAssertEqual(description, "MPZ(\"-0x12345678901234567890\")")
    }

    func testNegate() {
        let a: MPZ = 1
        let b = -a
        XCTAssertNotEqual(b, a)
        XCTAssertEqual(b, -1)

        let c: MPZ = "-12345678901234567890"
        let d = MPZ("12345678901234567890")
        XCTAssertNotEqual(c, d)
        XCTAssertEqual(c, -d)
    }

    func testCompare() {
        let a: MPZ = 1
        let b = -a
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: MPZ = "-12345678901234567890"
        let d = MPZ("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(MPZ(2) + MPZ(3), 5)
        XCTAssertEqual(MPZ(-2) + MPZ(3), 1)
        XCTAssertEqual(MPZ(2) + MPZ(-3), -1)
        XCTAssertEqual(MPZ(-2) + MPZ(-3), -5)
        let a = MPZ("12345678901234567890")
        let b = MPZ("-12345678901234567890")
        let c = a + b
        XCTAssertEqual(c, 0)
    }

    func testSub() {
        XCTAssertEqual(MPZ(2) - MPZ(3), -1)
        XCTAssertEqual(MPZ(-2) - MPZ(3), -5)
        XCTAssertEqual(MPZ(2) - MPZ(-3), 5)
        XCTAssertEqual(MPZ(-2) - MPZ(-3), 1)
        let a = MPZ("12345678901234567890")
        let b = MPZ("12345678901234567890")
        let c = a - b
        XCTAssertEqual(c, 0)
    }

    func testMul() {
        XCTAssertEqual(MPZ(153) * MPZ(131), MPZ(153 * 131))
        XCTAssertEqual(MPZ(-153) * MPZ(131), MPZ(-153 * 131))
        XCTAssertEqual(MPZ(153) * MPZ(-131), MPZ(153 * -131))
        XCTAssertEqual(MPZ(-153) * MPZ(-131), MPZ(-153 * -131))
    }

    func testDiv() {
        XCTAssertEqual(MPZ(153) / MPZ(131), MPZ(153 / 131))
        XCTAssertEqual(MPZ(-153) / MPZ(131), MPZ(-153 / 131))
        XCTAssertEqual(MPZ(153) / MPZ(-131), MPZ(153 / -131))
        XCTAssertEqual(MPZ(-153) / MPZ(-131), MPZ(-153 / -131))
    }

    func testMod() {
        XCTAssertEqual(MPZ(153) % MPZ(131), MPZ(153 % 131))
        XCTAssertEqual(MPZ(-153) % MPZ(131), MPZ(-153 % 131))
        XCTAssertEqual(MPZ(153) % MPZ(-131), MPZ(153 % -131))
        XCTAssertEqual(MPZ(-153) % MPZ(-131), MPZ(-153 % -131))
    }

    func testAnd() {
        XCTAssertEqual(MPZ(153) & MPZ(131), MPZ(153 & 131))
        XCTAssertEqual(MPZ(-153) & MPZ(131), MPZ(-153 & 131))
        XCTAssertEqual(MPZ(153) & MPZ(-131), MPZ(153 & -131))
        XCTAssertEqual(MPZ(-153) & MPZ(-131), MPZ(-153 & -131))
    }

    func testOr() {
        XCTAssertEqual(MPZ(153) | MPZ(131), MPZ(153 | 131))
        XCTAssertEqual(MPZ(-153) | MPZ(131), MPZ(-153 | 131))
        XCTAssertEqual(MPZ(153) | MPZ(-131), MPZ(153 | -131))
        XCTAssertEqual(MPZ(-153) | MPZ(-131), MPZ(-153 | -131))
    }

    func testXor() {
        XCTAssertEqual(MPZ(153) ^ MPZ(131), MPZ(153 ^ 131))
        XCTAssertEqual(MPZ(-153) ^ MPZ(131), MPZ(-153 ^ 131))
        XCTAssertEqual(MPZ(153) ^ MPZ(-131), MPZ(153 ^ -131))
        XCTAssertEqual(MPZ(-153) ^ MPZ(-131), MPZ(-153 ^ -131))
    }

    func testShiftLeft() {
        let a = -12345678
        let b = a << 10
        let x = MPZ(a)
        let z = x << 10
        XCTAssertEqual(z, MPZ(b))
    }

    func testShiftRight() {
        let a = -12345678
        let b = a >> 10
        let x = MPZ(a)
        let z = x >> 10
        XCTAssertEqual(z, MPZ(b))
    }

    func testBit() {
        var a = MPZ.zero
        a[1] = 1
        XCTAssertEqual(a, 2)
        a[128] = 1
        let b = (MPZ(1) << 128) + 2
        XCTAssertEqual(a, b)
    }

    func testMemory() {
        var a = MPZ.zero
        for i in 0..<1024 {
            let z = MPZ(1) << i
            a = a + z
        }
    }

    static var allTests = [
        ("testCreateMPZ", testCreateMPZ),
        ("testBitWidth", testBitWidth)
    ]
}
