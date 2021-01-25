//
//  Self.swift
//  
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cmpfr
import RealModule

public struct MPFR {
    @usableFromInline internal typealias Round = mpfr_rnd_t
    public typealias Precission = mpfr_prec_t
    
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    internal typealias bByte = UnsafeMutableBufferPointer<UInt8>
    internal typealias pMPFR = UnsafeMutablePointer<mpfr_t>
    internal typealias bMPFR = UnsafeMutableBufferPointer<mpfr_t>
    
    @usableFromInline static let wordBits = mp_bits_per_limb
    @usableFromInline internal static let mask = ~Word(0)
    
    @usableFromInline internal var value = pMPFR.allocate(capacity: 1)
    
    @usableFromInline
    internal static func shift(_ size: Int32) -> Int {
        switch size {
        case 8:
            return 3
        case 16:
            return 4
        case 32:
            return 5
        case 64:
            return 6
        default:
            fatalError("Unknows integer size")
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

    internal var limbs: UnsafeMutableRawBufferPointer {
        let p = mpfr_custom_get_significand(value)
        let len = mpfr_custom_get_size(mpfr_get_prec(value))
        return UnsafeMutableRawBufferPointer(start: p, count: len)
    }
    
    @inlinable
    init() {
        mpfr_init(value)
        mpfr_set_zero(value, 1)
    }
    
    @inlinable
    init(precission: Precission) {
        mpfr_init2(value, precission)
        mpfr_set_zero(value, 1)
    }

    @inlinable
    public init(_ val: IntegerLiteralType) {
        mpfr_init(value)
        if val.signum() >= 0 {
            mpfr_set_ui(value, UInt(abs(val)), rounding.rule)
        } else {
            mpfr_set_si(value, Int(val), rounding.rule)
        }
    }
    
    @inlinable
    public init(_ val: MPZ) {
        mpfr_init(value)
        mpfr_set_z(value, val.value, rounding.rule)
    }
    
    @inlinable
    public init(_ val: MPQ) {
        let num = val.num.value
        let den = val.den.value
        mpfr_init(value)
        mpfr_set_z(value, num, rounding.rule)
        mpfr_div_z(value, value, den, rounding.rule)
    }
    
    @usableFromInline
    static internal func toPointer<T> (pointee value: T) -> UnsafeMutablePointer<T>{
        let pointer =  UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: value)
        return pointer
    }
    
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        let si = source as? Int
        if si != nil {
            mpfr_init(value)
            mpfr_set_si(value, si!, rounding.rule)
            return
        }
        let su = source as? UInt
        if su != nil {
            mpfr_init(value)
            mpfr_set_ui(value, su!, rounding.rule)
            return
        }
        let sz = source as? MPZ
        if sz != nil {
            mpfr_init(value)
            mpfr_set_z(value, sz!.value, rounding.rule)
            return
        }
        return nil
    }
    
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        let fr = source as? MPFR
        if fr != nil {
            mpfr_init(value)
            mpfr_set(value, fr!.value, rounding.rule)
            return
        }
        let d = source as? Double
        if d != nil {
            mpfr_init(value)
            mpfr_set_d(value, d!, rounding.rule)
            return
        }
        return nil
    }
    
    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        let fr = source as? MPFR
        if fr != nil {
            mpfr_init(value)
            mpfr_set(value, fr!.value, rounding.rule)
            return
        }
        let d = source as? Double
        if d != nil {
            mpfr_init(value)
            mpfr_set_d(value, d!, rounding.rule)
            return
        }
        fatalError("Not implemented")
    }
    
    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        let sz = source as? MPZ
        if sz != nil {
            mpfr_init(value)
            mpfr_set_z(value, sz!.value, rounding.rule)
        }
        if T.isSigned {
            let si = Int(truncatingIfNeeded: source)
            mpfr_init(value)
            mpfr_set_si(value, si, rounding.rule)
        } else {
            let su = UInt(truncatingIfNeeded: source)
            mpfr_init(value)
            mpfr_set_ui(value, su, rounding.rule)
        }
    }
    
    @inlinable
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let result = Self()
        mpfr_div_2exp(result.value, lhs.value, UInt(rhs), lhs.rounding.rule)
        return result
    }
    
    @inlinable
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        mpfr_div_2exp(lhs.value, lhs.value, UInt(rhs), lhs.rounding.rule)
    }
    
    @inlinable
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let result = Self()
        mpfr_mul_2exp(result.value, lhs.value, UInt(rhs), lhs.rounding.rule)
        return result
    }
    
    @inlinable
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        mpfr_mul_2exp(lhs.value, lhs.value, UInt(rhs), lhs.rounding.rule)
    }
}

