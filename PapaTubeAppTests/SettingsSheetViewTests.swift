#if canImport(ViewInspector)
import XCTest
import ViewInspector
@testable import PapaTubeApp

@MainActor final class SettingsSheetViewTests: XCTestCase {

    private var savedID: String? = nil

    override func setUp() {
        savedID = UserDefaults.standard.string(forKey: "ytPlaylistID")
    }

    override func tearDown() {
        if let id = savedID {
            UserDefaults.standard.setValue(id, forKey: "ytPlaylistID")
        } else {
            UserDefaults.standard.removeObject(forKey: "ytPlaylistID")
        }
    }

    func makeAppModel(initialID: String) -> AppModel {
        struct StubSession: NetworkSession {
            func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                throw URLError(.badURL) // never called
            }
        }
        let store = PlaylistStore(session: StubSession())
        store.setPlaylistInput(initialID)
        return AppModel(player: AppModelSpecTests.StubPlayer(), playlistStore: store)
    }

    func testTextFieldReflectsPlaylistID() throws {
        let app = makeAppModel(initialID: "INIT")
        let view = SettingsSheet().environmentObject(app)

        // WHEN & THEN – TextField shows existing ID
        let tf = try view.inspect().navigationView().list().textField(0)
        XCTAssertEqual(try tf.text(), "INIT")
    }

    func testEnteringNewIDUpdatesStore() throws {
        let app = makeAppModel(initialID: "OLD")
        let view = SettingsSheet().environmentObject(app)
        let store = app.playlistStore

        let tf = try view.inspect().navigationView().list().textField(0)
        try tf.setInput("NEWID")
        try tf.callOnCommit()

        XCTAssertEqual(store.playlistID, "NEWID")
    }
}

extension SettingsSheet: Inspectable {}
#endif 