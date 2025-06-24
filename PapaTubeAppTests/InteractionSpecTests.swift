import XCTest
@testable import PapaTubeApp

@MainActor final class InteractionSpecTests: XCTestCase {

    private func samplePlaylist() -> [Video] {
        [
            Video(title: "V1", year: nil, youtube_url: "https://youtu.be/1"),
            Video(title: "V2", year: nil, youtube_url: "https://youtu.be/2"),
            Video(title: "V3", year: nil, youtube_url: "https://youtu.be/3")
        ]
    }

    // 1. Play interaction
    func testPlay() {
        /* GIVEN Controls are visible, video is paused, Play toggle shows "Play" */
        let ctrl = InteractionController(playlist: samplePlaylist())

        /* WHEN the viewer presses the Play toggle */
        ctrl.togglePlayPause()

        /* THEN the Video plays and the Play toggle shows "Pause" */
        XCTAssertTrue(ctrl.isPlaying)
    }

    // 2. Pause interaction
    func testPause() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // start playing
        ctrl.togglePlayPause() // now pause
        XCTAssertFalse(ctrl.isPlaying)
    }

    // 3. Next interaction
    func testNext() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // now playing
        ctrl.next()
        XCTAssertEqual(ctrl.currentIndex, 1)
        XCTAssertTrue(ctrl.prevEnabled)
        XCTAssertTrue(ctrl.nextEnabled)
    }

    // 4. Previous interaction
    func testPrevious() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.currentIndex = 1
        ctrl.togglePlayPause()
        ctrl.prev()
        XCTAssertEqual(ctrl.currentIndex, 0)
        XCTAssertFalse(ctrl.prevEnabled)
    }

    // 5. Scrub interaction
    func testScrub() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause()
        ctrl.scrub(to: 42)
        // Only verifying that idle timer reset keeps controls visible.
        XCTAssertEqual(ctrl.controlsOpacity, .full)
    }

    // 6. Idle-fade interaction
    func testIdleFade() {
        /* GIVEN Controls are visible and playing */
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // playing
        /* WHEN 5 seconds pass */
        ctrl.tick(seconds: 5.1)
        /* THEN controls faded */
        XCTAssertEqual(ctrl.controlsOpacity, .faded)
    }

    // 7. Wake Controls
    func testWakeControls() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // playing
        ctrl.tick(seconds: 5.1) // fade
        XCTAssertEqual(ctrl.controlsOpacity, .faded)
        /* WHEN viewer taps screen */
        ctrl.wakeControls()
        /* THEN controls return to full */
        XCTAssertEqual(ctrl.controlsOpacity, .full)
    }

    // 9. Video completion -> Recommendation Grid
    func testVideoCompletionShowsGrid() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // playing
        /* WHEN video ends */
        ctrl.videoEnded()
        /* THEN Grid visible and controls hidden */
        XCTAssertTrue(ctrl.recommendationGridVisible)
        XCTAssertFalse(ctrl.isPlaying)
    }

    // 10. Select video from grid
    func testSelectVideoFromGrid() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.videoEnded() // grid visible
        ctrl.selectVideoFromGrid(index: 2)
        XCTAssertFalse(ctrl.recommendationGridVisible)
        XCTAssertEqual(ctrl.currentIndex, 2)
        XCTAssertTrue(ctrl.isPlaying)
    }

    // 11 & 12. Open settings and change playlist
    func testChangePlaylistResetsState() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // playing index 0
        ctrl.presentSettings()
        XCTAssertTrue(ctrl.settingsActive)

        let newList = [Video(title: "New", year: nil, youtube_url: "https://youtu.be/99")]
        ctrl.changePlaylist(id: "new", videos: newList)

        XCTAssertFalse(ctrl.settingsActive)
        XCTAssertEqual(ctrl.playlist.count, 1)
        XCTAssertEqual(ctrl.currentIndex, 0)
        XCTAssertFalse(ctrl.prevEnabled)
        XCTAssertFalse(ctrl.nextEnabled)
        XCTAssertFalse(ctrl.isPlaying)
    }

    // 13 & 14 Google sign-in/out
    func testAuthFlow() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        XCTAssertFalse(ctrl.isAuthenticated)
        ctrl.signIn()
        XCTAssertTrue(ctrl.isAuthenticated)
        ctrl.signOut()
        XCTAssertFalse(ctrl.isAuthenticated)
    }
} 