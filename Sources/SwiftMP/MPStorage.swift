//
//  MPStorage.swift
//
//
//  Reference-counted owners for the GMP/MPFR C structures.
//
//  `IntMP`, `UIntMP`, `QuotMP` and `FloatMP` are value types. Each one keeps
//  its C structure in one of the classes below and copies it only when a
//  shared value is about to be modified (copy-on-write). The class frees the
//  C structure in `deinit`, so temporaries no longer leak.
//
//  Rule for code in this module: a pointer obtained from `.value` is only
//  valid while the value that produced it is alive. Pointers taken from
//  parameters, `self` or a local that is used again afterwards are safe. For a
//  temporary (for example `Self(rhs).value`), bind it to a local and wrap the C
//  call in `withExtendedLifetime`.
//

import Foundation
import Cmpfr

// MARK: - Live-object counter (used by the memory tests)

@usableFromInline
internal enum _MPLiveCount {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _count = 0

    @usableFromInline
    internal static func increment() {
        lock.lock(); _count += 1; lock.unlock()
    }

    @usableFromInline
    internal static func decrement() {
        lock.lock(); _count -= 1; lock.unlock()
    }

    /// Number of C structures currently owned by SwiftMP values.
    internal static var current: Int {
        lock.lock(); defer { lock.unlock() }
        return _count
    }
}

// MARK: - mpz_t

@usableFromInline
internal final class _MPZStorage: @unchecked Sendable {
    @usableFromInline internal let pointer: UnsafeMutablePointer<mpz_t>

    @usableFromInline
    internal init() {
        pointer = UnsafeMutablePointer<mpz_t>.allocate(capacity: 1)
        mpz_init(pointer)
        _MPLiveCount.increment()
    }

    @usableFromInline
    internal init(copying other: _MPZStorage) {
        pointer = UnsafeMutablePointer<mpz_t>.allocate(capacity: 1)
        mpz_init_set(pointer, other.pointer)
        _MPLiveCount.increment()
    }

    deinit {
        mpz_clear(pointer)
        pointer.deallocate()
        _MPLiveCount.decrement()
    }
}

// MARK: - mpq_t

@usableFromInline
internal final class _MPQStorage: @unchecked Sendable {
    @usableFromInline internal let pointer: UnsafeMutablePointer<mpq_t>

    @usableFromInline
    internal init() {
        pointer = UnsafeMutablePointer<mpq_t>.allocate(capacity: 1)
        mpq_init(pointer)
        _MPLiveCount.increment()
    }

    @usableFromInline
    internal init(copying other: _MPQStorage) {
        pointer = UnsafeMutablePointer<mpq_t>.allocate(capacity: 1)
        mpq_init(pointer)
        mpq_set(pointer, other.pointer)
        _MPLiveCount.increment()
    }

    /// Pointer to the numerator (`mpq_numref`, a C macro Swift cannot import).
    @usableFromInline
    internal var numerator: UnsafeMutablePointer<mpz_t> {
        let offset = MemoryLayout<__mpq_struct>.offset(of: \__mpq_struct._mp_num)!
        return (UnsafeMutableRawPointer(pointer) + offset)
            .assumingMemoryBound(to: mpz_t.self)
    }

    /// Pointer to the denominator (`mpq_denref`).
    @usableFromInline
    internal var denominator: UnsafeMutablePointer<mpz_t> {
        let offset = MemoryLayout<__mpq_struct>.offset(of: \__mpq_struct._mp_den)!
        return (UnsafeMutableRawPointer(pointer) + offset)
            .assumingMemoryBound(to: mpz_t.self)
    }

    deinit {
        mpq_clear(pointer)
        pointer.deallocate()
        _MPLiveCount.decrement()
    }
}

// MARK: - mpfr_t

@usableFromInline
internal final class _MPFRStorage: @unchecked Sendable {
    @usableFromInline internal let pointer: UnsafeMutablePointer<mpfr_t>

    /// A new value set to +0 with the given precision (default precision when nil).
    @usableFromInline
    internal init(precision: mpfr_prec_t? = nil) {
        pointer = UnsafeMutablePointer<mpfr_t>.allocate(capacity: 1)
        mpfr_init2(pointer, precision ?? mpfr_get_default_prec())
        mpfr_set_zero(pointer, 1)
        _MPLiveCount.increment()
    }

    /// An exact copy, with the same precision.
    @usableFromInline
    internal init(copying other: _MPFRStorage) {
        pointer = UnsafeMutablePointer<mpfr_t>.allocate(capacity: 1)
        mpfr_init2(pointer, mpfr_get_prec(other.pointer))
        mpfr_set(pointer, other.pointer, MPFR_RNDN)
        _MPLiveCount.increment()
    }

