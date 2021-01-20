//
//  Self.swift
//  
//
//  Created by José María Gómez Cama on 16/01/2021.
//

import Foundation
import Cminigmp

public struct MPQ {
    public typealias Word = mp_limb_t
    public typealias Words = [Word]
    internal typealias bWord = UnsafeMutableBufferPointer<Word>
    internal typealias pMPQ = UnsafeMutablePointer<mpq_t>
    internal typealias bMPQ = UnsafeMutableBufferPointer<mpq_t>

    @usableFromInline static let wordBits = MemoryLayout<Word>.size * 8
    @usableFromInline internal static let mask = ~Word(0)

    @usableFromInline internal var value =
        pMPQ.allocate(capacity: 1)

    internal var limbs: (num: bWord, den: bWord) {
        return (bWord(start: value[0]._mp_num._mp_d,
                      count: abs(Int(value[0]._mp_num._mp_size))),
                bWord(start: value[0]._mp_den._mp_d,
                      count: abs(Int(value[0]._mp_den._mp_size))))
    }

    @inlinable
    init() {
        mpq_init(value)
    }

    @inlinable
    public init(num: IntegerLiteralType, den: IntegerLiteralType) {
        mpq_init(value)
        if num.signum() == den.signum() {
            mpq_set_ui(value, UInt(abs(num)), UInt(abs(den)))
        } else {
            mpq_set_si(value, -Int(abs(num)), UInt(abs(den)))
        }
    }

    @inlinable
    public init(val: MPZ) {
        mpq_init(value)
        mpq_set_z(value, val.value)
    }

    @inlinable
    public init(num: MPZ, den: MPZ) {
        mpq_init(value)
        mpq_set_z(value, num.value)
        mpq_set_den(value, den.value)
    }

    @usableFromInline
    static internal func toPointer<T> (pointee value: T) -> UnsafeMutablePointer<T>{
        let pointer =  UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: value)
        return pointer
    }

    @inlinable
    public var num: MPZ {
        let num = MPQ.toPointer(pointee: value[0]._mp_num)
        return MPZ(mpz: MPZ.bMPZ(start: num, count: 1))!
    }

    @inlinable
    public var den: MPZ {
        let den = MPQ.toPointer(pointee: value[0]._mp_den)
        return MPZ(mpz: MPZ.bMPZ(start: den, count: 1))!
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger {
        let si = source as? Int
        if si != nil {
            mpq_init(value)
            mpq_set_si(value, si!, 1)
            return
        }
        let su = source as? UInt
        if su != nil {
            mpq_init(value)
            mpq_set_ui(value, su!, 1)
            return
        }
        let sz = source as? MPZ
        if sz != nil {
            mpq_init(value)
            mpq_set_z(value, sz!.value)
            return
        }
        return nil
    }

    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        let d = source as? Double
        if d != nil {
            mpq_init(value)
            mpq_set_d(value, d!)
            return
        }
        return nil
    }

    public init<T>(_ source: T) where T : BinaryFloatingPoint {
        let d = source as? Double
        if d != nil {
            mpq_init(value)
            mpq_set_d(value, d!)
            return
        }
        fatalError("Not implemented")
    }

    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger {
        let sz = source as? MPZ
        if sz != nil {
            mpq_init(value)
            mpq_set_z(value, sz!.value)
        }
        if T.isSigned {
            let si = Int(truncatingIfNeeded: source)
            mpq_init(value)
            mpq_set_si(value, si, 1)
        } else {
            let su = UInt(truncatingIfNeeded: source)
            mpq_init(value)
            mpq_set_ui(value, su, 1)
        }
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        let str = value.cString(using: .ascii)!
        mpq_init(self.value)
        mpq_set_str(self.value, str, 0)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType, base: Int) {
        let str = value.cString(using: .ascii)!
        mpq_init(self.value)
        mpq_set_str(self.value, str, Int32(base))
    }

    @inlinable
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let result = Self()
        mpq_div_2exp(result.value, lhs.value, UInt(rhs))
        return result
    }

    @inlinable
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        mpq_div_2exp(lhs.value, lhs.value, UInt(rhs))
    }

    @inlinable
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let result = Self()
        mpq_mul_2exp(result.value, lhs.value, UInt(rhs))
        return result
    }

    @inlinable
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        mpq_mul_2exp(lhs.value, lhs.value, UInt(rhs))
    }
}

extension MPQ: Comparable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return mpq_cmp(lhs.value, rhs.value) == 0
    }

    @inlinable
    public static func ==<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpq_cmp(lhs.value, Self(rhs).value) == 0
    }

    @inlinable
    public static func ==<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpq_cmp(Self(lhs).value, rhs.value) == 0
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return mpq_cmp(lhs.value, rhs.value) < 0
    }

    @inlinable
    public static func <<RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpq_cmp(lhs.value, Self(rhs).value) < 0
    }

    @inlinable
    public static func <<LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpq_cmp(Self(lhs).value, rhs.value) < 0
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return mpq_cmp(lhs.value, rhs.value) > 0
    }

    @inlinable
    public static func ><RHS> (lhs: Self, rhs: RHS) -> Bool where RHS : BinaryInteger {
        return mpq_cmp(lhs.value, Self(rhs).value) > 0
    }

    @inlinable
    public static func ><LHS> (lhs: LHS, rhs: Self) -> Bool where LHS : BinaryInteger {
        return mpq_cmp(Self(lhs).value, rhs.value) > 0
    }
}

extension MPQ: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        mpq_init(self.value)
        mpq_set_si(self.value, value, 1)
    }
}

extension MPQ: AdditiveArithmetic {
    public static var zero: Self{
        return Self()
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpq_add(result.value, lhs.value, rhs.value)
        return result
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpq_sub(result.value, lhs.value, rhs.value)
        return result
    }
}

extension MPQ: Numeric {
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
        mpq_mul(lhs.value, lhs.value, rhs.value)
    }

}

extension MPQ: SignedNumeric {
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

    public func negate() {
        mpq_neg(value, value)
    }

    @inlinable
    public func signum() -> Self {
        return Self(mpq_sgn(value))
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        let result = Self()
        mpq_div(result.value, lhs.value, rhs.value)
        return result
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        mpq_div(lhs.value, lhs.value, rhs.value)
    }
}

extension MPQ: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension MPQ: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
}

extension MPQ: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public init(floatLiteral source: FloatLiteralType) {
        mpq_init(value)
        mpq_set_d(value, source)
    }
}

extension MPQ: CustomStringConvertible {
    public var description: String {
        let base: Int32 = 10
        let size = mpz_sizeinbase(MPQ.toPointer(pointee: value[0]._mp_num), base)
            + mpz_sizeinbase(MPQ.toPointer(pointee: value[0]._mp_den), base) + 3
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
        _ = mpq_get_str(buffer, base, value)
        let str = String(cString: buffer)
        buffer.deallocate()
        return str
    }
}

extension MPQ: CustomDebugStringConvertible {
    public var debugDescription: String {
        let base: Int32 = 10
        let size = mpz_sizeinbase(MPQ.toPointer(pointee: value[0]._mp_num), base)
            + mpz_sizeinbase(MPQ.toPointer(pointee: value[0]._mp_den), base) + 3
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
        _ = mpq_get_str(buffer, 16, magnitude.value)
        let str = String(cString: buffer)
        buffer.deallocate()
        if mpq_sgn(value) < 0 {
            return "MPQ(\"-0x\(str)\")"
        } else {
            return "MPQ(\"0x\(str)\")"
        }
    }
}
