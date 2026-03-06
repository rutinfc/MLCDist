import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDocumentPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if appState.isImporting {
                    ProgressView("모델 import 중...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.isLoading {
                    ProgressView("모델 로딩 중...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = appState.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.availableModels.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("모델을 import 해주세요")
                            .font(.title2)
                        Text("iOS Files에서 MLC 모델 zip 파일을 선택하세요.\nzip 압축 해제 후 mlc-app-config.json을 읽어 모델을 로드합니다.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            showDocumentPicker = true
                        } label: {
                            Label("모델 Import", systemImage: "folder.badge.plus")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ChatView()
                }
            }
            .navigationTitle("MLC Chat")
            .onAppear {
                appState.startEngineIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !appState.availableModels.isEmpty {
                        Button {
                            showDocumentPicker = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !appState.isLoading && appState.errorMessage == nil && !appState.availableModels.isEmpty {
                        Menu {
                            ForEach(appState.availableModels, id: \.modelId) { model in
                                Button {
                                    appState.selectModel(model)
                                } label: {
                                    HStack {
                                        Text(model.modelId)
                                        if appState.selectedModel?.modelId == model.modelId {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label(appState.selectedModel?.modelId ?? "모델 선택", systemImage: "cpu")
                        }
                    }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { url in
                    showDocumentPicker = false
                    appState.importModelZip(from: url)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