extension FloatingPointRoundingRule {
    @usableFromInline
    internal var rule: MPFR.Round {
        switch self {
        case .toNearestOrEven:
            return MPFR.nearest
        case .towardZero:
            return MPFR.toward_zero
        case .up:
            return MPFR.toward_plus_inf
        case .down:
            return MPFR.toward_minus_inf
        case .toNearestOrAwayFromZero:
            return MPFR.nearest_with_ties_away
        case .awayFromZero:
            return MPFR.away
        default:
            fatalError("Unknown rounding rule: \(self)")
        }
    }

    @usableFromInline
    internal static func from(_ rule: MPFR.Round) -> Self {
        switch rule {
        case MPFR.nearest:
            return .toNearestOrEven
        case MPFR.toward_zero:
            return .towardZero
        case MPFR.toward_plus_inf:
            return .up
        case MPFR.toward_minus_inf:
            return .down
        case MPFR.nearest_with_ties_away:
            return .toNearestOrAwayFromZero
        case MPFR.away:
            return .awayFromZero
        default:
            fatalError("Unknown rounding rule: \(rule)")
        }
    }
}

extension MPFR: Comparable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return mpfr_cmp(lhs.value, rhs.value) == 0
    }
    
    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpfr_cmp(lhs.value, Self(rhs).value) == 0
    }
    
    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpfr_cmp(Self(lhs).value, rhs.value) == 0
    }
    
    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryFloatingPoint {
        return mpfr_cmp(lhs.value, Self(rhs).value) == 0
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryFloatingPoint {
        return mpfr_cmp(Self(lhs).value, rhs.value) == 0
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return mpfr_cmp(lhs.value, rhs.value) < 0
    }
    
    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpfr_cmp(lhs.value, Self(rhs).value) < 0
    }
    
    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpfr_cmp(Self(lhs).value, rhs.value) < 0
    }
    
    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryFloatingPoint {
        return mpfr_cmp(lhs.value, Self(rhs).value) < 0
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryFloatingPoint {
        return mpfr_cmp(Self(lhs).value, rhs.value) < 0
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return mpfr_cmp(lhs.value, rhs.value) > 0
    }
    
    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpfr_cmp(lhs.value, Self(rhs).value) > 0
    }
    
    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpfr_cmp(Self(lhs).value, rhs.value) > 0
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryFloatingPoint {
        return mpfr_cmp(lhs.value, Self(rhs).value) > 0
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryFloatingPoint {
        return mpfr_cmp(Self(lhs).value, rhs.value) > 0
    }
}

extension MPFR: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        mpfr_init(self.value)
        mpfr_set_si(self.value, value, rounding.rule)
    }
}

extension MPFR: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public init(floatLiteral value: FloatLiteralType) {
        mpfr_init(self.value)
        mpfr_set_d(self.value, value, rounding.rule)
    }
}

extension MPFR: AdditiveArithmetic {
    public static var zero: Self{
        return Self()
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpfr_add(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpfr_sub(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }
}

extension MPFR: Numeric {
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
        mpfr_mul(lhs.value, lhs.value, rhs.value, lhs.rounding.rule)
    }
}

extension MPFR: SignedNumeric {
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
    
    public func negate() {
        mpfr_neg(value, value, rounding.rule)
    }
    
    @inlinable
    public func signum() -> Self {
        return Self(mpfr_sgn(value))
    }
}

extension MPFR: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension MPFR: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        let str = value.cString(using: .ascii)!
        mpfr_init(self.value)
        mpfr_set_str(self.value, str, 0, rounding.rule)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType, base: Int) {
        let str = value.cString(using: .ascii)!
        mpfr_init(self.value)
        mpfr_set_str(self.value, str, Int32(base), rounding.rule)
    }
}

extension MPFR: BinaryFloatingPoint {
    public typealias RawSignificand = MPU

