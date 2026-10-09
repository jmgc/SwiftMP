import XCTest
import SwiftMP

/// Every example of TUTORIAL.md, with the outputs it shows.
final class TutorialTests: XCTestCase {

    // MARK: 2. IntMP

    func testCreatingIntegers() {
        let a: IntMP = 42
        let b: IntMP = "123456789012345678901234567890"
        let c = IntMP(Int64.min)
        let d = IntMP(-2.75)
        let f = IntMP(stringLiteral: "777", base: 8)
        let text = "0xff"
        let e = IntMP(text)
        let bad = "12abc"
        let g = IntMP(bad)

        XCTAssertEqual(a, 42)
        XCTAssertEqual(b.description, "123456789012345678901234567890")
        XCTAssertEqual(c.description, "-9223372036854775808")
        XCTAssertEqual(d, -2)
        XCTAssertEqual(f, 511)
        XCTAssertEqual(e, 255)
        XCTAssertNil(g)
        XCTAssertNil(IntMP(exactly: 2.5))
        XCTAssertEqual(IntMP(exactly: 3.0), 3)
    }

    func testIntegerArithmetic() {
        let x: IntMP = "123456789012345678901234567890"
        let y: IntMP = "987654321098765432109876543210"
        XCTAssertEqual((x * y).description,
                       "121932631137021795226185032733622923332237463801111263526900")
        XCTAssertEqual(y / x, 8)
        XCTAssertEqual((y % x).description, "9000000000900000000090")
        XCTAssertEqual((-x).description, "-123456789012345678901234567890")
        XCTAssertEqual(IntMP(-7) / 2, -3)
        XCTAssertEqual(IntMP(-7) % 2, -1)

        let n = 10
        XCTAssertEqual(x + IntMP(n), x + 10)

        var total: IntMP = 0
        for i in 1...100 {
            total += IntMP(i) * IntMP(i)
        }
        XCTAssertEqual(total, 338350)
    }

    func testNumberTheory() {
        XCTAssertEqual(IntMP.factorial(30).description, "265252859812191058636308480000000")
        XCTAssertEqual(IntMP.gcd(12, 18), 6)
        XCTAssertEqual(IntMP.lcm(12, 18), 36)
        XCTAssertTrue(((IntMP(1) << 127) - 1).probablyPrime())
        XCTAssertFalse(IntMP(91).probablyPrime())
    }

    func testBits() {
        let p = IntMP(1) << 100
        XCTAssertEqual(p.description, "1267650600228229401496703205376")
        XCTAssertEqual(p >> 98, 4)
        XCTAssertEqual(IntMP(255) & 0x0f, 15)
        XCTAssertEqual(~IntMP(5), -6)
        XCTAssertEqual(IntMP(-8) >> 1, -4)

        var bits: IntMP = 0
        bits[3] = 1
        bits[130] = 1
        XCTAssertEqual(bits[3], 1)
        XCTAssertEqual(bits, (IntMP(1) << 130) + 8)
        XCTAssertEqual(IntMP(255).bitWidth, 9)
    }

    func testTextAndConversion() {
        let h = (IntMP(1) << 100) + 255
        XCTAssertEqual(h.description, "1267650600228229401496703205631")
        XCTAssertEqual(h.debugDescription, "0x100000000000000000000000ff")
        XCTAssertNil(Int(exactly: h))
        XCTAssertEqual(Int(IntMP(42)), 42)
        XCTAssertEqual(Int(truncatingIfNeeded: (IntMP(1) << 64) + 5), 5)
        XCTAssertEqual(Double(IntMP(1) << 100), 1.2676506002282294e+30)
    }

    private func fibonacci<T: BinaryInteger>(_ n: Int, as _: T.Type) -> T {
        var (a, b): (T, T) = (0, 1)
        for _ in 0..<n { (a, b) = (b, a + b) }
        return a
    }

    func testGenericCode() {
        XCTAssertEqual(fibonacci(90, as: Int.self), 2880067194370816120)
        XCTAssertEqual(fibonacci(200, as: IntMP.self).description,
                       "280571172992510140037611932413038677189525")
    }

    // MARK: 3. UIntMP

    func testUnsigned() {
        let u: UIntMP = "340282366920938463463374607431768211455"
        XCTAssertEqual((u + 1).description, "340282366920938463463374607431768211456")
        XCTAssertNil(UIntMP(exactly: -1))
        XCTAssertEqual(UIntMP(truncatingIfNeeded: -1), 3)
    }

