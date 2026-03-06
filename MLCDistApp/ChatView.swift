import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(appState.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if appState.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("생성 중...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
                .onChange(of: appState.messages.count) { _ in
                    if let last = appState.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("메시지를 입력하세요", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...6)
                    .focused($isInputFocused)
                    .disabled(appState.isGenerating)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(inputText.isEmpty || appState.isGenerating ? .gray : .accentColor)
                }
                .disabled(inputText.isEmpty || appState.isGenerating)
            }
            .padding()
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isInputFocused = false
        appState.sendMessage(text)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                    .foregroundStyle(message.role == .user ? .primary : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if let usage = message.usageText {
                    Text(usage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}
