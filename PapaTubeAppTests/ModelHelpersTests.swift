import XCTest
@testable import PapaTubeApp

final class ModelHelpersTests: XCTestCase {
    func testVideoIDExtraction() {
        let v = Video(title: "t", year: nil, youtube_url: "https://youtu.be/abcXYZ")
        XCTAssertEqual(v.id, "abcXYZ")
    }

    func testPlaylistNextPrev() {
        let vids = (1...3).map { Video(title: "\($0)", year: nil, youtube_url: "https://youtu.be/\($0)") }
        var pl = Playlist(videos: vids)
        XCTAssertTrue(pl.isAtStart)
        pl = pl.next()
        XCTAssertEqual(pl.currentIndex, 1)
        pl = pl.prev()
        XCTAssertEqual(pl.currentIndex, 0)
    }
} 