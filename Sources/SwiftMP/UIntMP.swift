//
//  UIntMP.swift
//
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cmpfr

/// Arbitrary-precision unsigned integer (GMP `mpz_t`) with value semantics.
///
/// Values built with `init(truncatingIfNeeded:)` from a negative source, or
/// with `~`, keep a negative internal value. It stands for the two's-complement
/// bit pattern of `bitWidth` bits, and comparisons wrap both operands to the
/// wider of their widths.
public struct UIntMP: Sendable {
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    @usableFromInline internal typealias pMPU = UnsafeMutablePointer<mpz_t>
    @usableFromInline static let wordBits = MemoryLayout<Word>.size * 8
    @usableFromInline internal static let wordMask = ~Word(0)

    @usableFromInline internal var storage = _MPZStorage()

    /// The C value. Read it freely; call `makeUnique()` before writing to it.
    @usableFromInline internal var value: pMPU {
        return storage.pointer
    }

    /// Copy-on-write: gives this value its own storage before it is modified.
    @inlinable
    internal mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = _MPZStorage(copying: storage)
        }
    }

    /// Keeps the low `bits` bits (two's complement for a negative internal value).
    @usableFromInline
    internal mutating func wrap(_ bits: Int) {
        makeUnique()
        mpz_fdiv_r_2exp(value, value, UInt(bits))
    }

    /// `2^bitWidth - 1`.
    @inlinable
    public var mask: UIntMP {
        let wrap = UIntMP()
        mpz_setbit(wrap.value, UInt(bitWidth))
        mpz_sub_ui(wrap.value, wrap.value, 1)
        return wrap
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
        mpz_set_ui(value, val)
    }

    /// Nil when `source` is negative.
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        _MPZ.set(value, source)
        if mpz_sgn(value) < 0 {
            return nil
        }
    }

    /// Nil when `source` is negative, not finite or not integral.
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        guard _MPZ.isIntegral(source), source >= 0 else {
            return nil
        }
        _MPZ.setTruncating(value, source)
    }

    /// Truncates toward zero. Traps when the result is negative, NaN or infinite.
    @inlinable
    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        _MPZ.setTruncating(value, source)
        precondition(mpz_sgn(value) >= 0, "arithmetic overflow")
    }

    /// Traps when `source` is negative.
    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        _MPZ.set(value, source)
        precondition(mpz_sgn(value) >= 0, "arithmetic overflow")
    }

    /// Negative values become zero.
    @inlinable
    public init<T>(clamping val: T) where T : BinaryInteger {
        _MPZ.set(value, val)
        if mpz_sgn(value) < 0 {
            mpz_set_ui(value, 0)
        }
    }

    /// Keeps the source value; a negative source stands for its two's-complement
    /// bit pattern (see the type documentation).
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
        precondition(mpz_sgn(self.value) >= 0, "arithmetic overflow")
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

    /// Number of ones in the low `bitWidth` bits.
    @inlinable
    public var nonzeroBitCount: Int {
        var u = self
        u.wrap(bitWidth)
        return withExtendedLifetime(u) {
            Int(truncatingIfNeeded: mpz_popcount(u.value))
        }
    }

    /// Both operands wrapped to the wider of their widths.
    @usableFromInline
    internal static func compare(_ lhs: Self, _ rhs: Self) -> Int32 {
        if mpz_sgn(lhs.value) >= 0 && mpz_sgn(rhs.value) >= 0 {
            // Both already fit in their widths: nothing to wrap.
            return mpz_cmp(lhs.value, rhs.value)
        }
        let size = Swift.max(lhs.bitWidth, rhs.bitWidth)
        var l = lhs
        var r = rhs
        l.wrap(size)
        r.wrap(size)
        return withExtendedLifetime((l, r)) {
            mpz_cmp(l.value, r.value)
        }
    }
}

extension UIntMP: Comparable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return compare(lhs, rhs) == 0
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return compare(lhs, rhs) < 0
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return compare(lhs, rhs) > 0
    }
}

extension UIntMP: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt
}

extension UIntMP: AdditiveArithmetic {
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
        precondition(mpz_sgn(result.value) >= 0, "arithmetic overflow")
        return result
    }

    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpz_sub(lhs.value, lhs.value, rhs.value)
        precondition(mpz_sgn(lhs.value) >= 0, "arithmetic overflow")
    }
}

extension UIntMP: Numeric {
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

extension UIntMP: Hashable {
    /// Hashes a canonical form so that values equal under `==` (which wraps to
    /// the wider width) hash alike: wrap to `bitWidth`, then drop leading ones
    /// while the bit below them is also one (`0b1101` and `0b101` both stand
    /// for the two's-complement value -3).
    @inlinable
    public func hash(into hasher: inout Hasher) {
        var c = self
        c.wrap(bitWidth)
        withExtendedLifetime(c) {
            var width = mpz_sizeinbase(c.value, 2)
            while width > 2 && mpz_tstbit(c.value, UInt(width - 2)) != 0 {
                mpz_clrbit(c.value, UInt(width - 1))
                width -= 1
            }
            _MPZ.hash(c.value, into: &hasher)
        }
    }
}

extension UIntMP: BinaryInteger {
    @inlinable
    static public var isSigned: Bool {
        return false
    }

    @inlinable
    public func signum() -> Self {
        return mpz_sgn(value) == 0 ? Self() : Self(integerLiteral: 1)
    }

    @inlinable
    public func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        let quotient = Self()
        let reminder = Self()
        mpz_tdiv_qr(quotient.value, reminder.value, value, rhs.value)
        return (quotient, reminder)
    }

    /// Words of the low `bitWidth` bits, least significant first.
    @inlinable
    public var words: [Word] {
        let count = (bitWidth + Self.wordBits - 1) / Self.wordBits
        return _MPZ.words(value, count: count)
    }

    @inlinable
    public var bitWidth: Int {
        return mpz_sizeinbase(value, 2) + (mpz_sgn(value) < 0 ? 1 : 0)
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

    /// Shift right. A negative count shifts left.
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

extension UIntMP: UnsignedInteger {
}

extension UIntMP: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension UIntMP: CustomStringConvertible {
    public var description: String {
        return _MPZ.string(value, base: 10)
    }
}

extension UIntMP: CustomDebugStringConvertible {
    public var debugDescription: String {
        var u = self
        u.wrap(bitWidth)
        let str = withExtendedLifetime(u) { _MPZ.string(u.value, base: 16) }
        return "0x\(str)"
    }
}

extension UIntMP: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        if mpz_set_str(self.value, description, 0) != 0 {
            return nil
        }
        if mpz_sgn(self.value) < 0 {
            return nil
        }
    }
}

extension UIntMP: RandomAccessCollection {
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

extension UIntMP: MutableCollection {
}
