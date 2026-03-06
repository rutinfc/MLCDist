// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MLCDist",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "MLCDist",
            targets: ["MLCDist"]
        ),
    ],
    targets: [
        .target(
            name: "MLCDist",
            path: "Sources/MLCDist",
            linkerSettings: [
                .unsafeFlags(["-L", "lib"], .when(platforms: [.iOS])),
                .unsafeFlags([
                    "-Wl,-all_load",
                    "-lmodel_iphone",
                    "-lmlc_llm",
                    "-ltvm_runtime",
                    "-ltvm_ffi_static",
                    "-ltokenizers_cpp",
                    "-lsentencepiece",
                    "-ltokenizers_c",
                ], .when(platforms: [.iOS])),
            ]
        ),
    ]
)
