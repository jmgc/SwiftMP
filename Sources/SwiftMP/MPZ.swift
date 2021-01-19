//
//  MPZ.swift
//  
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cminigmp

public struct MPZ {
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    @usableFromInline static let wordBits = MemoryLayout<Word>.size * 8
    @usableFromInline internal static let mask = ~Word(0)

    @usableFromInline internal var value =
        UnsafeMutablePointer<mpz_t>.allocate(capacity: 1)

    internal var limbs: UnsafeMutableBufferPointer<Word> {
        return UnsafeMutableBufferPointer(start: value[0]._mp_d,
                                          count: abs(Int(value[0]._mp_size)))
    }

    @inlinable
    init() {
        mpz_init(value)
    }

    @inlinable
    init(bits: UInt) {
        mpz_init2(value, bits)
    }

    @inlinable
    public init(integerLiteral val: IntegerLiteralType) {
        mpz_init_set_si(value, val)
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        let si = source as? Int
        if si != nil {
            mpz_init_set_si(value, si!)
            return
        }
        let su = source as? UInt
        if su != nil {
            mpz_init_set_ui(value, su!)
            return
        }
        let sz = source as? MPZ
        if sz != nil {
            mpz_init_set(value, sz!.value)
        }
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        let d = source as? Double
        if d != nil {
            mpz_init_set_d(value, d!)
            return
        }
        return nil
    }

    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        let d = source as? Double
        if d != nil {
            mpz_init_set_d(value, d!)
            return
        }
        fatalError("Not implemented")
    }

    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        let sz = source as? MPZ
        if sz != nil {
            mpz_init_set(value, sz!.value)
            return
        }
        if T.isSigned {
            let si = Int(source)
            mpz_init_set_si(value, si)
        } else {
            let su = UInt(source)
            mpz_init_set_ui(value, su)
        }
    }

    @inlinable
    public init<T>(clamping val: T) where T : BinaryInteger {
        let si = val as? Int
        if si != nil {
            mpz_init_set_si(value, si!)
            return
        }
        let su = val as? UInt
        if su != nil {
            mpz_init_set_ui(value, su!)
            return
        }
        let sz = val as? MPZ
        if sz != nil {
            mpz_init_set(value, sz!.value)
        }
    }

    @inlinable
    public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        let si = source as? Int
        if si != nil {
            mpz_init_set_si(value, si!)
            return
        }
        let su = source as? UInt
        if su != nil {
            mpz_init_set_ui(value, su!)
            return
        }
        let sz = source as? MPZ
        if sz != nil {
            mpz_init_set(value, sz!.value)
        }
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        let str = value.cString(using: .ascii)!
        mpz_init_set_str(self.value, str, 0)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType, base: Int) {
        let str = value.cString(using: .ascii)!
        mpz_init_set_str(self.value, str, Int32(base))
    }

    public func probablyPrime() -> Bool {
        return mpz_probab_prime_p(value, 32) == 0
    }

    public static func gcd(_ lhs: MPZ, _ rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_gcd(result.value, lhs.value, rhs.value)
        return result
    }

    public static func lcm(_ lhs: MPZ, _ rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_lcm(result.value, lhs.value, rhs.value)
        return result
    }

    public static func factorial(_ value: UInt) -> MPZ {
        let result = MPZ()
        mpz_fac_ui(result.value, value)
        return result
    }

    @inlinable
    var nonzeroBitCount: Int {
        let v = MPZ()
        mpz_set(v.value, value)
        if signum() < 0 {
            let mask = MPZ()
            mpz_set_si(mask.value, -1)
            mpz_mul_2exp(mask.value, mask.value, UInt(bitWidth))
            mpz_com(mask.value, mask.value)
            mpz_and(v.value, v.value, mask.value)
        }
        let ones = Int(mpz_popcount(v.value))
        return ones
    }
}

