import Foundation
import Combine

final class PlaybackStateStore: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var positions: [String: Double] = [:] // videoId : seconds

    private let defaults = UserDefaults.standard
    private let keyIndex = "currentIndex"
    private let keyPositions = "positions"

    init() {
        currentIndex = defaults.integer(forKey: keyIndex)
        if let data = defaults.data(forKey: keyPositions),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
            positions = dict
        }
    }

    func updatePosition(for videoID: String, seconds: Double) {
        positions[videoID] = seconds
        save()
    }

    func save() {
        defaults.set(currentIndex, forKey: keyIndex)
        if let data = try? JSONEncoder().encode(positions) {
            defaults.set(data, forKey: keyPositions)
        }
    }
} 