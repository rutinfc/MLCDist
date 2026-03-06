// MLCDistApp - dist 내 MLC 모델을 실행하는 iOS 앱
import SwiftUI

@main
struct MLCDistAppApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
