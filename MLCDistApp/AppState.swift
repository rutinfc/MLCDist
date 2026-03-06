import Foundation
import SwiftUI
import MLCSwift
import ZIPFoundation
import UniformTypeIdentifiers

struct ModelInfo {
    let modelId: String
    let modelPath: String
    let modelLib: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    var usageText: String?

    enum MessageRole {
        case user
        case assistant
    }
}

@MainActor
class AppState: ObservableObject {
    private let engine = MLCEngine()

    /// iOS Files에서 import된 zip의 압축 해제 폴더 (zip 파일명으로 생성)
    /// 이 폴더 아래에 mlc-app-config.json과 모델 폴더들이 있음
    @Published var importedModelBaseURL: URL?

    @Published var displayText = ""
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGenerating = false
    @Published var isImporting = false
    @Published var selectedModel: ModelInfo?
    @Published var availableModels: [ModelInfo] = []

    private var engineLoaded = false

    /// 앱 Documents 디렉토리 (import된 모델 저장 위치)
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init() {
        loadLastImportedModel()
    }

    /// 마지막으로 import한 모델 폴더 로드
    private func loadLastImportedModel() {
        if let path = UserDefaults.standard.string(forKey: "lastImportedModelURLPath"),
           FileManager.default.fileExists(atPath: path) {
            importedModelBaseURL = URL(fileURLWithPath: path)
            loadModelsFromImportedFolder()
            selectDefaultModel()
        }
    }

    /// zip 파일 import (iOS Files에서 선택)
    /// - zip을 Documents/<zip파일명>/ 폴더에 압축 해제
    func importModelZip(from sourceURL: URL) {
        isImporting = true
        errorMessage = nil

        Task {
            do {
                // zip 파일명(확장자 제외)으로 폴더 생성
                let zipFileName = sourceURL.deletingPathExtension().lastPathComponent
                let destinationURL = documentsURL.appending(path: zipFileName)

                // 기존 폴더가 있으면 삭제
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

                // zip 압축 해제
                try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)

                // 압축 해제 후 zip 파일 삭제 (용량 절약)
                try? FileManager.default.removeItem(at: sourceURL)

                // mlc-app-config.json 확인
                let configURL = destinationURL.appending(path: "mlc-app-config.json")
                guard FileManager.default.fileExists(atPath: configURL.path) else {
                    throw NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "mlc-app-config.json을 찾을 수 없습니다. zip 구조를 확인해주세요."])
                }

                await MainActor.run {
                    importedModelBaseURL = destinationURL
                    UserDefaults.standard.set(destinationURL.path, forKey: "lastImportedModelURLPath")
                    loadModelsFromImportedFolder()
                    selectDefaultModel()
                    engineLoaded = false
                    startEngineIfNeeded()
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "모델 import 실패: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }

    /// import된 폴더의 mlc-app-config.json에서 모델 목록 로드
    private func loadModelsFromImportedFolder() {
        guard let baseURL = importedModelBaseURL else {
            availableModels = []
            return
        }

        let configURL = baseURL.appending(path: "mlc-app-config.json")
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(MLCAppConfig.self, from: data) else {
            availableModels = []
            return
        }

        availableModels = config.modelList.map { model in
            ModelInfo(
                modelId: model.modelId,
                modelPath: model.modelPath,
                modelLib: model.modelLib
            )
        }
    }

    private func selectDefaultModel() {
        if let first = availableModels.first {
            selectedModel = first
        } else {
            selectedModel = nil
        }
    }

    func selectModel(_ model: ModelInfo) {
        selectedModel = model
        engineLoaded = false
        startEngineIfNeeded()
    }

    func startEngineIfNeeded() {
        guard !engineLoaded, let model = selectedModel, let baseURL = importedModelBaseURL else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // baseURL + modelPath = 모델 폴더 전체 경로
                let modelFullPath = baseURL.appending(path: model.modelPath).path()
                await engine.reload(modelPath: modelFullPath, modelLib: model.modelLib)
                engineLoaded = true
                isLoading = false
            } catch {
                errorMessage = "모델 로딩 실패: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func sendMessage(_ text: String) {
        guard let _ = selectedModel, engineLoaded else {
            errorMessage = "모델을 먼저 로드해주세요"
            return
        }

        messages.append(ChatMessage(role: .user, content: text))
        isGenerating = true

        Task {
            var assistantContent = ""
            var usageText: String?

            for await res in await engine.chat.completions.create(
                messages: [
                    ChatCompletionMessage(role: .user, content: text)
                ],
                stream_options: StreamOptions(include_usage: true)
            ) {
                await MainActor.run {
                    if let finalUsage = res.usage {
                        usageText = finalUsage.extra?.asTextLabel()
                    } else {
                        assistantContent += res.choices[0].delta.content?.asText() ?? ""
                    }
                }
            }

            await MainActor.run {
                messages.append(ChatMessage(
                    role: .assistant,
                    content: assistantContent,
                    usageText: usageText
                ))
                isGenerating = false
            }
        }
    }
}

private struct MLCAppConfig: Decodable {
    let modelList: [MLCModelEntry]

    enum CodingKeys: String, CodingKey {
        case modelList = "model_list"
    }
}

private struct MLCModelEntry: Decodable {
    let modelId: String
    let modelPath: String
    let modelLib: String

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case modelPath = "model_path"
        case modelLib = "model_lib"
    }
}
