# SwiftMP

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjmgc%2FSwiftMP%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/jmgc/SwiftMP)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjmgc%2FSwiftMP%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/jmgc/SwiftMP)

Swift wrapper for the Mini-GMP and MPFR library.

It uses the Swift-numerics Real protocol for the MPFR type.

It uses the mini-gmp library to ensure that it can be compiled by the swift package
manager.

## Types

| Type     | Backed by | Swift protocols |
|----------|-----------|-----------------|
| `IntMP`  | `mpz_t`   | `SignedInteger`, `Hashable`, `Sendable` |
| `UIntMP` | `mpz_t`   | `UnsignedInteger`, `Hashable`, `Sendable` |
| `QuotMP` | `mpq_t`   | `SignedNumeric`, `Hashable`, `Sendable` |
| `FloatMP`| `mpfr_t`  | `BinaryFloatingPoint`, `Real`, `Hashable`, `Sendable` |

All four are value types: a copy is independent of the original. The C data is
shared between copies until one of them is modified (copy-on-write) and is
freed when the last copy goes away.

## Licensing

mini-gmp is under GNU license, see the Cmini-gmp package
mpfr is under GNU license, see the Cmpfr package
SwiftMP is under Apache license
