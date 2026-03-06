import Foundation
import SwiftUI
import MLCSwift

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
    private var bundleURL: URL {
        Bundle.main.bundleURL.appending(path: "bundle")
    }

    @Published var displayText = ""
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isGenerating = false
    @Published var selectedModel: ModelInfo?
    @Published var availableModels: [ModelInfo] = []

    private var engineLoaded = false

    init() {
        loadAvailableModels()
        selectDefaultModel()
    }

    private func loadAvailableModels() {
        // bundle 폴더가 앱 리소스에 복사됨 (dist/bundle)
        if let configURL = Bundle.main.url(forResource: "mlc-app-config", withExtension: "json", subdirectory: "bundle"),
           let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(MLCAppConfig.self, from: data) {
            availableModels = config.modelList.map { model in
                ModelInfo(
                    modelId: model.modelId,
                    modelPath: model.modelPath,
                    modelLib: model.modelLib
                )
            }
        } else {
            // 폴백: dist/bundle/mlc-app-config.json 기반 기본 모델
            availableModels = [
                ModelInfo(modelId: "gemma3-270m-v13-q4f16_0", modelPath: "gemma3-270m-v13-q4f16_0", modelLib: "gemma3_text_q4f16_0_4cfe7a4812ed2a438e1fa691f0f6f158"),
                ModelInfo(modelId: "gemma3-270m-v13-q4f16_1", modelPath: "gemma3-270m-v13-q4f16_1", modelLib: "gemma3_text_q4f16_1_05e65fe2ba13ae2a9724bff8288b593f"),
                ModelInfo(modelId: "gemma3-1b-v9-q4f16_0", modelPath: "gemma3-1b-v9-q4f16_0", modelLib: "gemma3_text_q4f16_0_5f7490bb7a0220180ac9660a30560e11"),
                ModelInfo(modelId: "gemma3-1b-v9-q4f16_1", modelPath: "gemma3-1b-v9-q4f16_1", modelLib: "gemma3_text_q4f16_1_c6979bf20d04b9a71d1118f1fb7c6fc1"),
            ]
        }
    }

    private func selectDefaultModel() {
        if let first = availableModels.first {
            selectedModel = first
        }
    }

    func selectModel(_ model: ModelInfo) {
        selectedModel = model
        engineLoaded = false
        startEngineIfNeeded()
    }

    func startEngineIfNeeded() {
        guard !engineLoaded, let model = selectedModel else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let modelLocalPath = bundleURL.appending(path: model.modelPath).path()
                await engine.reload(modelPath: modelLocalPath, modelLib: model.modelLib)
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
