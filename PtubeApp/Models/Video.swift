import Foundation

struct Video: Identifiable, Codable {
    let title: String
    let year: Int?
    let youtube_url: String

    var id: String { Video.extractID(from: youtube_url) ?? UUID().uuidString }

    var url: URL { URL(string: youtube_url)! }

    // MARK: - Helpers
    private static func extractID(from url: String) -> String? {
        if let url = URL(string: url), let host = url.host {
            if host.contains("youtube.com") {
                return URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "v" })?
                    .value
            } else if host.contains("youtu.be") {
                return url.pathComponents.dropFirst().first
            }
        }
        return nil
    }
} 