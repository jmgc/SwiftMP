// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMP",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "minigmp",
            targets: ["Cminigmp"]),
        .library(
            name: "mpfr",
            targets: ["Cmpfr"]),
        .library(
            name: "SwiftMP",
            targets: ["SwiftMP"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "0.0.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Cminigmp",
            dependencies: []),
        .target(
            name: "Cmpfr",
            dependencies: ["Cminigmp"],
            cSettings: [
                .define("MPFR_USE_MINI_GMP", to: "1"),
                .define("MINI_GMP_LIMB_TYPE", to: 1.bitWidth == 32 ? "int" : "long"),
                .define("GMP_NUMB_BITS", to: "\(1.bitWidth)"),
                .define("HAVE_STDARG", to: "1"),
                .define(1.littleEndian == 1 ? "HAVE_BIG_ENDIAN" : "HAVE_LITTLE_ENDIAN")
            ]),
        .target(
            name: "SwiftMP",
            dependencies: ["Cmpfr",
                           .product(name: "Numerics", package: "swift-numerics")]),
        .testTarget(
            name: "CminigmpTests",
            dependencies: ["Cminigmp"]),
        .testTarget(
            name: "CmpfrTests",
            dependencies: ["Cmpfr"],
            cSettings: [
                .define("MPFR_USE_MINI_GMP", to: "1"),
                .define("MINI_GMP_LIMB_TYPE", to: 1.bitWidth == 32 ? "int" : "long"),
                .define("GMP_NUMB_BITS", to: "\(1.bitWidth)"),
                .define("HAVE_STDARG", to: "1"),
                .define(1.littleEndian == 1 ? "HAVE_BIG_ENDIAN" : "HAVE_LITTLE_ENDIAN")
            ]),
        .testTarget(
            name: "SwiftMPTests",
            dependencies: ["SwiftMP"]),
    ]
)
