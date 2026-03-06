// swift-tools-version: 5.5
// MLCDist 루트 패키지 - MLCSwift 라이브러리

import PackageDescription

let package = Package(
    name: "MLCDist",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MLCSwift",
            targets: ["MLCEngineObjC", "MLCSwift"]
        ),
        .library(
            name: "MLCDistAppSupport",
            targets: ["MLCDistAppSupport"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
            name: "MLCEngineObjC",
            path: "Sources/ObjC",
            cxxSettings: [
                .headerSearchPath("third_party/tvm_include"),
                .headerSearchPath("third_party/tvm_ffi_include"),
                .headerSearchPath("third_party/dlpack_include")
            ]
        ),
        .target(
            name: "MLCSwift",
            dependencies: ["MLCEngineObjC"],
            path: "Sources/Swift"
        ),
        .target(
            name: "MLCDistAppSupport",
            dependencies: ["ZIPFoundation"],
            path: "Sources/MLCDistAppSupport"
        )
    ],
    cxxLanguageStandard: .cxx17
)
