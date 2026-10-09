//
//  FloatMP.swift
//
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cmpfr
import RealModule

/// Arbitrary-precision binary floating point (MPFR `mpfr_t`) with value semantics.
/// New values use MPFR's default precision (`FloatMP.significandBitCount`).
public struct FloatMP: Sendable {
    @usableFromInline internal typealias Round = mpfr_rnd_t
    public typealias Precission = mpfr_prec_t

    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    @usableFromInline internal typealias pMPFR = UnsafeMutablePointer<mpfr_t>

    @usableFromInline static let wordBits = mp_bits_per_limb
    @usableFromInline internal static let mask = ~Word(0)

    @usableFromInline internal var storage = _MPFRStorage()

    /// The C value. Read it freely; call `makeUnique()` before writing to it.
    @usableFromInline internal var value: pMPFR {
        return storage.pointer
    }

    /// Copy-on-write: gives this value its own storage before it is modified.
    @inlinable
    internal mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = _MPFRStorage(copying: storage)
        }
    }

    /* round to nearest, with ties to even */
    @usableFromInline internal static let nearest: Round = MPFR_RNDN
    /* round toward zero */
    @usableFromInline internal static let toward_zero: Round = MPFR_RNDZ
    /* round toward +Inf */
    @usableFromInline internal static let toward_plus_inf: Round = MPFR_RNDU
    /* round toward -Inf */
    @usableFromInline internal static let toward_minus_inf: Round = MPFR_RNDD
    /* round away from zero */
    @usableFromInline internal static let away: Round = MPFR_RNDA
    /* faithful rounding */
    @usableFromInline internal static let faithful: Round = MPFR_RNDF
    /* round to nearest, with ties away from zero (mpfr_round) */
    @usableFromInline internal static let nearest_with_ties_away: Round = MPFR_RNDNA

    public var rounding: FloatingPointRoundingRule = .from(mpfr_get_default_rounding_mode())

    @inlinable
    init() {
    }

    @inlinable
    init(precission: Precission) {
        storage = _MPFRStorage(precision: precission)
    }

    @inlinable
    public init(_ val: IntegerLiteralType) {
        mpfr_set_si(value, val, rounding.rule)
    }

    @inlinable
    public init(_ val: IntMP) {
        mpfr_set_z(value, val.value, rounding.rule)
    }

    @inlinable
    public init(_ val: QuotMP) {
        let num = val.num
        let den = val.den
        mpfr_set_z(value, num.value, rounding.rule)
        mpfr_div_z(value, value, den.value, rounding.rule)
        withExtendedLifetime((num, den)) {}
    }

    /// Sets the value from an integer and returns MPFR's ternary result
    /// (0 when exact).
    @usableFromInline
    internal func _set<T: BinaryInteger>(integer source: T) -> Int32 {
        let z = IntMP(source)
        return withExtendedLifetime(z) {
            mpfr_set_z(value, z.value, rounding.rule)
        }
    }

    /// Sets the value from a binary floating-point value and returns MPFR's
    /// ternary result (0 when exact).
    @usableFromInline
    internal func _set<T: BinaryFloatingPoint>(float source: T) -> Int32 {
        if let f = source as? FloatMP {
            return mpfr_set(value, f.value, rounding.rule)
        }
        if let d = source as? Double {
            return mpfr_set_d(value, d, rounding.rule)
        }
        if let f = source as? Float {
            return mpfr_set_flt(value, f, rounding.rule)
        }
#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
        if let l = source as? Float80 {
            return mpfr_set_ld(value, l, rounding.rule)
        }
#endif
        // Any other IEEE type: (implicit bit + significand) * 2^(exponent - bits).
        if source.isNaN {
            mpfr_set_nan(value)
            return 0
        }
        let sign: Int32 = source.sign == .minus ? -1 : 1
        if source.isInfinite {
            mpfr_set_inf(value, sign)
            return 0
        }
        if source.isZero {
            mpfr_set_zero(value, sign)
            return 0
        }
        let z = IntMP()
        _MPZ.set(z.value, source.significandBitPattern)
        var exponent = Int(source.exponent)
        if source.isNormal {
            mpz_setbit(z.value, UInt(T.significandBitCount))
        } else {
            exponent = Int(T.leastNormalMagnitude.exponent)
        }
        if sign < 0 {
            mpz_neg(z.value, z.value)
        }
        let ternary = mpfr_set_z_2exp(value, z.value,
                                      exponent - T.significandBitCount,
                                      rounding.rule)
        withExtendedLifetime(z) {}
        return ternary
    }

    /// Nil when the integer cannot be represented exactly at the default precision.
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        if _set(integer: source) != 0 {
            return nil
        }
    }

    /// Nil when `source` cannot be represented exactly at the default precision.
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        if _set(float: source) != 0 {
            return nil
        }
    }

    /// Rounds `source` to the default precision with the current rounding mode.
    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        _ = _set(float: source)
    }

    /// Rounds `source` to the default precision with the current rounding mode.
    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        _ = _set(integer: source)
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
            mpfr_mul_2exp(lhs.value, lhs.value, UInt(rhs.magnitude), lhs.rounding.rule)
        } else {
            mpfr_div_2exp(lhs.value, lhs.value, UInt(rhs), lhs.rounding.rule)
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
            mpfr_div_2exp(lhs.value, lhs.value, UInt(rhs.magnitude), lhs.rounding.rule)
        } else {
            mpfr_mul_2exp(lhs.value, lhs.value, UInt(rhs), lhs.rounding.rule)
        }
    }
}

