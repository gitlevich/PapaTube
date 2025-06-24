import Combine
import YouTubePlayerKit

// Lightweight abstraction over YouTubePlayer so core logic can be tested without the SDK.
protocol PlayerProtocol {
    var playbackStatePublisher: AnyPublisher<YouTubePlayer.PlaybackState, Never> { get }
    func load(source: YouTubePlayer.Source) async throws
    func play() async throws
    func pause() async throws
}

// Prefer using this adapter to pass a concrete PlayerProtocol where needed.
@MainActor
struct RealPlayer: PlayerProtocol {
    let wrapped: YouTubePlayer

    var playbackStatePublisher: AnyPublisher<YouTubePlayer.PlaybackState, Never> {
        wrapped.playbackStatePublisher.eraseToAnyPublisher()
    }

    func load(source: YouTubePlayer.Source) async throws {
        try await wrapped.load(source: source)
    }

    func play() async throws { try await wrapped.play() }
    func pause() async throws { try await wrapped.pause() }
} 