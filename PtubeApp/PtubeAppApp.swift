import SwiftUI

@main
struct PapaTubeApp: App {
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            PlayerScreen()
                .environmentObject(app)
        }
    }
} 