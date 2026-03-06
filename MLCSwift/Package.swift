// swift-tools-version: 5.5
// MLCDist 로컬 MLCSwift 패키지 - mlc-llm/ios/MLCSwift와 동일한 API

import PackageDescription

let package = Package(
    name: "MLCSwift",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MLCSwift",
            targets: ["MLCEngineObjC", "MLCSwift"]
        )
    ],
    dependencies: [],
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
        )
    ],
    cxxLanguageStandard: .cxx17
)
