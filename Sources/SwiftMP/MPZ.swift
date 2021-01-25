//
//  Self.swift
//  
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cmpfr

public struct MPZ {
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    @usableFromInline internal typealias bWord = UnsafeMutableBufferPointer<Word>
    @usableFromInline internal typealias pMPZ = UnsafeMutablePointer<mpz_t>
    @usableFromInline internal typealias bMPZ = UnsafeMutableBufferPointer<mpz_t>
    @usableFromInline static let wordBits = MemoryLayout<Word>.size * 8
    @usableFromInline internal static let wordMask = ~Word(0)

    @usableFromInline internal var value =
        pMPZ.allocate(capacity: 1)

    @usableFromInline internal var limbs: bWord {
        return bWord(start: value[0]._mp_d,
                     count: abs(Int(value[0]._mp_size)))
    }

    @inlinable
    public init() {
        mpz_init(value)
    }

    @usableFromInline
    internal init?(mpz: bMPZ) {
        if mpz.count != 1 {
            return nil
        }
        value.deallocate()
        value = pMPZ.allocate(capacity: 1)
        value.initialize(to: mpz[0])
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
        let sz = source as? Self
        if sz != nil {
            mpz_init_set(value, sz!.value)
            return
        }
        if T.isSigned {
            let si = source as? Int
            if si != nil {
                mpz_init_set_si(value, si!)
                return
            }
        } else {
            let su = source as? UInt
            if su != nil {
                mpz_init_set_ui(value, su!)
                return
            }
        }
        return nil
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

    @inlinable
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
        let sz = source as? Self
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
        let sz = val as? Self
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
        let sz = source as? Self
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

    @inlinable
    public func probablyPrime() -> Bool {
        return mpz_probab_prime_p(value, 32) == 0
    }

    @inlinable
    public static func gcd(_ lhs: Self, _ rhs: Self) -> Self {
        let result = Self()
        mpz_gcd(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func lcm(_ lhs: Self, _ rhs: Self) -> Self {
        let result = Self()
        mpz_lcm(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func factorial(_ value: UInt) -> Self {
        let result = Self()
        mpz_fac_ui(result.value, value)
        return result
    }

    @inlinable
    var nonzeroBitCount: Int {
        let v = Self()
        mpz_set(v.value, value)
        if signum() < 0 {
            let mask = Self()
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
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) == 0
    }

    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpz_cmp(lhs.value, Self(rhs).value) == 0
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpz_cmp(Self(lhs).value, rhs.value) == 0
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) < 0
    }

    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpz_cmp(lhs.value, Self(rhs).value) < 0
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpz_cmp(Self(lhs).value, rhs.value) < 0
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) > 0
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpz_cmp(lhs.value, Self(rhs).value) > 0
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpz_cmp(Self(lhs).value, rhs.value) > 0
    }
}

extension MPZ: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
}

extension MPZ: AdditiveArithmetic {
    @inlinable
    public static var zero: Self{
        return Self()
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_add(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_sub(result.value, lhs.value, rhs.value)
        return result
    }
}

extension MPZ: Numeric {
    public typealias Magnitude = Self

    @inlinable
    public var magnitude: Magnitude {
        let result = Self()
        mpz_abs(result.value, value)
        return result
    }

    @inlinable
    public static func * (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_mul(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func *= (lhs: inout Self, rhs: Self) {
        mpz_mul(lhs.value, lhs.value, rhs.value)
    }

}

extension MPZ: SignedNumeric {
    @inlinable
    public static prefix func +(_ x: Self) -> Self {
        return x
    }

    @inlinable
    public static prefix func -(_ x: Self) -> Self {
        let result = Self()
        mpz_neg(result.value, x.value)
        return result
    }

    @inlinable
    public func negate() {
        mpz_neg(value, value)
    }
}

extension MPZ: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension MPZ: BinaryInteger {
    @inlinable
    static public var isSigned: Bool {
        return true
    }

    @inlinable
    public func signum() -> Self {
        return Self(mpz_sgn(value))
    }

    @inlinable
    public func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        let quotient = Self()
        let reminder = Self()
        mpz_tdiv_qr(quotient.value, reminder.value, value, rhs.value)
        return (quotient, reminder)
    }

    @inlinable
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
        if mpz_size(value) == 0 {
            return 1
        }
        return mpz_sizeinbase(value, 2) + 1
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

    @inlinable
    public static prefix func ~ (x: Self) -> Self {
        let result = Self()
        mpz_com(result.value, x.value)
        return result
    }

    @inlinable
    public static func / (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_tdiv_q(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func /= (lhs: inout Self, rhs: Self) {
        mpz_tdiv_q(lhs.value, lhs.value, rhs.value)
    }

    @inlinable
    public static func % (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_tdiv_r(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func %= (lhs: inout Self, rhs: Self) {
        mpz_tdiv_r(lhs.value, lhs.value, rhs.value)
    }

    @inlinable
    public static func & (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_and(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func &= (lhs: inout Self, rhs: Self) {
        mpz_and(lhs.value, lhs.value, rhs.value)
    }

    @inlinable
    public static func | (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_ior(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func |= (lhs: inout Self, rhs: Self) {
        mpz_ior(lhs.value, lhs.value, rhs.value)
    }

    @inlinable
    public static func ^ (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_xor(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func ^= (lhs: inout Self, rhs: Self) {
        mpz_xor(lhs.value, lhs.value, rhs.value)
    }

    @inlinable
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let result = Self()
        mpz_fdiv_q_2exp(result.value, lhs.value, UInt(rhs))
        return result
    }

    @inlinable
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        mpz_fdiv_q_2exp(lhs.value, lhs.value, UInt(rhs))
    }

    @inlinable
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let result = Self()
        mpz_mul_2exp(result.value, lhs.value, UInt(rhs))
        return result
    }

    @inlinable
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
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
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size + 1)
        _ = mpz_get_str(buffer, base, value)
        let str = String(cString: buffer)
        buffer.deallocate()
        return str
    }
}

extension MPZ: CustomDebugStringConvertible {
    public var debugDescription: String {
        let base: Int32 = 16
        let size = mpz_sizeinbase(value, base) + 2
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size + 1)
        _ = mpz_get_str(buffer, base, magnitude.value)
        let str = String(cString: buffer)
        buffer.deallocate()
        if mpz_sgn(value) < 0 {
            return "-0x\(str)"
        } else {
            return "0x\(str)"
        }
    }
}

extension MPZ: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        let str = description.cString(using: .ascii)!
        mpz_init(self.value)
        if mpz_set_str(self.value, str, 0) != 0 {
            return nil
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