    public typealias RawExponent = mpfr_uexp_t

    @inlinable
    public init(_ val: Float) {
        mpfr_init(value)
        mpfr_set_flt(value, val, rounding.rule)
    }

    @inlinable
    public init(_ val: Double) {
        mpfr_init(value)
        mpfr_set_d(value, val, rounding.rule)
    }

    @inlinable
    public init(_ val: Float80) {
        mpfr_init(value)
        mpfr_set_ld(value, val, rounding.rule)
    }

    public var binade: Self {
        let two = MPFR(mpfr_signbit(value) != 0 ? -2 : 2)
        mpfr_set_exp(two.value, mpfr_get_exp(value))
        return two
    }

    public init(sign: FloatingPointSign, exponentBitPattern: mpfr_uexp_t, significandBitPattern: MPU) {
        let exp = Exponent(truncatingIfNeeded: exponentBitPattern)
        mpfr_set_z_2exp(value, significandBitPattern.value, exp, rounding.rule)
    }

    public static var exponentBitCount: Int {
        RawExponent.bitWidth
    }


    public var exponentBitPattern: RawExponent {
        let exp = mpfr_get_exp(value)
        return RawExponent(truncatingIfNeeded: exp)
    }

    public var significandWidth: Int {
        get {
            return mpfr_get_prec(value)
        } set (newValue) {
            mpfr_set_prec(value, newValue)
        }
    }

    public var significandBitPattern: RawSignificand {
        let result = MPU()
        _ = mpfr_get_z_2exp(result.value, value)
        return result
    }

    public static var significandBitCount: Int {
        get {
            return mpfr_get_default_prec()
        } set (newValue) {
            mpfr_set_default_prec(newValue)
        }
    }
}

extension MPFR: FloatingPoint {
    public typealias Exponent = mpfr_exp_t

    public typealias Stride = MPFR

    @inlinable
    public init(sign: FloatingPointSign, exponent: Exponent, significand: MPFR) {
        mpfr_init(value)
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
    public init(signOf sign: MPFR, magnitudeOf mag: MPFR) {
        mpfr_init(value)
        mpfr_copysign(value, mag.value, sign.value, mag.rounding.rule)
    }

    public static var radix: Int {
        return 2
    }

    public static var nan: MPFR {
        let result = Self()
        mpfr_set_nan(result.value)
        return result
    }

    public static var signalingNaN: MPFR {
        let result = Self()
        mpfr_set_nan(result.value)
        mpfr_set_nanflag()
        return result
    }

    public static var infinity: MPFR {
        let result = Self()
        mpfr_set_inf(result.value, 1)
        return result
    }

    public static var greatestFiniteMagnitude: MPFR {
        fatalError("Not implemented")
    }

    public static var pi: MPFR {
        let PI = Self()
        mpfr_const_pi(PI.value, PI.rounding.rule)
        return PI
    }

    public mutating func round(_ rule: FloatingPointRoundingRule) {
        mpfr_rint(value, value, rule.rule)
    }

    public var ulp: MPFR {
        fatalError("Not implemented")
    }

    public static var leastNormalMagnitude: MPFR {
        fatalError("Not implemented")
    }

    public static var leastNonzeroMagnitude: MPFR {
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

    public var significand: MPFR {
        fatalError("Not implemented")
    }

    public static func / (lhs: MPFR, rhs: MPFR) -> MPFR {
        let result = Self()
        mpfr_div(result.value, lhs.value, rhs.value, result.rounding.rule)
        return result
    }

    public static func /= (lhs: inout MPFR, rhs: MPFR) {
        mpfr_div(lhs.value, lhs.value, rhs.value, lhs.rounding.rule)
    }

    public mutating func formRemainder(dividingBy other: MPFR) {
        fatalError("Not implemented")
    }

    public mutating func formTruncatingRemainder(dividingBy other: MPFR) {
        fatalError("Not implemented")
    }

    public mutating func formSquareRoot() {
        fatalError("Not implemented")
    }

    public mutating func addProduct(_ lhs: MPFR, _ rhs: MPFR) {
        fatalError("Not implemented")
    }

    public var nextUp: MPFR {
        fatalError("Not implemented")
    }

    public func isEqual(to other: MPFR) -> Bool {
        fatalError("Not implemented")
    }

    public func isLess(than other: MPFR) -> Bool {
        fatalError("Not implemented")
    }

    public func isLessThanOrEqualTo(_ other: MPFR) -> Bool {
        fatalError("Not implemented")
    }

    public func isTotallyOrdered(belowOrEqualTo other: MPFR) -> Bool {
        fatalError("Not implemented")
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
        mpfr_sub(dist.value, value, other.value, self.rounding.rule)
        return dist
    }

    public func advanced(by n: Self) -> Self {
        let dist = Self()
        mpfr_add(dist.value, value, n.value, self.rounding.rule)
        return dist
    }
}

extension MPFR: CustomStringConvertible {
    public var description: String {
        let base: Int32 = 10
        let size = max(mpfr_get_str_ndigits(base, mpfr_get_prec(value) + 2), 7)
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size + 5)
        var exp: Exponent = 0
        _ = mpfr_get_str(buffer, &exp, base, size, value, rounding.rule)
        var str = String(cString: buffer)
        buffer.deallocate()
        let idx = str.startIndex
        if str[idx] == "-" {
            str.insert(contentsOf: ".", at: str.index(idx, offsetBy: 2))
        } else {
            str.insert(contentsOf: ".", at: str.index(after: idx))
        }
        exp -= 1
        if exp < 0 {
            str += "e-\(exp)"
        } else {
            str += "e+\(exp)"
        }
        return str
    }
}

extension MPFR: CustomDebugStringConvertible {
    public var debugDescription: String {
        let base: Int32 = 16
        let size = max(mpfr_get_str_ndigits(base, mpfr_get_prec(value) + 2), 7)
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size + 5)
        buffer.assign(repeating: 122, count: size)
        buffer[size] = 0
        var exp: Exponent = 0
        _ = mpfr_get_str(buffer, &exp, base, size, value, rounding.rule)
        var str = String(cString: buffer)
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
            str += "p-\(exp)"
        } else {
            str += "p+\(exp)"
        }
        return prefix + str
    }
}

