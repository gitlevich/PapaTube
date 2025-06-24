import Foundation

/// Immutable view of a YouTube playlist plus current selection.
struct Playlist: Equatable, Hashable {
    var videos: [Video]
    var currentIndex: Int = 0

    var current: Video? { videos.indices.contains(currentIndex) ? videos[currentIndex] : nil }
    var isAtStart: Bool { currentIndex <= 0 }
    var isAtEnd: Bool { currentIndex >= videos.count - 1 }
    var count: Int { videos.count }
    var isEmpty: Bool { videos.isEmpty }
    var indices: Range<Int> { videos.indices }

    func next() -> Playlist {
        guard !isAtEnd else { return self }
        var copy = self
        copy.currentIndex += 1
        return copy
    }

    func prev() -> Playlist {
        guard !isAtStart else { return self }
        var copy = self
        copy.currentIndex -= 1
        return copy
    }

    func move(to index: Int) -> Playlist {
        guard videos.indices.contains(index) else { return self }
        var copy = self
        copy.currentIndex = index
        return copy
    }

    static var empty: Playlist { Playlist(videos: []) }
} 