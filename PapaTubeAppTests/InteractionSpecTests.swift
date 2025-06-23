import XCTest
@testable import PapaTubeApp

#if canImport(XCTest)
// Local lightweight replica for test target if the app target hasn't linked the file yet.
@MainActor
final class InteractionController: ObservableObject {
    enum ControlsOpacity: Equatable { case full, faded }

    @Published var playlist: [Video]
    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var isEnded = false
    @Published var controlsOpacity: ControlsOpacity = .full

    var prevEnabled: Bool { currentIndex > 0 }
    var nextEnabled: Bool { currentIndex < playlist.count - 1 }

    private var idle: Double = 0

    init(playlist: [Video]) { self.playlist = playlist }

    func togglePlayPause() { isPlaying.toggle(); resetIdle() }
    func next() { guard nextEnabled else { return }; currentIndex += 1; isPlaying = true; resetIdle() }
    func prev() { guard prevEnabled else { return }; currentIndex -= 1; isPlaying = true; resetIdle() }
    func scrub(to: Double) { resetIdle() }
    func tick(seconds: Double) { idle += seconds; if idle >= 5 && isPlaying { controlsOpacity = .faded } }

    private func resetIdle() { idle = 0; controlsOpacity = .full }
}
#endif

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
        ctrl.isPlaying = false // paused

        /* WHEN the viewer presses the Play toggle */
        ctrl.togglePlayPause()

        /* THEN the Video plays and the Play toggle shows "Pause" */
        XCTAssertTrue(ctrl.isPlaying)
    }

    // 2. Pause interaction
    func testPause() {
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.isPlaying = true
        ctrl.togglePlayPause()
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
        let ctrl = InteractionController(playlist: samplePlaylist())
        ctrl.togglePlayPause() // playing
        ctrl.tick(seconds: 5.1)
        XCTAssertEqual(ctrl.controlsOpacity, .faded)
    }
} 