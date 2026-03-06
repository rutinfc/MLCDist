#!/bin/bash
# .a 파일들을 합쳐 MLCEngine.xcframework 생성
# Sources/ObjC/lib의 .a 파일이 변경되면 이 스크립트를 실행하세요.

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$ROOT/Sources/ObjC/lib"
BUILD_DIR="$ROOT/XCFrameworks/build"
OUTPUT_DIR="$ROOT/XCFrameworks"

mkdir -p "$BUILD_DIR/ios-arm64"

echo "Combining static libraries..."
libtool -static -o "$BUILD_DIR/ios-arm64/libMLCEngine.a" \
  "$LIB_DIR/libmlc_llm.a" \
  "$LIB_DIR/libmodel_iphone.a" \
  "$LIB_DIR/libsentencepiece.a" \
  "$LIB_DIR/libtokenizers_c.a" \
  "$LIB_DIR/libtokenizers_cpp.a" \
  "$LIB_DIR/libtvm_ffi_static.a" \
  "$LIB_DIR/libtvm_runtime.a"

echo "Creating XCFramework..."
rm -rf "$OUTPUT_DIR/MLCEngine.xcframework"
xcodebuild -create-xcframework \
  -library "$BUILD_DIR/ios-arm64/libMLCEngine.a" \
  -output "$OUTPUT_DIR/MLCEngine.xcframework"

echo "Done: $OUTPUT_DIR/MLCEngine.xcframework"
