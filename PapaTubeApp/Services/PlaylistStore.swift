import Foundation
import Combine

@MainActor
final class PlaylistStore: ObservableObject {

    enum PlaylistState: Equatable {
        case idle
        case loading
        case loaded([Video])
        case failed(String)
    }

    // Published state the UI can react to.
    @Published private(set) var state: PlaylistState = .idle

    // Convenience: current videos (empty for any other state)
    var videos: [Video] {
        if case let .loaded(v) = state { return v } else { return [] }
    }

    private let auth = AuthService.shared
    private let defaults = UserDefaults.standard
    private let keyPlaylistID = "ytPlaylistID"

    private var loadTask: Task<Void, Never>? = nil
    private var bag = Set<AnyCancellable>()

    init() {
        // preload cached
        if let data = try? Data(contentsOf: cacheURL()),
           let vids = try? JSONDecoder().decode([Video].self, from: data) {
            state = .loaded(vids)
        }

        // attempt remote
        Task { await refresh() }

        // Refresh automatically when user signs in/out.
        auth.$accessToken
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
            .store(in: &bag)
    }

    // MARK: - Public API

    var playlistID: String {
        get { defaults.string(forKey: keyPlaylistID) ?? "" }
    }

    func setPlaylistInput(_ input: String) {
        defaults.setValue(extractPlaylistID(from: input), forKey: keyPlaylistID)
    }

    func refresh() async {
        guard !playlistID.isEmpty else { return }
        guard let token = auth.accessToken else {
            state = .failed("Not signed in")
            return
        }

        loadTask?.cancel()
        loadTask = Task {
            await MainActor.run { state = .loading }

            do {
                let vids = try await fetchAllVideos(token: token, playlistID: playlistID)
                // cache
                if let data = try? JSONEncoder().encode(vids) {
                    try? data.write(to: self.cacheURL(), options: .atomic)
                }
                await MainActor.run { state = .loaded(vids) }
            } catch {
                await MainActor.run { state = .failed(error.localizedDescription) }
            }
        }
    }

    // MARK: - Helpers

    func extractPlaylistID(from input: String) -> String {
        if input.contains("http"), let comps = URLComponents(string: input),
           let list = comps.queryItems?.first(where: { $0.name == "list" })?.value {
            return list
        }
        return input
    }

    private func cacheURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("yt_playlist.json")
    }

    private func fetchAllVideos(token: String, playlistID: String) async throws -> [Video] {
        var videos: [Video] = []
        var nextToken: String? = nil

        repeat {
            var comp = URLComponents(string: "https://www.googleapis.com/youtube/v3/playlistItems")!
            comp.queryItems = [
                .init(name: "part", value: "snippet"),
                .init(name: "maxResults", value: "50"),
                .init(name: "playlistId", value: playlistID)
            ]
            if let n = nextToken { comp.queryItems?.append(.init(name: "pageToken", value: n)) }

            var req = URLRequest(url: comp.url!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(ItemsResponse.self, from: data)
            videos.append(contentsOf: decoded.items.map { $0.toVideo() })
            nextToken = decoded.nextPageToken
        } while nextToken != nil

        return videos
    }

    // MARK: - DTOs
    private struct ItemsResponse: Decodable {
        let items: [Item]
        let nextPageToken: String?

        struct Item: Decodable {
            let snippet: Snippet
            struct Snippet: Decodable {
                let title: String
                let resourceId: ResourceID
                struct ResourceID: Decodable { let videoId: String }
            }
            func toVideo() -> Video {
                Video(title: snippet.title, year: nil, youtube_url: "https://youtu.be/\(snippet.resourceId.videoId)")
            }
        }
    }
} 