extension FloatingPointRoundingRule {
    @usableFromInline
    internal var rule: FloatMP.Round {
        switch self {
        case .toNearestOrEven:
            return FloatMP.nearest
        case .towardZero:
            return FloatMP.toward_zero
        case .up:
            return FloatMP.toward_plus_inf
        case .down:
            return FloatMP.toward_minus_inf
        case .toNearestOrAwayFromZero:
            return FloatMP.nearest_with_ties_away
        case .awayFromZero:
            return FloatMP.away
        default:
            fatalError("Unknown rounding rule: \(self)")
        }
    }

    @usableFromInline
    internal static func from(_ rule: FloatMP.Round) -> Self {
        switch rule {
        case FloatMP.nearest:
            return .toNearestOrEven
        case FloatMP.toward_zero:
            return .towardZero
        case FloatMP.toward_plus_inf:
            return .up
        case FloatMP.toward_minus_inf:
            return .down
        case FloatMP.nearest_with_ties_away:
            return .toNearestOrAwayFromZero
        case FloatMP.away:
            return .awayFromZero
        default:
            fatalError("Unknown rounding rule: \(rule)")
        }
    }
}

/// IEEE comparisons: NaN is unordered and never equal, -0 == +0.
extension FloatMP: Comparable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return mpfr_equal_p(lhs.value, rhs.value) != 0
    }

    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpfr_equal_p(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpfr_equal_p(l.value, rhs.value) != 0 }
    }

    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryFloatingPoint {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpfr_equal_p(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryFloatingPoint {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpfr_equal_p(l.value, rhs.value) != 0 }
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return mpfr_less_p(lhs.value, rhs.value) != 0
    }

    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpfr_less_p(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpfr_less_p(l.value, rhs.value) != 0 }
    }

    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryFloatingPoint {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpfr_less_p(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryFloatingPoint {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpfr_less_p(l.value, rhs.value) != 0 }
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return mpfr_greater_p(lhs.value, rhs.value) != 0
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpfr_greater_p(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpfr_greater_p(l.value, rhs.value) != 0 }
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryFloatingPoint {
        let r = Self(rhs)
        return withExtendedLifetime(r) { mpfr_greater_p(lhs.value, r.value) != 0 }
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryFloatingPoint {
        let l = Self(lhs)
        return withExtendedLifetime(l) { mpfr_greater_p(l.value, rhs.value) != 0 }
    }
}

extension FloatMP: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        mpfr_set_si(self.value, value, rounding.rule)
    }
}

extension FloatMP: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public init(floatLiteral value: FloatLiteralType) {
        mpfr_set_d(self.value, value, rounding.rule)
    }
}