extension MPFR: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        let str = description.cString(using: .ascii)!
        mpfr_init(self.value)
        if mpfr_set_str(self.value, str, 0, rounding.rule) != 0 {
            return nil
        }
    }
}

extension MPFR: Real {
    public static func atan2(y: MPFR, x: MPFR) -> MPFR {
        let result = Self()
        mpfr_atan2(result.value, y.value, x.value, result.rounding.rule)
        return result
    }

    public static func erf(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_erf(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func erfc(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_erfc(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func exp2(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_exp2(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func hypot(_ x: MPFR, _ y: MPFR) -> MPFR {
        let result = Self()
        mpfr_hypot(result.value, x.value, y.value, result.rounding.rule)
        return result
    }

    public static func gamma(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_gamma(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log2(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_log2(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log10(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_log10(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func logGamma(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_gamma(result.value, x.value, result.rounding.rule)
        mpfr_log(result.value, result.value, result.rounding.rule)
        return result
    }

    public static func exp(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_exp(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func expMinusOne(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_expm1(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func cosh(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_cosh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func sinh(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_sinh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func tanh(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_tanh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func cos(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_cos(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func sin(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_sin(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func tan(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_tan(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_log(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func log(onePlus x: MPFR) -> MPFR {
        let result = Self()
        mpfr_log1p(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func acosh(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_acosh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func asinh(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_asinh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func atanh(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_atanh(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func acos(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_acos(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func asin(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_asin(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func atan(_ x: MPFR) -> MPFR {
        let result = Self()
        mpfr_atan(result.value, x.value, result.rounding.rule)
        return result
    }

    public static func pow(_ x: MPFR, _ y: MPFR) -> MPFR {
        let result = Self()
        mpfr_pow(result.value, x.value, y.value, result.rounding.rule)
        return result
    }

    public static func pow(_ x: MPFR, _ n: Int) -> MPFR {
        let result = Self()
        mpfr_pow_si(result.value, x.value, n, result.rounding.rule)
        return result
    }

    public static func root(_ x: MPFR, _ n: Int) -> MPFR {
        let result = Self()
        if n < 0 {
            fatalError("Roots can only be calculated from positive numbers")
        }
        mpfr_rootn_ui(result.value, x.value, UInt(n), result.rounding.rule)
        return result
    }
}
