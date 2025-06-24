#if canImport(ViewInspector)
import XCTest
import ViewInspector
@testable import PapaTubeApp

@MainActor final class RecommendationGridViewTests: XCTestCase {

    func testRendersCorrectNumberOfThumbnails() throws {
        let vids = (1...4).map { Video(title: "\($0)", year: nil, youtube_url: "https://youtu.be/id\($0)") }
        let grid = RecommendationGrid(videos: vids, onSelect: { _ in })

        let forEach = try grid.inspect().scrollView().lazyVGrid().forEach()
        XCTAssertEqual(forEach.count, vids.count)
    }

    func testTapCallsOnSelect() throws {
        let vids = [Video(title: "A", year: nil, youtube_url: "https://youtu.be/a"),
                     Video(title: "B", year: nil, youtube_url: "https://youtu.be/b")]
        var selected: Video? = nil
        let grid = RecommendationGrid(videos: vids, onSelect: { selected = $0 })

        let first = try grid.inspect().scrollView().lazyVGrid().forEach().element(at: 0)
        try first.callOnTapGesture()
        XCTAssertEqual(selected?.id, vids[0].id)
    }
}

extension RecommendationGrid: Inspectable {}
#endif 