    deinit {
        mpfr_clear(pointer)
        pointer.deallocate()
        _MPLiveCount.decrement()
    }
}

// MARK: - Helpers shared by the integer types

@usableFromInline
internal enum _MPZ {
    /// Sets `z` to the exact value of any `BinaryInteger`.
    @usableFromInline
    internal static func set<T: BinaryInteger>(_ z: UnsafeMutablePointer<mpz_t>, _ source: T) {
        if let v = source as? IntMP {
            mpz_set(z, v.value)
            return
        }
        if let v = source as? UIntMP {
            mpz_set(z, v.value)
            return
        }
        if let v = Int(exactly: source) {
            mpz_set_si(z, v)
            return
        }
        if let v = UInt(exactly: source) {
            mpz_set_ui(z, v)
            return
        }
        // Wider than one machine word: build from the magnitude's words.
        let negative = T.isSigned && source < (0 as T)
        let magnitude = source.magnitude
        mpz_set_ui(z, 0)
        for word in magnitude.words.reversed() {
            mpz_mul_2exp(z, z, UInt(UInt.bitWidth))
            mpz_add_ui(z, z, word)
        }
        if negative {
            mpz_neg(z, z)
        }
    }

    /// Sets `z` to `x` truncated toward zero. `x` must be finite.
    @usableFromInline
    internal static func setTruncating<T: BinaryFloatingPoint>(_ z: UnsafeMutablePointer<mpz_t>, _ x: T) {
        precondition(x.isFinite, "\(x) cannot be converted to an integer")
        if let f = x as? FloatMP {
            mpfr_get_z(z, f.value, MPFR_RNDZ)
            return
        }
        if let d = x as? Double {
            mpz_set_d(z, d)
            return
        }
        if let f = x as? Float {
            mpz_set_d(z, Double(f))
            return
        }
        let t = x.rounded(.towardZero)
        if t.isZero {
            mpz_set_ui(z, 0)
            return
        }
        // A non-zero integral value is always normal: significand 1.xxx.
        set(z, t.significandBitPattern)
        mpz_setbit(z, UInt(T.significandBitCount))
        let shift = Int(t.exponent) - T.significandBitCount
        if shift >= 0 {
            mpz_mul_2exp(z, z, UInt(shift))
        } else {
            mpz_tdiv_q_2exp(z, z, UInt(-shift))
        }
        if t.sign == .minus {
            mpz_neg(z, z)
        }
    }

    /// Whether a finite floating-point value has no fractional part.
    @usableFromInline
    internal static func isIntegral<T: BinaryFloatingPoint>(_ x: T) -> Bool {
        return x.isFinite && x.rounded(.towardZero) == x
    }

    /// Two's-complement words of `z`, sign-extended to `count` words.
    @usableFromInline
    internal static func words(_ z: UnsafeMutablePointer<mpz_t>, count: Int) -> [UInt] {
        let n = Swift.max(count, 1)
        let t = IntMP()
        // Floor remainder: the two's-complement bit pattern, always non-negative.
        mpz_fdiv_r_2exp(t.value, z, UInt(n * UInt.bitWidth))
        var result = [UInt](repeating: 0, count: n)
        withExtendedLifetime(t) {
            let used = Int(mpz_size(t.value))
            if used > 0 {
                let limbs = mpz_limbs_read(t.value)!
                for i in 0..<Swift.min(used, n) {
                    result[i] = UInt(limbs[i])
                }
            }
        }
        return result
    }

    /// Hashes the canonical (sign, limbs) form of `z`.
    @usableFromInline
    internal static func hash(_ z: UnsafeMutablePointer<mpz_t>, into hasher: inout Hasher) {
        hasher.combine(Int(mpz_sgn(z)))
        let used = Int(mpz_size(z))
        hasher.combine(used)
        if used > 0 {
            let limbs = mpz_limbs_read(z)!
            for i in 0..<used {
                hasher.combine(UInt(limbs[i]))
            }
        }
    }

    /// Decimal or hexadecimal digits of `z` (with a leading "-" when negative).
    @usableFromInline
    internal static func string(_ z: UnsafeMutablePointer<mpz_t>, base: Int32) -> String {
        let size = mpz_sizeinbase(z, base) + 2
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: size + 1)
        defer { buffer.deallocate() }
        _ = mpz_get_str(buffer, base, z)
        return String(cString: buffer)
    }
}