extension MPZ: Comparable {
    public static func == (lhs: MPZ, rhs: MPZ) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) == 0
    }

    public static func ==<RHS> (lhs: MPZ, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let si = rhs as? Int
        if si != nil {
            return mpz_cmp_si(lhs.value, si!) == 0
        }
        let su = rhs as? UInt
        if su != nil {
            return mpz_cmp_ui(lhs.value, su!) == 0
        }
        return mpz_cmp(lhs.value, MPZ(rhs).value) == 0
    }

    public static func ==<LHS> (lhs: LHS, rhs: MPZ) -> Bool where LHS : BinaryInteger {
        let si = lhs as? Int
        if si != nil {
            return mpz_cmp_si(rhs.value, si!) == 0
        }
        let su = lhs as? UInt
        if su != nil {
            return mpz_cmp_ui(rhs.value, su!) == 0
        }
        return mpz_cmp(rhs.value, MPZ(lhs).value) == 0
    }

    public static func == (lhs: MPZ, rhs: UInt) -> Bool {
        return mpz_cmp_ui(lhs.value, rhs) == 0
    }

    public static func == (lhs: UInt, rhs: MPZ) -> Bool {
        return mpz_cmp_ui(rhs.value, lhs) == 0
    }

    public static func < (lhs: MPZ, rhs: MPZ) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) < 0
    }

    public static func < (lhs: MPZ, rhs: Int) -> Bool {
        return mpz_cmp_si(lhs.value, rhs) < 0
    }

    public static func < (lhs: Int, rhs: MPZ) -> Bool {
        return mpz_cmp_si(rhs.value, lhs) > 0
    }

    public static func < (lhs: MPZ, rhs: UInt) -> Bool {
        return mpz_cmp_ui(lhs.value, rhs) < 0
    }

    public static func < (lhs: UInt, rhs: MPZ) -> Bool {
        return mpz_cmp_ui(rhs.value, lhs) > 0
    }

    public static func > (lhs: MPZ, rhs: MPZ) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) > 0
    }

    public static func > (lhs: MPZ, rhs: Int) -> Bool {
        return mpz_cmp_si(lhs.value, rhs) > 0
    }

    public static func > (lhs: Int, rhs: MPZ) -> Bool {
        return mpz_cmp_si(rhs.value, lhs) < 0
    }

    public static func > (lhs: MPZ, rhs: UInt) -> Bool {
        return mpz_cmp_ui(lhs.value, rhs) > 0
    }

    public static func > (lhs: UInt, rhs: MPZ) -> Bool {
        return mpz_cmp_ui(rhs.value, lhs) < 0
    }
}

extension MPZ: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
}

extension MPZ: AdditiveArithmetic {
    public static var zero: MPZ{
        return MPZ()
    }

    public static func + (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_add(result.value, lhs.value, rhs.value)
        return result
    }

    public static func - (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_sub(result.value, lhs.value, rhs.value)
        return result
    }
}

extension MPZ: Numeric {
    public typealias Magnitude = MPZ

    public var magnitude: Magnitude {
        let result = MPZ()
        mpz_abs(result.value, value)
        return result
    }

    public static func * (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_mul(result.value, lhs.value, rhs.value)
        return result
    }

    public static func *= (lhs: inout MPZ, rhs: MPZ) {
        mpz_mul(lhs.value, lhs.value, rhs.value)
    }

}

extension MPZ: SignedNumeric {
    public static prefix func +(_ x: MPZ) -> MPZ {
        return x
    }

    public static prefix func -(_ x: MPZ) -> MPZ {
        let result = MPZ()
        mpz_neg(result.value, x.value)
        return result
    }

    public func negate() {
        mpz_neg(value, value)
    }
}

extension MPZ: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension MPZ: BinaryInteger {
    static public var isSigned: Bool {
        return true
    }

    public func signum() -> Self {
        return MPZ(mpz_sgn(value))
    }

