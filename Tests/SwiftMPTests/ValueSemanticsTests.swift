import XCTest
@testable import SwiftMP

/// Copy-on-write, memory release, hashing and conversions.
final class ValueSemanticsTests: XCTestCase {

    // MARK: Copies are independent

    func testIntMPCopiesAreIndependent() {
        let a: IntMP = "123456789012345678901234567890"
        var b = a
        b *= 2
        XCTAssertEqual(a, IntMP("123456789012345678901234567890"))
        XCTAssertEqual(b, IntMP("246913578024691357802469135780"))

        var c = a
        c.negate()
        XCTAssertEqual(a.signum(), 1)
        XCTAssertEqual(c.signum(), -1)

        var d = a
        d[0] = 1
        d += 1
        d <<= 3
        XCTAssertEqual(a, IntMP("123456789012345678901234567890"))
    }

    func testUIntMPCopiesAreIndependent() {
        let a: UIntMP = 1000
        var b = a
        b -= 1
        b[20] = 1
        b >>= 1
        XCTAssertEqual(a, 1000)
    }

    func testQuotMPCopiesAreIndependent() {
        let a = QuotMP(num: 1, den: 3)
        var b = a
        b *= QuotMP(num: 3, den: 1)
        b.negate()
        XCTAssertEqual(a, QuotMP(num: 1, den: 3))
        XCTAssertEqual(b, -1)
    }

    func testFloatMPCopiesAreIndependent() {
        let a: FloatMP = 2
        var b = a
        b.formSquareRoot()
        b.negate()
        b.significandWidth = 200
        XCTAssertEqual(a, 2)
        XCTAssertEqual(a.significandWidth, FloatMP.significandBitCount)
    }

    // MARK: Memory is released

    func testTemporariesAreFreed() {
        let before = _MPLiveCount.current
        do {
            var i: IntMP = 1
            var u: UIntMP = 1
            var q = QuotMP(num: 1, den: 2)
            var f: FloatMP = 1
            for k in 0..<500 {
                i = i * 3 + IntMP(k)
                u = (u << 1) + UIntMP(k)
                q = q * QuotMP(num: 2, den: 3) + 1
                f = f * 1.5 - 0.25
            }
            XCTAssertGreaterThan(_MPLiveCount.current, before)
            _ = (i, u, q, f)
        }
        XCTAssertEqual(_MPLiveCount.current, before)
    }

    // MARK: Hashing agrees with ==

    func testIntMPHashing() {
        let big = IntMP(1) << 200
        let set: Set<IntMP> = [big, (IntMP(1) << 199) * 2, -big, 0, IntMP(0)]
        XCTAssertEqual(set.count, 3)
        var dict: [IntMP: String] = [:]
        dict[IntMP(42)] = "answer"
        XCTAssertEqual(dict[IntMP(6) * IntMP(7)], "answer")
    }

    func testUIntMPHashing() {
        // -1 truncated stands for the bit pattern 0b11, and compares equal to 3 and 7.
        let minusOne = UIntMP(truncatingIfNeeded: -1)
        XCTAssertEqual(minusOne, UIntMP(3))
        XCTAssertEqual(minusOne, UIntMP(7))
        XCTAssertEqual(minusOne.hashValue, UIntMP(3).hashValue)
        XCTAssertEqual(minusOne.hashValue, UIntMP(7).hashValue)
        let minusThree = UIntMP(truncatingIfNeeded: -3)
        XCTAssertEqual(minusThree, UIntMP(5))
        XCTAssertEqual(minusThree, UIntMP(13))
        XCTAssertEqual(minusThree.hashValue, UIntMP(5).hashValue)
        XCTAssertEqual(minusThree.hashValue, UIntMP(13).hashValue)
        XCTAssertEqual(Set([UIntMP(10), UIntMP(10), UIntMP(11)]).count, 2)
    }

    func testQuotMPHashing() {
        let set: Set<QuotMP> = [QuotMP(num: 1, den: 2), QuotMP(num: 2, den: 4),
                                QuotMP(num: -3, den: -6), QuotMP(0.5)]
        XCTAssertEqual(set.count, 1)
    }

    func testFloatMPHashingAndNaN() {
        var wide: FloatMP = 0.75
        wide.significandWidth = 300
        let narrow: FloatMP = 0.75
        XCTAssertEqual(wide, narrow)
        XCTAssertEqual(wide.hashValue, narrow.hashValue)
        XCTAssertEqual(FloatMP(0.0).hashValue, FloatMP(-0.0).hashValue)
        XCTAssertEqual(FloatMP(0.0), FloatMP(-0.0))
        // Through functions, so the compiler does not flag the NaN comparisons.
        func less(_ a: FloatMP, _ b: FloatMP) -> Bool { a < b }
        func greater(_ a: FloatMP, _ b: FloatMP) -> Bool { a > b }
        let nan = FloatMP.nan
        XCTAssertNotEqual(nan, nan)
        XCTAssertFalse(less(nan, 1))
        XCTAssertFalse(greater(nan, 1))
    }