    // MARK: 4. QuotMP

    func testFractions() {
        let third = QuotMP(num: 1, den: 3)
        let sixth = QuotMP(num: 1, den: 6)
        XCTAssertEqual((third + sixth).description, "1/2")
        XCTAssertEqual((QuotMP(num: 2, den: 3) * QuotMP(num: 9, den: 4)).description, "3/2")
        XCTAssertEqual(QuotMP(num: 6, den: -4).description, "-3/2")
        XCTAssertEqual(QuotMP(num: 6, den: -4).num, -3)
        XCTAssertEqual(QuotMP(num: 6, den: -4).den, 2)

        let q: QuotMP = "22/7"
        XCTAssertEqual(q, QuotMP(num: 22, den: 7))
        let input = "1/0"
        XCTAssertNil(QuotMP(input))

        XCTAssertEqual(QuotMP(0.1).description, "3602879701896397/36028797018963968")
        XCTAssertEqual(QuotMP(0.75).description, "3/4")
        XCTAssertLessThan(QuotMP(num: 1, den: 2), QuotMP(num: 2, den: 3))
    }

    // MARK: 5. FloatMP

    func testPrecision() {
        let saved = FloatMP.significandBitCount
        defer { FloatMP.significandBitCount = saved }

        FloatMP.significandBitCount = 200
        let two: FloatMP = 2
        let root = FloatMP.sqrt(two)
        XCTAssertEqual(root.significandWidth, 200)
        XCTAssertTrue(root.description.hasPrefix("1.41421356237309504880168872420969807856967187537694"),
                      root.description)
        FloatMP.significandBitCount = 53

        var v = FloatMP(1) / FloatMP(3)
        XCTAssertEqual(v.significandWidth, 53)
        v.significandWidth = 20
        XCTAssertEqual(v.significandWidth, 20)
    }

    func testFloatArithmetic() {
        let a: FloatMP = 1.5
        let b = FloatMP(2)
        let c = FloatMP(IntMP(1) << 200)
        let d = FloatMP(QuotMP(num: 1, den: 4))
        let e: FloatMP = "2.5e21"
        XCTAssertEqual(a + b, 3.5)
        XCTAssertEqual(a * b, 3.0)
        XCTAssertEqual(c, FloatMP(1) << 200)
        XCTAssertEqual(d, 0.25)
        XCTAssertEqual(e, 2.5e21)
        XCTAssertNil(FloatMP(exactly: (IntMP(1) << 200) + 1))
    }

    func testFunctions() {
        XCTAssertEqual(FloatMP.sin(FloatMP.pi / 2), 1)
        XCTAssertEqual(FloatMP.cos(FloatMP.pi), -1)
        XCTAssertEqual(FloatMP.exp(1), FloatMP(M_E))
        XCTAssertLessThan((FloatMP.log(FloatMP.exp(2)) - 2).magnitude, 1e-15)
        XCTAssertEqual(FloatMP.pow(2, 10), 1024)
        XCTAssertEqual(FloatMP.root(FloatMP(27), 3), 3)
        XCTAssertEqual(FloatMP.gamma(5), 24)
    }

    func testSpecialValues() {
        let nan = FloatMP.nan
        XCTAssertNotEqual(nan, nan)
        XCTAssertTrue(nan.isNaN)
        XCTAssertTrue(FloatMP.infinity > (FloatMP(1) << 10_000))
        XCTAssertEqual(FloatMP(0.0), FloatMP(-0.0))
    }

    func testRounding() {
        XCTAssertEqual(FloatMP(2.5).rounded(.toNearestOrEven), 2)
        XCTAssertEqual(FloatMP(2.5).rounded(.awayFromZero), 3)
        XCTAssertEqual(FloatMP(-2.5).rounded(.down), -3)
    }

    // MARK: 6. Values and hashing

    func testValuesAndHashing() {
        var m: IntMP = "1000000000000000000000"
        let n = m
        m *= 2
        XCTAssertEqual(n.description, "1000000000000000000000")
        XCTAssertEqual(m.description, "2000000000000000000000")

        var cache: [IntMP: String] = [:]
        cache[IntMP.factorial(20)] = "20!"
        XCTAssertEqual(cache[IntMP(2432902008176640000)], "20!")
    }
}
