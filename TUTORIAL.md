# SwiftMP tutorial

SwiftMP gives Swift four number types without a size limit:

| Type      | What it holds                         | Backed by       |
|-----------|---------------------------------------|-----------------|
| `IntMP`   | signed integers of any size           | GMP `mpz_t`     |
| `UIntMP`  | unsigned integers of any size         | GMP `mpz_t`     |
| `QuotMP`  | exact fractions (rational numbers)    | GMP `mpq_t`     |
| `FloatMP` | binary floating point, any precision  | MPFR `mpfr_t`   |

They behave like Swift's own numbers: they are value types, they use the
usual operators, and `IntMP` conforms to `SignedInteger`, so generic code
written for `BinaryInteger` works with it unchanged.

Every example below is also a test in `Tests/SwiftMPTests/TutorialTests.swift`,
so the outputs shown are checked on each `swift test`.

## 1. Adding SwiftMP to a package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/jmgc/SwiftMP", branch: "main"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "SwiftMP", package: "SwiftMP"),
    ]),
]
```

```swift
import SwiftMP
```

SwiftMP compiles its own copies of mini-gmp and MPFR, so nothing needs to be
installed on the system.

## 2. Integers: `IntMP`

### Creating values

```swift
let a: IntMP = 42                                   // integer literal
let b: IntMP = "123456789012345678901234567890"     // too big for Int: use a string literal
let c = IntMP(Int64.min)                            // from any Swift integer
let d = IntMP(-2.75)                                // from a floating-point value, truncated: -2
let f = IntMP(stringLiteral: "777", base: 8)        // explicit base: 511

let text = "0xff"                                   // text read at run time
let e = IntMP(text)                                 // Optional(255): the prefix gives the base
let bad = "12abc"
let g = IntMP(bad)                                  // nil: not a number
```

Parse run-time text through a `String` value as above. Written directly,
`IntMP("12abc")` is read as a string *literal*, and an invalid literal stops
the program instead of returning `nil`.

`IntMP(exactly:)` returns `nil` when a floating-point value has a fractional
part, as for Swift's own integers: `IntMP(exactly: 2.5)` is `nil`,
`IntMP(exactly: 3.0)` is `3`.

### Arithmetic

All the usual operators work and never overflow:

```swift
let x: IntMP = "123456789012345678901234567890"
let y: IntMP = "987654321098765432109876543210"

x * y        // 121932631137021795226185032733622923332237463801111263526900
y / x        // 8
y % x        // 9000000000900000000090
-x           // -123456789012345678901234567890
```

Division truncates toward zero, as `Int` does: `IntMP(-7) / 2` is `-3` and
`IntMP(-7) % 2` is `-1`. `quotientAndRemainder(dividingBy:)` returns both at once.

An integer literal next to an `IntMP` becomes an `IntMP`, so `x + 1` works. A
Swift integer stored in a variable has to be converted first:

```swift
let n = 10
let z = x + IntMP(n)
```

Compound assignment (`+=`, `*=`, `<<=`, …) updates the value in place, which
avoids allocating a new number on every step of a loop:

```swift
var total: IntMP = 0
for i in 1...100 {
    total += IntMP(i) * IntMP(i)
}
// total == 338350
```

### Number theory

```swift
IntMP.factorial(30)                  // 265252859812191058636308480000000
IntMP.gcd(12, 18)                    // 6
IntMP.lcm(12, 18)                    // 36
((IntMP(1) << 127) - 1).probablyPrime()   // true  (a Mersenne prime)
IntMP(91).probablyPrime()            // false (7 × 13)
```

`probablyPrime()` runs 32 Miller–Rabin rounds: `false` is certain,
`true` is wrong with a probability below 4⁻³².

### Bits

Bit operations use two's complement with an infinite sign extension, like
Python integers:

```swift
let p = IntMP(1) << 100              // 1267650600228229401496703205376
p >> 98                              // 4
IntMP(255) & 0x0f                    // 15
~IntMP(5)                            // -6
IntMP(-8) >> 1                       // -4 (rounds toward minus infinity)

var bits: IntMP = 0
bits[3] = 1                          // set bit 3
bits[130] = 1                        // and bit 130
bits[3]                              // 1
```

`bitWidth` is the number of bits needed in two's complement, sign included
(`IntMP(255).bitWidth` is 9), and `nonzeroBitCount` counts the ones in that
representation.

### Text and conversion back

```swift
let h = (IntMP(1) << 100) + 255
h.description                        // "1267650600228229401496703205631"
h.debugDescription                   // "0x100000000000000000000000ff"

Int(exactly: h)                      // nil: does not fit
Int(IntMP(42))                       // 42
Int(truncatingIfNeeded: (IntMP(1) << 64) + 5)   // 5: the low 64 bits
Double(IntMP(1) << 100)              // 1.2676506002282294e+30
```

`Int(_:)` traps when the value does not fit, exactly as converting an
`Int64` to an `Int8` does; use `Int(exactly:)` when unsure.

### Generic code

Because `IntMP` is a `BinaryInteger`, a generic function needs no changes:

```swift
func fibonacci<T: BinaryInteger>(_ n: Int, as _: T.Type) -> T {
    var (a, b): (T, T) = (0, 1)
    for _ in 0..<n { (a, b) = (b, a + b) }
    return a
}

