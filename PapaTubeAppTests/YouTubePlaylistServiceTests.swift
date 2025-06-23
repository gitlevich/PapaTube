import XCTest
@testable import PtubeApp

final class PlaylistStoreTests: XCTestCase {
    func testExtractPlaylistIDFromUrl() {
        let svc = PlaylistStore()
        let url = "https://youtube.com/playlist?list=PL4dWJMOQ_a1Tb4-nXkAfYj9AKs6QiDRv5&si=FiNNnsyhChFiVxw8"
        let id = svc.extractPlaylistID(from: url)
        XCTAssertEqual(id, "PL4dWJMOQ_a1Tb4-nXkAfYj9AKs6QiDRv5")
    }

    func testExtractPlaylistIDFromRaw() {
        let svc = PlaylistStore()
        let raw = "PL4dWJMOQ_a1Tb4-nXkAfYj9AKs6QiDRv5"
        XCTAssertEqual(svc.extractPlaylistID(from: raw), raw)
    }
} 