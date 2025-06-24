import XCTest
@testable import PapaTubeApp
import Combine
import YouTubePlayerKit

/// Behavior-spec tests for AppModel (scaffold). Each test currently just passes –
/// replace the GIVEN/WHEN/THEN blocks with concrete assertions.
@MainActor final class AppModelSpecTests: XCTestCase {
    
    // MARK: - Test doubles (local to test bundle)
    // TODO: Introduce a stub player once AppModel is refactored for dependency injection.
    
    // Simple in-memory stub of PlayerProtocol.
    final class StubPlayer: PlayerProtocol {
        enum Call: Equatable { case play, pause, load(String) }
        private(set) var calls: [Call] = []

        private let stateSubject = PassthroughSubject<YouTubePlayer.PlaybackState, Never>()
        var playbackStatePublisher: AnyPublisher<YouTubePlayer.PlaybackState, Never> { stateSubject.eraseToAnyPublisher() }

        func load(source: YouTubePlayer.Source) async throws {
            if case .video(let id) = source { calls.append(.load(id)) }
        }
        func play() async throws { calls.append(.play); stateSubject.send(.playing) }
        func pause() async throws { calls.append(.pause); stateSubject.send(.paused) }
    }
    
    // Example scaffold
    func testPlayToggle() async {
        /* GIVEN */
        let stub = StubPlayer()
        let app = AppModel(player: stub)

        /* WHEN */
        app.togglePlayPause()

        /* THEN */
        let exp = XCTestExpectation(description: "playing")
        let canc = app.$isPlaying.sink { if $0 { exp.fulfill() } }
        await fulfillment(of: [exp], timeout: 1.0)
        canc.cancel()
        XCTAssertTrue(app.isPlaying)
        // Note: player.play() should have been invoked (covered via isPlaying flag change)
    }
} 