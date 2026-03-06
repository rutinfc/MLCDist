# MLCDistApp

dist 폴더의 MLC 모델(Gemma3)을 실행하는 iOS 앱입니다. **루트 Package.swift**(`MLCDist/Package.swift`)와 dist 내 사전 빌드된 라이브러리를 사용합니다. tvm C++ 헤더가 `Sources/ObjC/third_party/`에 포함되어 있어 **mlc-llm 서브모듈 없이** 빌드 가능합니다.

## 사전 요구사항

- Xcode 15+
- iOS 16+
- **실기기 필요**: Sources/ObjC/lib의 라이브러리가 iPhone용으로 빌드되어 있어 **시뮬레이터에서는 실행되지 않습니다**

## 설정

### 1. Xcode에서 프로젝트 열기

```bash
open MLCDistApp.xcodeproj
```

### 2. 개발 팀 설정

1. Xcode에서 MLCDistApp 타겟 선택
2. **Signing & Capabilities** 탭 이동
3. **Team** 드롭다운에서 본인의 Apple Developer 팀 선택

### 3. 빌드 및 실행

- **실기기**를 연결하고 타겟으로 선택
- Run (⌘R)으로 빌드 및 실행

## 사용 가능한 모델

dist/bundle에 포함된 모델:

- **gemma3-270m-v13-q4f16_0** (270M 파라미터, 경량)
- **gemma3-270m-v13-q4f16_1**
- **gemma3-1b-v9-q4f16_0** (1B 파라미터)
- **gemma3-1b-v9-q4f16_1**

앱 내 상단 메뉴에서 모델을 전환할 수 있습니다.

## 프로젝트 구조

```
MLCDist/
├── Package.swift           # 루트 Swift 패키지 (MLCSwift 라이브러리)
├── Sources/
│   ├── ObjC/               # MLCEngineObjC
│   │   ├── lib/            # MLC 정적 라이브러리 (.a)
│   │   ├── third_party/    # tvm C++ 헤더 (포함)
│   │   │   ├── tvm_include/
│   │   │   ├── tvm_ffi_include/
│   │   │   └── dlpack_include/
│   │   └── ...
│   └── Swift/              # MLCSwift
├── MLCDistApp.xcodeproj    # Xcode 프로젝트 (SPM: 루트 패키지 참조)
├── MLCDistApp/             # 앱 소스
└── dist/                   # MLC 빌드 결과물
    └── bundle/             # 모델 가중치 및 설정
```
