# MLCSwift (로컬 패키지)

MLC LLM iOS Swift 바인딩. mlc-llm/ios/MLCSwift와 동일한 API를 제공합니다.

## 구조

- **Sources/ObjC/**: JSONFFIEngine (Objective-C++ 브릿지)
- **Sources/Swift/**: MLCEngine, OpenAI 호환 API
- **Sources/ObjC/third_party/**: tvm C++ 헤더 (패키지 내 포함, mlc-llm 의존성 없음)
  - `tvm_include/`: tvm/include (runtime, ir 등)
  - `tvm_ffi_include/`: tvm-ffi/include (ffi/extra, ffi/function 등)
  - `dlpack_include/`: dlpack 헤더

## 의존성

- **dist/lib**: MLC 사전 빌드 라이브러리 (libmlc_llm.a, libtvm_runtime.a 등) - 앱 프로젝트에서 링크
