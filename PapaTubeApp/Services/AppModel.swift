import SwiftUI
import Combine
import YouTubePlayerKit

/// Root state container – owns playlist fetching and simple playback control (no FSM).
@MainActor
final class AppModel: ObservableObject {
    // MARK: - Sub-objects
    let playlistService = YouTubePlaylistService()
    let playbackStore   = PlaybackStateStore()
    let player: YouTubePlayer

    // MARK: - Published UI state
    @Published private(set) var playlist: [Video] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var isEnded: Bool = false

    private var bag = Set<AnyCancellable>()

    init() {
        player = YouTubePlayer(
            source: .video(id: ""),
            parameters: .init(autoPlay: false,
                              showControls: false,
                              showFullscreenButton: false,
                              showCaptions: false))

        // Relay playlist updates.
        playlistService.$state
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
        Task { await playlistService.refresh() }

        // Keep isPlaying in sync with actual player callbacks.
        player.playbackStatePublisher
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
            _ = try? await player.load(source: .video(id: id))
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

    func refreshPlaylist() { Task { await playlistService.refresh() } }

    // Persist when app backgrounds.
    func save() { playbackStore.save() }
} 