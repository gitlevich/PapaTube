import Foundation
import Combine
import OctoKit

final class PlaylistService: ObservableObject {
    @Published private(set) var videos: [Video] = []

    private var cancellables = Set<AnyCancellable>()

    /// Sync playlist.json from the public GitHub repo.
    func sync() {
        guard let url = URL(string: "https://raw.githubusercontent.com/gitlevich/PapaTube/main/conf/playlist.json") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Video].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Playlist fetch error:", error)
                }
            }, receiveValue: { [weak self] videos in
                self?.videos = videos
                self?.cache(videos: videos)
            })
            .store(in: &cancellables)
    }

    private func cache(videos: [Video]) {
        if let data = try? JSONEncoder().encode(videos) {
            try? data.write(to: cacheURL())
        }
    }

    private func loadCache() {
        if let data = try? Data(contentsOf: cacheURL()),
           let cached = try? JSONDecoder().decode([Video].self, from: data) {
            self.videos = cached
        }
    }

    private func cacheURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("playlist.json")
    }

    init() {
        loadCache()
    }
} 