    public func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        let quotient = MPZ()
        let reminder = MPZ()
        mpz_tdiv_qr(quotient.value, reminder.value, value, rhs.value)
        return (quotient, reminder)
    }

    public var words: [Word] {
        let b = limbs
        if mpz_sgn(value) < 0 {
            var v = b.map({~$0})
            for (d, l) in zip(v, limbs) {
                assert(d != l)
            }
            for idx in v.indices {
                v[idx] += 1
                if v[idx] != 0 {
                    break
                }
            }
            return v
        }
        return Array(b)
    }

    public var bitWidth: Int {
        let n = abs(Int(value[0]._mp_size))
        if n == 0 {
            return 1
        }
        var word = 0
        var bits = MPZ.wordBits
        for idx in stride(from: abs(Int(value[0]._mp_size)) - 1, through: 0, by: -1) {
            let v = value[0]._mp_d[idx]
            if v == 0 {
                continue
            } else {
                word = idx
                var mask = MPZ.Word(1) << (bits - 1)
                while (v & mask) == Word(0) {
                    bits -= 1
                    mask >>= 1
                }
            }
        }
        return word * MPZ.wordBits + bits + 1 // Sign bit
    }

    public var trailingZeroBitCount: Int {
        let n = abs(Int(value[0]._mp_size))
        if n == 0 {
            return 0
        }
        let idx = limbs.firstIndex(where: {$0 != 0})
        if idx == nil {
            return limbs[0].trailingZeroBitCount
        }
        return idx! + limbs[idx!].trailingZeroBitCount
    }

    public static prefix func ~ (x: MPZ) -> MPZ {
        let result = MPZ()
        mpz_com(result.value, x.value)
        return result
    }

    public static func / (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_tdiv_q(result.value, lhs.value, rhs.value)
        return result
    }

    public static func /= (lhs: inout MPZ, rhs: MPZ) {
        mpz_tdiv_q(lhs.value, lhs.value, rhs.value)
    }

    public static func % (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_tdiv_r(result.value, lhs.value, rhs.value)
        return result
    }

    public static func %= (lhs: inout MPZ, rhs: MPZ) {
        mpz_tdiv_r(lhs.value, lhs.value, rhs.value)
    }

    public static func & (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_and(result.value, lhs.value, rhs.value)
        return result
    }

    public static func &= (lhs: inout MPZ, rhs: MPZ) {
        mpz_and(lhs.value, lhs.value, rhs.value)
    }

    public static func | (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_ior(result.value, lhs.value, rhs.value)
        return result
    }

    public static func |= (lhs: inout MPZ, rhs: MPZ) {
        mpz_ior(lhs.value, lhs.value, rhs.value)
    }

    public static func ^ (lhs: MPZ, rhs: MPZ) -> MPZ {
        let result = MPZ()
        mpz_xor(result.value, lhs.value, rhs.value)
        return result
    }

    public static func ^= (lhs: inout MPZ, rhs: MPZ) {
        mpz_xor(lhs.value, lhs.value, rhs.value)
    }

    public static func >> <RHS>(lhs: MPZ, rhs: RHS) -> MPZ where RHS : BinaryInteger {
        let result = MPZ()
        mpz_fdiv_q_2exp(result.value, lhs.value, UInt(rhs))
        return result
    }

    public static func >>= <RHS>(lhs: inout MPZ, rhs: RHS) where RHS : BinaryInteger {
        mpz_fdiv_q_2exp(lhs.value, lhs.value, UInt(rhs))
    }

    public static func << <RHS>(lhs: MPZ, rhs: RHS) -> MPZ where RHS : BinaryInteger {
        let result = MPZ()
        mpz_mul_2exp(result.value, lhs.value, UInt(rhs))
        return result
    }

    public static func <<= <RHS>(lhs: inout MPZ, rhs: RHS) where RHS : BinaryInteger {
        mpz_mul_2exp(lhs.value, lhs.value, UInt(rhs))
    }
}

extension MPZ: SignedInteger {
}

extension MPZ: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension MPZ: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public init(floatLiteral source: FloatLiteralType) {
        mpz_init_set_d(value, source)
    }
}

extension MPZ: CustomStringConvertible {
    public var description: String {
        let base: Int32 = 10
        let size = mpz_sizeinbase(value, base) + 2
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
        _ = mpz_get_str(buffer, base, value)
        let str = String(cString: buffer)
        buffer.deallocate()
        return str
    }
}

extension MPZ: CustomDebugStringConvertible {
    public var debugDescription: String {
        let base: Int32 = 10
        let size = mpz_sizeinbase(value, base) + 2
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
        _ = mpz_get_str(buffer, 16, magnitude.value)
        let str = String(cString: buffer)
        buffer.deallocate()
        if mpz_sgn(value) < 0 {
            return "MPZ(\"-0x\(str)\")"
        } else {
            return "MPZ(\"0x\(str)\")"
        }
    }
}

extension MPZ: RandomAccessCollection {
    public typealias Element = Int

    public typealias Index = Int

    @inlinable
    public subscript(position: Index) -> Element {
        get {
            return Int(mpz_tstbit(value, UInt(position)))
        }
        set(newValue) {
            if newValue == 0 {
                mpz_clrbit(value, UInt(position))
            } else {
                mpz_setbit(value, UInt(position))
            }
        }
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return bitWidth
    }
}

extension MPZ: MutableCollection {
}
