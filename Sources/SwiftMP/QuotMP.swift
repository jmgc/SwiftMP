//
//  QuotMP.swift
//
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cmpfr

/// Arbitrary-precision rational number (GMP `mpq_t`) with value semantics.
/// Values are always kept in canonical form (lowest terms, positive denominator).
public struct QuotMP: Sendable {
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    @usableFromInline internal typealias pMPQ = UnsafeMutablePointer<mpq_t>

    @usableFromInline static let wordBits = MemoryLayout<Word>.size * 8
    @usableFromInline internal static let mask = ~Word(0)

    @usableFromInline internal var storage = _MPQStorage()

    /// The C value. Read it freely; call `makeUnique()` before writing to it.
    @usableFromInline internal var value: pMPQ {
        return storage.pointer
    }

    /// Copy-on-write: gives this value its own storage before it is modified.
    @inlinable
    internal mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = _MPQStorage(copying: storage)
        }
    }

    @inlinable
    init() {
    }

    @inlinable
    public init(num: IntegerLiteralType, den: IntegerLiteralType) {
        precondition(den != 0, "Division by zero")
        _MPZ.set(storage.numerator, num)
        _MPZ.set(storage.denominator, den)
        mpq_canonicalize(value)
    }

    @inlinable
    public init(val: IntMP) {
        mpq_set_z(value, val.value)
    }

    @inlinable
    public init(num: IntMP, den: IntMP) {
        precondition(mpz_sgn(den.value) != 0, "Division by zero")
        mpz_set(storage.numerator, num.value)
        mpz_set(storage.denominator, den.value)
        mpq_canonicalize(value)
    }

    /// The numerator (carries the sign).
    @inlinable
    public var num: IntMP {
        let result = IntMP()
        mpz_set(result.value, storage.numerator)
        return result
    }

    /// The denominator (always positive).
    @inlinable
    public var den: IntMP {
        let result = IntMP()
        mpz_set(result.value, storage.denominator)
        return result
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(source)
    }

    /// Nil when `source` is NaN or infinite. Every finite binary floating-point
    /// value is an exact rational.
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        guard source.isFinite else {
            return nil
        }
        self.init(source)
    }

    /// Exact conversion. Traps on NaN or infinity.
    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        precondition(source.isFinite, "\(source) cannot be converted to a rational")
        if let d = source as? Double {
            mpq_set_d(value, d)
            return
        }
        if let f = source as? Float {
            mpq_set_d(value, Double(f))
            return
        }
        if let f = source as? FloatMP {
            // f = z * 2^e exactly.
            let z = IntMP()
            let e = mpfr_get_z_2exp(z.value, f.value)
            mpq_set_z(value, z.value)
            withExtendedLifetime(z) {}
            if mpfr_zero_p(f.value) == 0 {
                if e >= 0 {
                    mpq_mul_2exp(value, value, UInt(e))
                } else {
                    mpq_div_2exp(value, value, UInt(-e))
                }
            }
            return
        }
        // Other IEEE types (Float16, Float80): significand * 2^(exponent - bits).
        if source.isZero {
            return
        }
        let z = IntMP()
        _MPZ.set(z.value, source.significandBitPattern)
        var exponent = Int(source.exponent)
        if source.isNormal {
            mpz_setbit(z.value, UInt(T.significandBitCount))
        } else {
            exponent = Int(T.leastNormalMagnitude.exponent)
        }
        if source.sign == .minus {
            mpz_neg(z.value, z.value)
        }
        mpq_set_z(value, z.value)
        withExtendedLifetime(z) {}
        let shift = exponent - T.significandBitCount
        if shift >= 0 {
            mpq_mul_2exp(value, value, UInt(shift))
        } else {
            mpq_div_2exp(value, value, UInt(-shift))
        }
    }

    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        _MPZ.set(storage.numerator, source)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.init(stringLiteral: value, base: 0)
    }

    /// Parses `"n"` or `"n/d"` in `base` (0 = detect the prefix of each part).
    @inlinable
    public init(stringLiteral value: StringLiteralType, base: Int) {
        let ok = mpq_set_str(self.value, value, Int32(base)) == 0
            && mpz_sgn(storage.denominator) != 0
        precondition(ok, "Invalid rational literal: \(value)")
        mpq_canonicalize(self.value)
    }

    @inlinable
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        var result = lhs
        result >>= rhs
        return result
    }

    /// Divides by `2^rhs`. A negative count multiplies.
    @inlinable
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs.makeUnique()
        if rhs < (0 as RHS) {
            mpq_mul_2exp(lhs.value, lhs.value, UInt(rhs.magnitude))
        } else {
            mpq_div_2exp(lhs.value, lhs.value, UInt(rhs))
        }
    }

    @inlinable
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        var result = lhs
        result <<= rhs
        return result
    }

    /// Multiplies by `2^rhs`. A negative count divides.
    @inlinable
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs.makeUnique()
        if rhs < (0 as RHS) {
            mpq_div_2exp(lhs.value, lhs.value, UInt(rhs.magnitude))
        } else {
            mpq_mul_2exp(lhs.value, lhs.value, UInt(rhs))
        }
    }
}

