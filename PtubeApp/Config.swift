import Foundation

enum Config {
    static var youtubeAPIKey: String {
        guard let key = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? Bundle.main.infoDictionary?["YOUTUBE_API_KEY"] as? String else {
            fatalError("YOUTUBE_API_KEY not set")
        }
        return key
    }
} 