extension FloatMP: AdditiveArithmetic {
    public static var zero: Self {
        return Self()
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpfr_add(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpfr_add(lhs.value, lhs.value, rhs.value, lhs.rounding.rule)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpfr_sub(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpfr_sub(lhs.value, lhs.value, rhs.value, lhs.rounding.rule)
    }
}

extension FloatMP: Numeric {
    public typealias Magnitude = Self

    public var magnitude: Magnitude {
        let result = Self()
        mpfr_abs(result.value, value, rounding.rule)
        return result
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpfr_mul(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.makeUnique()
        mpfr_mul(lhs.value, lhs.value, rhs.value, lhs.rounding.rule)
    }
}

extension FloatMP: SignedNumeric {
    static public var isSigned: Bool {
        return true
    }

    public static prefix func +(_ x: Self) -> Self {
        return x
    }

    public static prefix func -(_ x: Self) -> Self {
        let result = Self()
        mpfr_neg(result.value, x.value, x.rounding.rule)
        return result
    }

    public mutating func negate() {
        makeUnique()
        mpfr_neg(value, value, rounding.rule)
    }

    @inlinable
    public func signum() -> Self {
        return Self(integerLiteral: Int(mpfr_sgn(value)))
    }
}

extension FloatMP: Hashable {
    /// Hashes the exact value independently of the precision, so values equal
    /// under `==` hash alike (+0 and -0 included).
    public func hash(into hasher: inout Hasher) {
        if mpfr_nan_p(value) != 0 {
            hasher.combine(0 as UInt8)
            return
        }
        if mpfr_inf_p(value) != 0 {
            hasher.combine(1 as UInt8)
            hasher.combine(mpfr_signbit(value) != 0)
            return
        }
        if mpfr_zero_p(value) != 0 {
            hasher.combine(2 as UInt8)
            return
        }
        // value = z * 2^e; remove the trailing zero bits of z.
        let z = IntMP()
        var e = mpfr_get_z_2exp(z.value, value)
        let tz = mpz_scan1(z.value, 0)
        mpz_fdiv_q_2exp(z.value, z.value, tz)
        e += mpfr_exp_t(tz)
        hasher.combine(3 as UInt8)
        hasher.combine(e)
        _MPZ.hash(z.value, into: &hasher)
        withExtendedLifetime(z) {}
    }
}

extension FloatMP: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.init(stringLiteral: value, base: 0)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType, base: Int) {
        let ok = mpfr_set_str(self.value, value, Int32(base), rounding.rule) == 0
        precondition(ok, "Invalid floating-point literal: \(value)")
    }
}

extension FloatMP: BinaryFloatingPoint {
    public typealias RawSignificand = UIntMP

    public typealias RawExponent = mpfr_uexp_t

    @inlinable
    public init(_ val: Float) {
        mpfr_set_flt(value, val, rounding.rule)
    }

    @inlinable
    public init(_ val: Double) {
        mpfr_set_d(value, val, rounding.rule)
    }

#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
    @inlinable
    public init(_ val: Float80) {
        mpfr_set_ld(value, val, rounding.rule)
    }
#endif

    public var binade: Self {
        let two = FloatMP(mpfr_signbit(value) != 0 ? -2 : 2)
        mpfr_set_exp(two.value, mpfr_get_exp(value))
        return two
    }

    public init(sign: FloatingPointSign, exponentBitPattern: mpfr_uexp_t, significandBitPattern: UIntMP) {
        let exp = Exponent(truncatingIfNeeded: exponentBitPattern)
        mpfr_set_z_2exp(value, significandBitPattern.value, exp, rounding.rule)
        if sign == .minus {
            mpfr_neg(value, value, rounding.rule)
        }
    }

    public static var exponentBitCount: Int {
        RawExponent.bitWidth
    }


    public var exponentBitPattern: RawExponent {
        let exp = mpfr_get_exp(value)
        return RawExponent(truncatingIfNeeded: exp)
    }

    /// Precision in bits. Setting it rounds the value to the new precision.
    public var significandWidth: Int {
        get {
            return mpfr_get_prec(value)
        } set (newValue) {
            makeUnique()
            mpfr_prec_round(value, newValue, rounding.rule)
        }
    }

    public var significandBitPattern: RawSignificand {
        let result = UIntMP()
        _ = mpfr_get_z_2exp(result.value, value)
        return result
    }

    /// MPFR's default precision, used by every new value.
    public static var significandBitCount: Int {
        get {
            return mpfr_get_default_prec()
        } set (newValue) {
            mpfr_set_default_prec(newValue)
        }
    }
}

extension FloatMP: FloatingPoint {
    public typealias Exponent = mpfr_exp_t

