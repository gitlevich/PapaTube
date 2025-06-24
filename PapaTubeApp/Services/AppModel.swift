import SwiftUI
import Combine
import YouTubePlayerKit

/// Root state container – owns playlist fetching and simple playback control (no FSM).
@MainActor
final class AppModel: ObservableObject {
    // MARK: - Sub-objects
    let playlistStore: PlaylistStore
    let player: PlayerProtocol

    // MARK: - Published UI state
    @Published private(set) var playlist: [Video] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var isEnded: Bool = false

    // Persisted playback info
    @Published var positions: [String: Double] = [:] // videoId : seconds
    @Published var playingStates: [String: Bool] = [:] // videoId : wasPlaying

    private var bag = Set<AnyCancellable>()

    private let defaults = UserDefaults.standard
    private let keyPositions = "positions"
    private let keyPlaying = "playingStates"
    private let keyIndex = "currentIndex"

    init(player: PlayerProtocol? = nil, playlistStore: PlaylistStore? = nil) {
        self.playlistStore = playlistStore ?? PlaylistStore()

        self.player = player ?? RealPlayer(wrapped: YouTubePlayer(
             source: .video(id: ""),
             parameters: .init(autoPlay: false,
                               showControls: false,
                               showFullscreenButton: false,
                               showCaptions: false)))

        // Load persisted state
        currentIndex = defaults.integer(forKey: keyIndex)
        if let data = defaults.data(forKey: keyPositions),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
            positions = dict
        }
        if let data = defaults.data(forKey: keyPlaying),
           let dict = try? JSONDecoder().decode([String: Bool].self, from: data) {
            playingStates = dict
        }

        // Relay playlist updates.
        self.playlistStore.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] st in
                guard let self else { return }
                if case let .loaded(vids) = st {
                    playlist = vids
                    // Auto-start first video when playlist appears.
                    if !vids.isEmpty {
                        load(index: 0)
                    }
                }
            }
            .store(in: &bag)

        // Start with cached/remote playlist.
        Task { await self.playlistStore.refresh() }

        // Keep isPlaying in sync with actual player callbacks.
        self.player.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .playing:
                    self?.isPlaying = true
                    self?.isEnded = false
                case .ended:
                    self?.isPlaying = false
                    self?.isEnded = true
                case .paused, .buffering, .unstarted:
                    self?.isPlaying = false
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    // MARK: - Controls
    private func play() {
        isPlaying = true
        Task { try? await player.play() }
    }

    private func pause() {
        isPlaying = false
        Task { try? await player.pause() }
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func load(index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index

        let id = playlist[index].id
        Task {
            try? await player.load(source: .video(id: id))
            if isPlaying {
                try? await player.play()
            } else {
                try? await player.pause()
            }
        }
    }

    func next() {
        guard !playlist.isEmpty else { return }
        load(index: min(currentIndex + 1, playlist.count - 1))
    }

    func prev() {
        guard !playlist.isEmpty else { return }
        load(index: max(currentIndex - 1, 0))
    }

    func refreshPlaylist() { Task { await playlistStore.refresh() } }

    // MARK: - Playback state helpers
    func updatePosition(for videoID: String, seconds: Double) {
        positions[videoID] = seconds
        save()
    }

    func updatePlaying(for videoID: String, isPlaying: Bool) {
        playingStates[videoID] = isPlaying
        save()
    }

    // Persist when app backgrounds.
    func save() {
        defaults.set(currentIndex, forKey: keyIndex)
        if let data = try? JSONEncoder().encode(positions) {
            defaults.set(data, forKey: keyPositions)
        }
        if let data = try? JSONEncoder().encode(playingStates) {
            defaults.set(data, forKey: keyPlaying)
        }
    }
} 