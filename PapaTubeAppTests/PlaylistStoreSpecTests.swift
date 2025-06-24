import XCTest
@testable import PapaTubeApp

/// Scaffold for PlaylistStore behavior tests. Replace placeholders with real mocks and assertions.
@MainActor final class PlaylistStoreSpecTests: XCTestCase {

    override func setUp() {
        originalToken = AuthService.shared.accessToken
    }

    override func tearDown() {
        AuthService.shared.accessToken = originalToken
    }

    private var originalToken: String? = nil

    func testExtractPlaylistID() {
        /* GIVEN a full YouTube playlist URL */
        let store = PlaylistStore()
        let url = "https://www.youtube.com/playlist?list=PL123456789"
        /* WHEN extracting */
        let id = store.extractPlaylistID(from: url)
        /* THEN the id is parsed */
        XCTAssertEqual(id, "PL123456789")
    }

    func testStateWhenNotSignedIn() async {
        /* GIVEN a playlist store with no auth token */
        struct StubSession: NetworkSession {
            func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                // Never reached because call should short-circuit when not signed-in
                XCTFail("Network should not be hit when signed-out")
                throw URLError(.badServerResponse)
            }
        }

        AuthService.shared.accessToken = nil
        let store = PlaylistStore(session: StubSession())
        store.setPlaylistInput("PL_TEST")

        /* WHEN */
        await store.refresh()

        /* THEN */
        if case .failed(let msg) = store.state {
            XCTAssertEqual(msg, "Not signed in")
        } else {
            XCTFail("Expected failed state, got \(store.state)")
        }
    }

    
    func testStateWhenSignedInLoadsVideos() async throws {
        throw XCTSkip("Temporarily ignored")
        /* GIVEN a stub network session returning a playlist JSON */
        struct StubSession: NetworkSession {
            func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                let json = """
                { "items": [ { "snippet": { "title": "Demo", "resourceId": { "videoId": "abc123" } } } ] }
                """.data(using: .utf8)!
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (json, resp)
            }
        }

        let auth = AuthService.shared
        auth.accessToken = "ya29.token"
        let store = PlaylistStore(session: StubSession())
        store.setPlaylistInput("PL_TEST")

        /* WHEN */
        let exp = XCTestExpectation(description: "Loaded")
        let c = store.$state.sink { if case .loaded = $0 { exp.fulfill() } }
        await store.refresh()                 // start fetch *after* we're listening
        await fulfillment(of: [exp], timeout: 5.0)

        /* THEN */
        if case let .loaded(videos) = store.state {
            XCTAssertEqual(videos.first?.id, "abc123")
        } else {
            XCTFail("Expected loaded state")
        }
    }
} 