    // MARK: Conversions

    func testIntMPConversions() {
        XCTAssertEqual(IntMP(Int64.min).description, "-9223372036854775808")
        XCTAssertEqual(IntMP(UInt64.max).description, "18446744073709551615")
        XCTAssertEqual(IntMP(truncatingIfNeeded: Int32(-5)), -5)
        XCTAssertEqual(IntMP(clamping: UInt16(7)), 7)
        XCTAssertEqual(IntMP(Int8(-128)), -128)
        XCTAssertEqual(IntMP(UIntMP(stringLiteral: "340282366920938463463374607431768211455")),
                       IntMP("340282366920938463463374607431768211455"))

        XCTAssertNil(IntMP(exactly: 2.5))
        XCTAssertNil(IntMP(exactly: Double.infinity))
        XCTAssertEqual(IntMP(exactly: 3.0), 3)
        XCTAssertEqual(IntMP(-2.75), -2)
        XCTAssertEqual(IntMP(Float(1.5e20)), IntMP(Double(Float(1.5e20))))
        XCTAssertEqual(IntMP(FloatMP(-7.5)), -7)

        // Back to fixed-width types through `words`.
        let twoTo64 = IntMP(1) << 64
        XCTAssertEqual(Int(truncatingIfNeeded: twoTo64 + 5), 5)
        XCTAssertEqual(Int64(IntMP(-12345)), -12345)
        XCTAssertNil(Int(exactly: IntMP(1) << 63))
        XCTAssertEqual(Int(exactly: -(IntMP(1) << 63)), Int.min)
        XCTAssertEqual(UInt64(exactly: (IntMP(1) << 64) - 1), UInt64.max)
        XCTAssertEqual(IntMP(0).words, [0])
        XCTAssertEqual(IntMP(-1).words, [UInt.max])
        XCTAssertEqual((-(IntMP(1) << 64)).words, [0, UInt.max])
    }

    func testUIntMPConversions() {
        XCTAssertNil(UIntMP(exactly: -1))
        XCTAssertNil(UIntMP(exactly: -1.0))
        XCTAssertEqual(UIntMP(exactly: 8), 8)
        XCTAssertEqual(UIntMP(clamping: -20), 0)
        XCTAssertEqual(UIntMP(UInt64.max).description, "18446744073709551615")
        XCTAssertEqual(UInt8(UIntMP(200)), 200)
    }

    func testQuotMPConversions() {
        XCTAssertEqual(QuotMP(0.75), QuotMP(num: 3, den: 4))
        XCTAssertEqual(QuotMP(Float(-0.125)), QuotMP(num: -1, den: 8))
        XCTAssertNil(QuotMP(exactly: Double.nan))
        XCTAssertEqual(QuotMP(FloatMP(0.375)), QuotMP(num: 3, den: 8))
        XCTAssertEqual(QuotMP(Int64.min).num.description, "-9223372036854775808")
        let q = QuotMP(num: 6, den: -4)
        XCTAssertEqual(q.num, -3)
        XCTAssertEqual(q.den, 2)
    }

    func testFloatMPConversions() {
        XCTAssertNotNil(FloatMP(exactly: 1 << 52))
        XCTAssertNil(FloatMP(exactly: (IntMP(1) << 200) + 1))
        XCTAssertEqual(FloatMP(Float(0.5)), 0.5)
        XCTAssertEqual(FloatMP(QuotMP(num: 1, den: 4)), 0.25)
        XCTAssertEqual(FloatMP(1).distance(to: FloatMP(3)), 2)
    }

    // MARK: Fixed behaviour

    func testProbablyPrime() {
        XCTAssertTrue(IntMP(97).probablyPrime())
        XCTAssertFalse(IntMP(91).probablyPrime())
        XCTAssertTrue(((IntMP(1) << 127) - 1).probablyPrime())
    }

    func testNegativeShiftCounts() {
        XCTAssertEqual(IntMP(8) >> -1, 16)
        XCTAssertEqual(IntMP(8) << -1, 4)
        XCTAssertEqual(IntMP(-7) >> 1, -4)
    }

    func testConcurrentUse() {
        let shared: IntMP = "98765432109876543210987654321"
        DispatchQueue.concurrentPerform(iterations: 8) { k in
            var local = shared
            for _ in 0..<200 {
                local *= IntMP(k + 2)
                local /= IntMP(k + 2)
            }
            XCTAssertEqual(local, shared)
        }
        XCTAssertEqual(shared, IntMP("98765432109876543210987654321"))
    }
}
