import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if appState.isLoading {
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
                } else {
                    ChatView()
                }
            }
            .navigationTitle("MLC Chat")
        .onAppear {
            appState.startEngineIfNeeded()
        }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !appState.isLoading && appState.errorMessage == nil {
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
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