fibonacci(90, as: Int.self)          // 2880067194370816120 (still fits in an Int)
fibonacci(200, as: IntMP.self)       // 280571172992510140037611932413038677189525
```

## 3. Unsigned integers: `UIntMP`

`UIntMP` is the unsigned counterpart. Subtraction below zero traps, as it does
for `UInt`:

```swift
let u: UIntMP = "340282366920938463463374607431768211455"   // 2^128 - 1
u + 1                                // 340282366920938463463374607431768211456
UIntMP(exactly: -1)                  // nil
// UIntMP(3) - UIntMP(4)             // traps: arithmetic overflow
```

`~` and `init(truncatingIfNeeded:)` with a negative value keep the bit
pattern over the value's own width (`UIntMP(truncatingIfNeeded: -1)` compares
equal to `3`, the two-bit pattern `11`). Unless you need that behaviour,
prefer `IntMP` and check the sign yourself.

## 4. Fractions: `QuotMP`

`QuotMP` keeps numerator and denominator exactly, always in lowest terms with
a positive denominator:

```swift
let third  = QuotMP(num: 1, den: 3)
let sixth  = QuotMP(num: 1, den: 6)
third + sixth                        // 1/2
QuotMP(num: 2, den: 3) * QuotMP(num: 9, den: 4)   // 3/2
QuotMP(num: 6, den: -4)              // -3/2
QuotMP(num: 6, den: -4).num          // -3
QuotMP(num: 6, den: -4).den          // 2

let q: QuotMP = "22/7"               // string literal
let input = "1/0"
QuotMP(input)                        // nil: zero denominator
```

Converting a `Double` gives its exact binary value, which shows why `0.1` is
not one tenth:

```swift
QuotMP(0.1)                          // 3602879701896397/36028797018963968
QuotMP(0.75)                         // 3/4
```

Fractions compare by value (`QuotMP(num: 1, den: 2) < QuotMP(num: 2, den: 3)`)
and `<<` / `>>` multiply or divide by powers of two. Division by zero traps.

## 5. Floating point: `FloatMP`

### Precision

A `FloatMP` has a precision in bits. Every new value, and every result of an
operation, uses the **default precision**, which starts at 53 bits (the same as
`Double`). Raise it before creating the values you work with:

```swift
FloatMP.significandBitCount = 200    // default precision for new values, in bits

let two: FloatMP = 2
let root = FloatMP.sqrt(two)
// root ≈ 1.41421356237309504880168872420969807856967187537694…  (60 significant digits)

FloatMP.significandBitCount = 53     // back to Double-like precision
```

The default precision is a global MPFR setting: set it once at start-up, not
from several threads at different values.

To change the precision of a single value, set its `significandWidth`; the
value is rounded to the new precision:

```swift
var v = FloatMP(1) / FloatMP(3)      // 53 bits
v.significandWidth = 20              // rounded to 20 bits
```

### Creating values and arithmetic

```swift
let a: FloatMP = 1.5                 // float literal
let b = FloatMP(2)                   // from an Int
let c = FloatMP(IntMP(1) << 200)     // from an IntMP (rounded to the precision)
let d = FloatMP(QuotMP(num: 1, den: 4))   // from a fraction: 0.25
let e: FloatMP = "2.5e21"            // from a string literal

a + b                                // 3.5
a * b                                // 3.0
FloatMP(1) / FloatMP(3)              // 0.333… rounded to the precision
```

`FloatMP(exactly:)` returns `nil` when the value cannot be represented exactly
at the default precision: `FloatMP(exactly: (IntMP(1) << 200) + 1)` is `nil`.

### Functions

`FloatMP` conforms to swift-numerics' `Real`, so the elementary functions are
available as static methods:

```swift
FloatMP.sin(FloatMP.pi / 2)          // 1
FloatMP.cos(FloatMP.pi)              // -1
FloatMP.exp(1)                       // e
FloatMP.log(FloatMP.exp(2))          // ≈ 2 (each step is rounded)
FloatMP.pow(2, 10)                   // 1024
FloatMP.root(FloatMP(27), 3)         // 3
FloatMP.gamma(5)                     // 24
```

### Special values and comparisons

Comparisons follow IEEE 754: `FloatMP.nan` is not equal to anything, itself
included, and `+0 == -0`:

```swift
let nan = FloatMP.nan
nan == nan                           // false
nan.isNaN                            // true
FloatMP.infinity > (FloatMP(1) << 10_000)   // true
FloatMP(0.0) == FloatMP(-0.0)        // true
```

Values that differ only in precision compare (and hash) as equal when they
hold the same number.

### Rounding

Each value carries a `rounding` mode used by the operations that produce it
(`.toNearestOrEven` by default). `rounded(_:)` rounds to an integer:

```swift
FloatMP(2.5).rounded(.toNearestOrEven)        // 2
FloatMP(2.5).rounded(.awayFromZero)           // 3
FloatMP(-2.5).rounded(.down)                  // -3
```

### Not implemented

`greatestFiniteMagnitude`, `leastNormalMagnitude`, `leastNonzeroMagnitude`,
`ulp` and `significand` stop the program with `fatalError`; MPFR has no fixed
exponent range in the IEEE sense.

## 6. Values, hashing and concurrency

All four types are values: a copy is independent of the original. The C data
is shared between copies until one of them changes, so copying is cheap:

```swift
var m: IntMP = "1000000000000000000000"
let n = m
m *= 2
// n is still 1000000000000000000000
```

The memory is released when the last copy goes away. All types are
`Hashable`, so they work as `Set` elements and `Dictionary` keys:

```swift
var cache: [IntMP: String] = [:]
cache[IntMP.factorial(20)] = "20!"
cache[IntMP(2432902008176640000)]    // "20!"
```

They are also `Sendable`: a value can be passed to another task or thread and
used there while the original is used here.

## 7. Performance notes

- Each operation allocates the result on the heap and calls into C. For
  numbers that always fit in 64 bits, `Int` / `Int64` are much faster.
- Prefer the compound operators (`+=`, `*=`, …) inside loops: they reuse the
  storage of a value that is not shared.
- `FloatMP` operations cost more as the precision grows; use the smallest
  precision that gives the accuracy you need.
