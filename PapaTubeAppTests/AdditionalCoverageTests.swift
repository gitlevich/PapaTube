import XCTest
@testable import PapaTubeApp

/// Extra tests that improve code-coverage for small helpers and flag getters.
final class AdditionalCoverageTests: XCTestCase {

    // MARK: Collection+Safe
    func testSafeSubscript() {
        let arr = [1, 2, 3]
        XCTAssertEqual(arr[safe: 1], 2)
        XCTAssertNil(arr[safe: 99]) // out of bounds should be nil
    }

    // MARK: Video helpers
    func testVideoIDExtractionVariants() {
        let longURL = "https://www.youtube.com/watch?v=XYZ123"
        let shortURL = "https://youtu.be/ABC987"

        let v1 = Video(title: "A", year: nil, youtube_url: longURL)
        let v2 = Video(title: "B", year: nil, youtube_url: shortURL)

        XCTAssertEqual(v1.id, "XYZ123")
        XCTAssertEqual(v2.id, "ABC987")
    }

    func testVideoURLProperty() {
        let v = Video(title: "Title", year: 2025, youtube_url: "https://youtu.be/hello")
        XCTAssertEqual(v.url.absoluteString, "https://youtu.be/hello")
    }

    // MARK: Playlist boundary helpers
    func testPlaylistBoundaryFlags() {
        let vids = (0..<2).map { Video(title: "\($0)", year: nil, youtube_url: "https://youtu.be/\($0)") }
        let start = Playlist(videos: vids) // index 0
        XCTAssertTrue(start.isAtStart)
        XCTAssertFalse(start.isAtEnd)

        let end = start.move(to: 1)
        XCTAssertTrue(end.isAtEnd)
        XCTAssertFalse(end.isAtStart)
    }

    // MARK: InteractionController flag getters
    @MainActor func testInteractionControllerFlags() {
        let ctrl = InteractionController(playlist: [])
        // With empty playlist controls should still be considered active (settings closed)
        XCTAssertTrue(ctrl.controlsActive)
        XCTAssertTrue(ctrl.videoSurfaceBlocked) // always true per design comment
        XCTAssertFalse(ctrl.gridActive)
        XCTAssertFalse(ctrl.settingsActive)
        // Present settings and verify flags flip
        ctrl.presentSettings()
        XCTAssertFalse(ctrl.controlsActive)
        XCTAssertTrue(ctrl.settingsActive)
    }
} 