    public typealias Stride = FloatMP

    @inlinable
    public init(sign: FloatingPointSign, exponent: Exponent, significand: FloatMP) {
        mpfr_abs(value, significand.value, significand.rounding.rule)
        if sign == .minus {
            mpfr_neg(value, value, significand.rounding.rule)
        }
        if exponent > 0 {
            mpfr_mul_2exp(value, value, UInt(exponent), significand.rounding.rule)
        } else {
            mpfr_div_2exp(value, value, UInt(abs(exponent)), significand.rounding.rule)
        }
    }

    @inlinable
    public init(signOf sign: FloatMP, magnitudeOf mag: FloatMP) {
        mpfr_copysign(value, mag.value, sign.value, mag.rounding.rule)
    }

    public static var radix: Int {
        return 2
    }

    public static var nan: FloatMP {
        let result = Self()
        mpfr_set_nan(result.value)
        return result
    }

    public static var signalingNaN: FloatMP {
        let result = Self()
        mpfr_set_nan(result.value)
        mpfr_set_nanflag()
        return result
    }

    public static var infinity: FloatMP {
        let result = Self()
        mpfr_set_inf(result.value, 1)
        return result
    }

    public static var greatestFiniteMagnitude: FloatMP {
        fatalError("Not implemented")
    }

    public static var pi: FloatMP {
        let PI = Self()
        mpfr_const_pi(PI.value, PI.rounding.rule)
        return PI
    }

    public mutating func round(_ rule: FloatingPointRoundingRule) {
        makeUnique()
        mpfr_rint(value, value, rule.rule)
    }

    public var ulp: FloatMP {
        fatalError("Not implemented")
    }

    public static var leastNormalMagnitude: FloatMP {
        fatalError("Not implemented")
    }

    public static var leastNonzeroMagnitude: FloatMP {
        fatalError("Not implemented")
    }

    public var sign: FloatingPointSign {
        if mpfr_signbit(value) != 0 {
            return .minus
        }
        return .plus
    }

    public var exponent: Exponent {
        return mpfr_get_exp(value)
    }

    public var significand: FloatMP {
        fatalError("Not implemented")
    }

