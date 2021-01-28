import XCTest
@testable import SwiftMP

final class IntMPTests: XCTestCase {
    func testCreateIntMP() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var a = IntMP()
        a = 1
        let b: IntMP = 1
        XCTAssertEqual(a, b)

        a = IntMP(IntMP.wordMask)
        XCTAssertEqual(a, IntMP(IntMP.wordMask))

        a = 2.5e21
        let c = IntMP("2500000000000000000000")
        XCTAssertEqual(a, c)
    }

    func testBitWidth() {
        XCTAssertEqual(IntMP.zero.bitWidth, 1)
        XCTAssertEqual(IntMP(1).bitWidth, 2)
        XCTAssertEqual(IntMP(-1).bitWidth, 2)
        let a = IntMP(1 << 10)
        XCTAssertEqual(a.bitWidth, 12)
        let b = IntMP(1) << 63
        XCTAssertEqual(b, 1 << 63)
        XCTAssertEqual(b.bitWidth, 65)
        let c = IntMP(-1) << 63
        XCTAssertEqual(c, (-1) << 63)
        XCTAssertEqual(c.bitWidth, 65)
        XCTAssertEqual(0, (-1 << 64))
        XCTAssertEqual((IntMP(-1) << 64).bitWidth, 66)
    }

    func testConversion() {
        XCTAssertEqual(IntMP.isSigned, Int.isSigned)
        let pA = 10
        let zA = 0
        let nA = -10
        let sPZA = IntMP(pA).signum()
        let sZZA = IntMP(zA).signum()
        let sNZA = IntMP(nA).signum()
        XCTAssertEqual(sPZA, IntMP(pA.signum()))
        XCTAssertEqual(sZZA, IntMP(zA.signum()))
        XCTAssertEqual(sNZA, IntMP(nA.signum()))
        XCTAssertEqual(Int(IntMP(-1024)), -1024)
        XCTAssertEqual(Int16(IntMP(-1024)), -1024)
        XCTAssertEqual(UInt(IntMP(1024)), 1024)
        XCTAssertEqual(UInt16(IntMP(1024)), 1024)
        XCTAssertEqual(IntMP(1).nonzeroBitCount, 1)
        XCTAssertEqual(IntMP(-1).nonzeroBitCount, 2)
        XCTAssertEqual(IntMP(255).nonzeroBitCount, 8)
        let n = -128
        let nZ = IntMP(n)
        XCTAssertEqual(nZ.bitWidth - nZ.nonzeroBitCount, n.bitWidth - n.nonzeroBitCount)
        let m = -255
        let mZ = IntMP(m)
        XCTAssertEqual(mZ.bitWidth - mZ.nonzeroBitCount, m.bitWidth - m.nonzeroBitCount)
    }

    func testExpressibleByStringLiteral() {
        let a: IntMP = "12345678901234567890"
        let b = IntMP("12345678901234567890")
        XCTAssertEqual(a, b)
    }

    func testCustomStringConvertible() {
        let str = "12345678901234567890"
        let a = IntMP(stringLiteral: str)
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
        let a = IntMP(stringLiteral: str)
        let b = -a
        XCTAssertEqual(a.debugDescription, "0x12345678901234567890")
        let description = b.debugDescription
        XCTAssertEqual(description, "-0x12345678901234567890")
    }

    func testNegate() {
        let a: IntMP = 1
        let b = -a
        XCTAssertNotEqual(b, a)
        XCTAssertEqual(b, -1)

        let c: IntMP = "-12345678901234567890"
        let d = IntMP("12345678901234567890")
        XCTAssertNotEqual(c, d)
        XCTAssertEqual(c, -d)
    }

    func testCompare() {
        let a: IntMP = 1
        let b = -a
        XCTAssertLessThan(b, a)
        XCTAssertGreaterThan(a, b)
        XCTAssertNotEqual(b, a)

        let c: IntMP = "-12345678901234567890"
        let d = IntMP("12345678901234567890")
        XCTAssertLessThan(c, d)
        XCTAssertGreaterThan(d, c)
        XCTAssertNotEqual(c, d)
    }

    func testAdd() {
        XCTAssertEqual(IntMP(2) + IntMP(3), 5)
        XCTAssertEqual(IntMP(-2) + IntMP(3), 1)
        XCTAssertEqual(IntMP(2) + IntMP(-3), -1)
        XCTAssertEqual(IntMP(-2) + IntMP(-3), -5)
        let a = IntMP("12345678901234567890")
        let b = IntMP("-12345678901234567890")
        let c = a + b
        XCTAssertEqual(c, 0)
    }

    func testSub() {
        XCTAssertEqual(IntMP(2) - IntMP(3), -1)
        XCTAssertEqual(IntMP(-2) - IntMP(3), -5)
        XCTAssertEqual(IntMP(2) - IntMP(-3), 5)
        XCTAssertEqual(IntMP(-2) - IntMP(-3), 1)
        let a = IntMP("12345678901234567890")
        let b = IntMP("12345678901234567890")
        let c = a - b
        XCTAssertEqual(c, 0)
    }

    func testMul() {
        XCTAssertEqual(IntMP(153) * IntMP(131), IntMP(153 * 131))
        XCTAssertEqual(IntMP(-153) * IntMP(131), IntMP(-153 * 131))
        XCTAssertEqual(IntMP(153) * IntMP(-131), IntMP(153 * -131))
        XCTAssertEqual(IntMP(-153) * IntMP(-131), IntMP(-153 * -131))
    }

    func testDiv() {
        XCTAssertEqual(IntMP(153) / IntMP(131), IntMP(153 / 131))
        XCTAssertEqual(IntMP(-153) / IntMP(131), IntMP(-153 / 131))
        XCTAssertEqual(IntMP(153) / IntMP(-131), IntMP(153 / -131))
        XCTAssertEqual(IntMP(-153) / IntMP(-131), IntMP(-153 / -131))
    }

    func testMod() {
        XCTAssertEqual(IntMP(153) % IntMP(131), IntMP(153 % 131))
        XCTAssertEqual(IntMP(-153) % IntMP(131), IntMP(-153 % 131))
        XCTAssertEqual(IntMP(153) % IntMP(-131), IntMP(153 % -131))
        XCTAssertEqual(IntMP(-153) % IntMP(-131), IntMP(-153 % -131))
    }

    func testAnd() {
        XCTAssertEqual(IntMP(153) & IntMP(131), IntMP(153 & 131))
        XCTAssertEqual(IntMP(-153) & IntMP(131), IntMP(-153 & 131))
        XCTAssertEqual(IntMP(153) & IntMP(-131), IntMP(153 & -131))
        XCTAssertEqual(IntMP(-153) & IntMP(-131), IntMP(-153 & -131))
    }

    func testOr() {
        XCTAssertEqual(IntMP(153) | IntMP(131), IntMP(153 | 131))
        XCTAssertEqual(IntMP(-153) | IntMP(131), IntMP(-153 | 131))
        XCTAssertEqual(IntMP(153) | IntMP(-131), IntMP(153 | -131))
        XCTAssertEqual(IntMP(-153) | IntMP(-131), IntMP(-153 | -131))
    }

    func testXor() {
        XCTAssertEqual(IntMP(153) ^ IntMP(131), IntMP(153 ^ 131))
        XCTAssertEqual(IntMP(-153) ^ IntMP(131), IntMP(-153 ^ 131))
        XCTAssertEqual(IntMP(153) ^ IntMP(-131), IntMP(153 ^ -131))
        XCTAssertEqual(IntMP(-153) ^ IntMP(-131), IntMP(-153 ^ -131))
    }

    func testShiftLeft() {
        let a = -12345678
        let b = a << 10
        let x = IntMP(a)
        let z = x << 10
        XCTAssertEqual(z, IntMP(b))
    }

    func testShiftRight() {
        let a = -12345678
        let b = a >> 10
        let x = IntMP(a)
        let z = x >> 10
        XCTAssertEqual(z, IntMP(b))
    }

    func testBit() {
        var a = IntMP.zero
        a[1] = 1
        XCTAssertEqual(a, 2)
        a[128] = 1
        let b = (IntMP(1) << 128) + 2
        XCTAssertEqual(a, b)
    }

    func testMemory() {
        var a = IntMP.zero
        for i in 0..<1024 {
            let z = IntMP(1) << i
            a = a + z
        }
    }

    static var allTests = [
        ("testCreateIntMP", testCreateIntMP),
        ("testBitWidth", testBitWidth)
    ]
}
