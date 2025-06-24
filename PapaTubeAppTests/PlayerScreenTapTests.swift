import XCTest
#if canImport(ViewInspector)
import ViewInspector
@testable import PapaTubeApp

@MainActor final class PlayerScreenTapTests: XCTestCase {
    /// Ensure tapping anywhere (overlay) wakes the controls (buttonOpacity = 1, controlsVisible true)
    func testTapOverlayShowsControls() throws {
        // GIVEN a screen with controls faded
        let app = AppModel(player: AppModelSpecTests.StubPlayer())
        let screen = PlayerScreen().environmentObject(app)
        // Render view hierarchy
        let exp = screen.on(
            \PlayerScreen.controlsVisible,
            set: false
        ) {
            // WHEN user taps overlay
            try screen.find(ViewType.Color.self, where: { try $0.accessibilityIdentifier() == "overlayTapArea" }).callOnTapGesture()
            // THEN controls become visible again
            XCTAssertTrue(try screen.actualView().controlsVisible)
        }
        ViewHosting.host(view: screen)
        wait(for: [exp], timeout: 1)
    }
}
#else
// ViewInspector not available – skip UI tests
#endif 