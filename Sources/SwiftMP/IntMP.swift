//
//  IntMP.swift
//
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cmpfr

/// Arbitrary-precision signed integer (GMP `mpz_t`) with value semantics.
public struct IntMP: Sendable {
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    @usableFromInline internal typealias pMPZ = UnsafeMutablePointer<mpz_t>
    @usableFromInline static let wordBits = MemoryLayout<Word>.size * 8
    @usableFromInline internal static let wordMask = ~Word(0)

    @usableFromInline internal var storage = _MPZStorage()

    /// The C value. Read it freely; call `makeUnique()` before writing to it.
    @usableFromInline internal var value: pMPZ {
        return storage.pointer
    }

    /// Copy-on-write: gives this value its own storage before it is modified.
    @inlinable
    internal mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = _MPZStorage(copying: storage)
        }
    }

    @inlinable
    public init() {
    }

    @inlinable
    init(bits: UInt) {
        mpz_realloc2(value, bits)
    }

    @inlinable
    public init(integerLiteral val: IntegerLiteralType) {
        mpz_set_si(value, val)
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        _MPZ.set(value, source)
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        guard _MPZ.isIntegral(source) else {
            return nil
        }
        _MPZ.setTruncating(value, source)
    }

    /// Truncates toward zero. Traps on NaN or infinity.
    @inlinable
    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        _MPZ.setTruncating(value, source)
    }

    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        _MPZ.set(value, source)
    }

    /// An `IntMP` can hold every integer, so clamping never changes the value.
    @inlinable
    public init<T>(clamping val: T) where T : BinaryInteger {
        _MPZ.set(value, val)
    }

    /// An `IntMP` can hold every integer, so truncation never changes the value.
    @inlinable
    public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        _MPZ.set(value, source)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.init(stringLiteral: value, base: 0)
    }

    /// Parses `value` in `base` (0 = detect the `0x`, `0b` or `0` prefix).
    @inlinable
    public init(stringLiteral value: StringLiteralType, base: Int) {
        let ok = mpz_set_str(self.value, value, Int32(base)) == 0
        precondition(ok, "Invalid integer literal: \(value)")
    }

    /// True when the number is prime or probably prime (Miller-Rabin, 32 rounds).
    @inlinable
    public func probablyPrime() -> Bool {
        return mpz_probab_prime_p(value, 32) != 0
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

    /// Number of ones in the two's-complement representation of `bitWidth` bits.
    @inlinable
    public var nonzeroBitCount: Int {
        let v = Self()
        return withExtendedLifetime(v) {
            // Floor remainder modulo 2^bitWidth: the two's-complement bit pattern.
            mpz_fdiv_r_2exp(v.value, value, UInt(bitWidth))
            return Int(mpz_popcount(v.value))
        }
    }
}

extension IntMP: Comparable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) == 0
    }

    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpz_cmp(lhs.value, r.value) == 0 }
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpz_cmp(l.value, rhs.value) == 0 }
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) < 0
    }

    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpz_cmp(lhs.value, r.value) < 0 }
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpz_cmp(l.value, rhs.value) < 0 }
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return mpz_cmp(lhs.value, rhs.value) > 0
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpz_cmp(lhs.value, r.value) > 0 }
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpz_cmp(l.value, rhs.value) > 0 }
    }
}

extension IntMP: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
}

extension IntMP: AdditiveArithmetic {
    @inlinable
    public static var zero: Self {
        return Self()
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_add(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpz_add(lhs.value, lhs.value, rhs.value)
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpz_sub(result.value, lhs.value, rhs.value)
        return result
    }

    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpz_sub(lhs.value, lhs.value, rhs.value)
    }
}

extension IntMP: Numeric {
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
        lhs.makeUnique()
        mpz_mul(lhs.value, lhs.value, rhs.value)
    }

}

extension IntMP: SignedNumeric {
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
    public mutating func negate() {
        makeUnique()
        mpz_neg(value, value)
    }
}

extension IntMP: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        _MPZ.hash(value, into: &hasher)
    }
}

extension IntMP: BinaryInteger {
    @inlinable
    static public var isSigned: Bool {
        return true
    }

    @inlinable
    public func signum() -> Self {
        return Self(integerLiteral: Int(mpz_sgn(value)))
    }

    @inlinable
    public func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        let quotient = Self()
        let reminder = Self()
        mpz_tdiv_qr(quotient.value, reminder.value, value, rhs.value)
        return (quotient, reminder)
    }

    /// Two's-complement words, least significant first, covering `bitWidth` bits.
    @inlinable
    public var words: [Word] {
        let count = (bitWidth + Self.wordBits - 1) / Self.wordBits
        return _MPZ.words(value, count: count)
    }

    /// Minimum number of bits of a two's-complement representation (sign included).
    @inlinable
    public var bitWidth: Int {
        if mpz_sgn(value) == 0 {
            return 1
        }
        return mpz_sizeinbase(value, 2) + 1
    }

    @inlinable
    public var trailingZeroBitCount: Int {
        if mpz_sgn(value) == 0 {
            return bitWidth
        }
        return Int(mpz_scan1(value, 0))
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
        lhs.makeUnique()
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
        lhs.makeUnique()
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
        lhs.makeUnique()
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
        lhs.makeUnique()
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
        lhs.makeUnique()
        mpz_xor(lhs.value, lhs.value, rhs.value)
    }

    /// Arithmetic shift right (rounds toward minus infinity). A negative
    /// count shifts left, as for the standard integer types.
    @inlinable
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        var result = lhs
        result >>= rhs
        return result
    }

    @inlinable
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs.makeUnique()
        if rhs < (0 as RHS) {
            mpz_mul_2exp(lhs.value, lhs.value, UInt(rhs.magnitude))
        } else {
            mpz_fdiv_q_2exp(lhs.value, lhs.value, UInt(rhs))
        }
    }

    /// Shift left. A negative count shifts right.
    @inlinable
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        var result = lhs
        result <<= rhs
        return result
    }

    @inlinable
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs.makeUnique()
        if rhs < (0 as RHS) {
            mpz_fdiv_q_2exp(lhs.value, lhs.value, UInt(rhs.magnitude))
        } else {
            mpz_mul_2exp(lhs.value, lhs.value, UInt(rhs))
        }
    }
}

extension IntMP: SignedInteger {
}

extension IntMP: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension IntMP: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    /// Truncates toward zero.
    public init(floatLiteral source: FloatLiteralType) {
        mpz_set_d(value, source)
    }
}

extension IntMP: CustomStringConvertible {
    public var description: String {
        return _MPZ.string(value, base: 10)
    }
}

extension IntMP: CustomDebugStringConvertible {
    public var debugDescription: String {
        let m = magnitude
        let str = withExtendedLifetime(m) { _MPZ.string(m.value, base: 16) }
        if mpz_sgn(value) < 0 {
            return "-0x\(str)"
        } else {
            return "0x\(str)"
        }
    }
}

extension IntMP: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        if mpz_set_str(self.value, description, 0) != 0 {
            return nil
        }
    }
}

extension IntMP: RandomAccessCollection {
    public typealias Element = Int

    public typealias Index = Int

    @inlinable
    public subscript(position: Index) -> Element {
        get {
            return Int(mpz_tstbit(value, UInt(position)))
        }
        set(newValue) {
            makeUnique()
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

extension IntMP: MutableCollection {
}
