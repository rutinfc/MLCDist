import Foundation

/// MLC-LLM 사전 빌드 라이브러리(lib)를 제공하는 모듈.
/// MLCSwift와 함께 사용 시 링커 플래그를 통해 lib 폴더의 정적 라이브러리를 링크합니다.
public enum MLCDist {
    /// MLCDist 라이브러리 사용 가능 여부
    public static var isAvailable: Bool { true }
}
