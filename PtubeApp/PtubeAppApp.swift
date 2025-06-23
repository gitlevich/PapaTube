import SwiftUI

@main
struct PtubeAppApp: App {
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            PlayerScreen()
                .environmentObject(app)
        }
    }
} 