    public static func / (lhs: FloatMP, rhs: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_div(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }

    public static func /= (lhs: inout FloatMP, rhs: FloatMP) {
        lhs.makeUnique()
        mpfr_div(lhs.value, lhs.value, rhs.value, lhs.rounding.rule)
    }

    public mutating func formRemainder(dividingBy other: FloatMP) {
        makeUnique()
        mpfr_remainder(value, value, other.value, rounding.rule)
    }

    public mutating func formTruncatingRemainder(dividingBy other: FloatMP) {
        makeUnique()
        mpfr_fmod(value, value, other.value, rounding.rule)
    }

    public mutating func formSquareRoot() {
        makeUnique()
        mpfr_sqrt(value, value, rounding.rule)
    }

    public mutating func addProduct(_ lhs: FloatMP, _ rhs: FloatMP) {
        makeUnique()
        mpfr_fma(value, lhs.value, rhs.value, value, rounding.rule)
    }

    /// The next representable value at this value's precision.
    public var nextUp: FloatMP {
        var result = self
        result.makeUnique()
        mpfr_nextabove(result.value)
        return result
    }

    public func isEqual(to other: FloatMP) -> Bool {
        return mpfr_equal_p(value, other.value) != 0
    }

    public func isLess(than other: FloatMP) -> Bool {
        return mpfr_less_p(value, other.value) != 0
    }

    public func isLessThanOrEqualTo(_ other: FloatMP) -> Bool {
        return mpfr_lessequal_p(value, other.value) != 0
    }

    public func isTotallyOrdered(belowOrEqualTo other: FloatMP) -> Bool {
        return mpfr_total_order_p(value, other.value) != 0
    }

    public var isNormal: Bool {
        return mpfr_regular_p(value) != 0
    }

    public var isFinite: Bool {
        return mpfr_number_p(value) != 0
    }

    public var isZero: Bool {
        return mpfr_zero_p(value) != 0
    }

    public var isSubnormal: Bool {
        return false
    }

    public var isInfinite: Bool {
        return mpfr_inf_p(value) != 0
    }

    public var isNaN: Bool {
        return mpfr_nan_p(value) != 0
    }

    public var isSignalingNaN: Bool {
        return false
    }

    public var isCanonical: Bool {
        return true
    }

    public func distance(to other: Self) -> Self {
        let dist = Self()
        mpfr_sub(dist.value, other.value, value, self.rounding.rule)
        return dist
    }

    public func advanced(by n: Self) -> Self {
        let dist = Self()
        mpfr_add(dist.value, value, n.value, self.rounding.rule)
        return dist
    }
}

extension FloatMP: CustomStringConvertible {
    public var description: String {
        let base: Int32 = 10
        let size = max(mpfr_get_str_ndigits(base, mpfr_get_prec(value) + 2), 7)
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: size + 5)
        defer { buffer.deallocate() }
        var exp: Exponent = 0
        _ = mpfr_get_str(buffer, &exp, base, size, value, rounding.rule)
        var str = String(cString: buffer)
        if !isFinite {
            return str
        }
        let idx = str.startIndex
        if str[idx] == "-" {
            str.insert(contentsOf: ".", at: str.index(idx, offsetBy: 2))
        } else {
            str.insert(contentsOf: ".", at: str.index(after: idx))
        }
        exp -= 1
        if exp < 0 {
            str += "e\(exp)"
        } else {
            str += "e+\(exp)"
        }
        return str
    }
}

extension FloatMP: CustomDebugStringConvertible {
    public var debugDescription: String {
        let base: Int32 = 16
        let size = max(mpfr_get_str_ndigits(base, mpfr_get_prec(value) + 2), 7)
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: size + 5)
        defer { buffer.deallocate() }
        buffer.initialize(repeating: 122, count: size + 5)
        buffer[size] = 0
        var exp: Exponent = 0
        _ = mpfr_get_str(buffer, &exp, base, size, value, rounding.rule)
        var str = String(cString: buffer)
        if !isFinite {
            return str
        }
        var prefix: String
        if str.first == "-" {
            str.remove(at: str.startIndex)
            prefix = "-0x"
        } else {
            prefix = "0x"
        }
        str.insert(contentsOf: ".", at: str.index(after: str.startIndex))
        exp = 4*(exp - 1)
        if exp < 0 {
            str += "p\(exp)"
        } else {
            str += "p+\(exp)"
        }
        return prefix + str
    }
}

extension FloatMP: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        if mpfr_set_str(self.value, description, 0, rounding.rule) != 0 {
            return nil
        }
    }
}

extension FloatMP: Real {
    public static func atan2(y: FloatMP, x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_atan2(result.value, y.value, x.value, result.rounding.rule)
        return result
    }

    public static func erf(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_erf(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func erfc(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_erfc(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func exp2(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_exp2(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func hypot(_ x: FloatMP, _ y: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_hypot(result.value, x.value, y.value, result.rounding.rule)
        return result
    }

    public static func gamma(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_gamma(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log2(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_log2(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log10(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_log10(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func logGamma(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_gamma(result.value, x.value, result.rounding.rule)
        mpfr_log(result.value, result.value, result.rounding.rule)
        return result
    }

    public static func exp(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_exp(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func expMinusOne(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_expm1(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func cosh(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_cosh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func sinh(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_sinh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func tanh(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_tanh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func cos(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_cos(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func sin(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_sin(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func tan(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_tan(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_log(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log(onePlus x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_log1p(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func acosh(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_acosh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func asinh(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_asinh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func atanh(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_atanh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func acos(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_acos(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func asin(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_asin(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func atan(_ x: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_atan(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func pow(_ x: FloatMP, _ y: FloatMP) -> FloatMP {
        let result = Self()
        mpfr_pow(result.value, x.value, y.value, result.rounding.rule)
        return result
    }

    public static func pow(_ x: FloatMP, _ n: Int) -> FloatMP {
        let result = Self()
        mpfr_pow_si(result.value, x.value, n, result.rounding.rule)
        return result
    }

    public static func root(_ x: FloatMP, _ n: Int) -> FloatMP {
        let result = Self()
        if n < 0 {
            fatalError("Roots can only be calculated from positive numbers")
        }
        mpfr_rootn_ui(result.value, x.value, UInt(n), result.rounding.rule)
        return result
    }
}
