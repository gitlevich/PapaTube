import Foundation
import Combine
import YouTubePlayerKit

/// Immutable description of the player's current mode.
public enum PlayerMode: Equatable {
    case idle
    case loading(index: Int)
    case playing(index: Int)
    case paused(index: Int)
    case ended(index: Int)

    /// Index of the video the mode is related to, if any.
    public var index: Int? {
        switch self {
        case .loading(let i), .playing(let i), .paused(let i), .ended(let i):
            return i
        default: return nil
        }
    }
}

protocol PlaylistProvider: AnyObject {
    var videos: [Video] { get }
}

extension PlaylistService: PlaylistProvider {}
extension YouTubePlaylistService: PlaylistProvider {}

/// A small finite-state machine that is the single source of truth for
/// what the player is doing (which video is active, whether it is playing, etc.).
/// UI code can simply observe the published `mode` property instead of juggling
/// separate booleans & indexes.
@MainActor
final class PlaybackStateMachine: ObservableObject {
    // MARK: - Published output
    @Published private(set) var mode: PlayerMode = .idle

    // MARK: - Private
    private let playlist: PlaylistProvider
    private let player: YouTubePlayer
    private var bag = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>? = nil

    // MARK: - Init
    init(playlist: PlaylistProvider, player: YouTubePlayer) {
        self.playlist = playlist
        self.player = player

        // Observe underlying player events → translate into FSM states.
        player.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in self?.handle(playerState: s) }
            .store(in: &bag)
    }

    // MARK: - Derived helpers
    var currentIndex: Int { mode.index ?? 0 }
    var atStart: Bool { currentIndex == 0 }
    var atEnd: Bool { currentIndex >= max(0, playlist.videos.count - 1) }
    var isPlaying: Bool { if case .playing = mode { return true } else { return false } }

    // MARK: - Public events
    func next() { load(index: min(currentIndex + 1, playlist.videos.count - 1)) }
    func prev() { load(index: max(currentIndex - 1, 0)) }

    func togglePlayPause() {
        switch mode {
        case .playing:
            Task { try? await player.pause() }
        case .paused, .ended:
            Task { try? await player.play() }
        default:
            break // Not loaded yet.
        }
    }

    /// Start loading & automatically play the given video.
    func load(index: Int) {
        guard playlist.videos.indices.contains(index) else { return }
        mode = .loading(index: index)
        loadTask?.cancel()
        loadTask = Task { [playlist, player] in
            // Capture index to ensure consistent ordering
            let videoID = playlist.videos[index].id
            try? await player.load(source: .video(id: videoID))
            try? await player.play()
        }
    }

    // MARK: - Player delegate → FSM transitions
    private func handle(playerState: YouTubePlayer.PlaybackState) {
        switch playerState {
        case .playing:
            if let i = mode.index { mode = .playing(index: i) }
        case .paused, .buffering, .unstarted:
            if let i = mode.index { mode = .paused(index: i) }
        case .ended:
            if let i = mode.index { mode = .ended(index: i) }
        default:
            break
        }
    }
} 