extension QuotMP: Comparable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return mpq_equal(lhs.value, rhs.value) != 0
    }

    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpq_equal(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpq_equal(l.value, rhs.value) != 0 }
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return mpq_cmp(lhs.value, rhs.value) < 0
    }

    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpq_cmp(lhs.value, r.value) < 0 }
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpq_cmp(l.value, rhs.value) < 0 }
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return mpq_cmp(lhs.value, rhs.value) > 0
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpq_cmp(lhs.value, r.value) > 0 }
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpq_cmp(l.value, rhs.value) > 0 }
    }
}

extension QuotMP: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        mpq_set_si(self.value, value, 1)
    }
}

extension QuotMP: AdditiveArithmetic {
    public static var zero: Self {
        return Self()
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpq_add(result.value, lhs.value, rhs.value)
        return result
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpq_add(lhs.value, lhs.value, rhs.value)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpq_sub(result.value, lhs.value, rhs.value)
        return result
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpq_sub(lhs.value, lhs.value, rhs.value)
    }
}

extension QuotMP: Numeric {
    public typealias Magnitude = Self

    public var magnitude: Magnitude {
        let result = Self()
        mpq_abs(result.value, value)
        return result
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpq_mul(result.value, lhs.value, rhs.value)
        return result
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpq_mul(lhs.value, lhs.value, rhs.value)
    }

}

extension QuotMP: SignedNumeric {
    static public var isSigned: Bool {
        return true
    }

    public static prefix func +(_ x: Self) -> Self {
        return x
    }

    public static prefix func -(_ x: Self) -> Self {
        let result = Self()
        mpq_neg(result.value, x.value)
        return result
    }

    public mutating func negate() {
        makeUnique()
        mpq_neg(value, value)
    }

    @inlinable
    public func signum() -> Self {
        return Self(integerLiteral: Int(mpq_sgn(value)))
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        precondition(mpq_sgn(rhs.value) != 0, "Division by zero")
        let result = Self()
        mpq_div(result.value, lhs.value, rhs.value)
        return result
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        precondition(mpq_sgn(rhs.value) != 0, "Division by zero")
        lhs.makeUnique()
        mpq_div(lhs.value, lhs.value, rhs.value)
    }
}

extension QuotMP: Hashable {
    public func hash(into hasher: inout Hasher) {
        // Canonical form, so equal values have equal numerators and denominators.
        _MPZ.hash(storage.numerator, into: &hasher)
        _MPZ.hash(storage.denominator, into: &hasher)
    }
}

extension QuotMP: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension QuotMP: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    /// Exact value of the `Double` literal.
    public init(floatLiteral source: FloatLiteralType) {
        mpq_set_d(value, source)
    }
}

extension QuotMP: CustomStringConvertible {
    public var description: String {
        let base: Int32 = 10
        let size = mpz_sizeinbase(storage.numerator, base)
            + mpz_sizeinbase(storage.denominator, base) + 3
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: size + 1)
        defer { buffer.deallocate() }
        _ = mpq_get_str(buffer, base, value)
        return String(cString: buffer)
    }
}

extension QuotMP: CustomDebugStringConvertible {
    public var debugDescription: String {
        let base: Int32 = 16
        let m = magnitude
        let size = mpz_sizeinbase(storage.numerator, base)
            + mpz_sizeinbase(storage.denominator, base) + 3
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: size + 1)
        defer { buffer.deallocate() }
        withExtendedLifetime(m) {
            _ = mpq_get_str(buffer, base, m.value)
        }
        let str = String(cString: buffer)
        if mpq_sgn(value) < 0 {
            return "-0x\(str)"
        } else {
            return "0x\(str)"
        }
    }
}

extension QuotMP: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        if mpq_set_str(self.value, description, 0) != 0 {
            return nil
        }
        if mpz_sgn(storage.denominator) == 0 {
            return nil
        }
        mpq_canonicalize(self.value)
    }
}
