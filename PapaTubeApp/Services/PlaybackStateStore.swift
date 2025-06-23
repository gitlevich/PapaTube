import Foundation
import Combine

final class PlaybackStateStore: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var positions: [String: Double] = [:] // videoId : seconds
    @Published var playingStates: [String: Bool] = [:] // videoId : wasPlaying

    private let defaults = UserDefaults.standard
    private let keyIndex = "currentIndex"
    private let keyPositions = "positions"
    private let keyPlaying = "playingStates"

    init() {
        currentIndex = defaults.integer(forKey: keyIndex)
        if let data = defaults.data(forKey: keyPositions),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
            positions = dict
        }
        if let data = defaults.data(forKey: keyPlaying),
           let dict = try? JSONDecoder().decode([String: Bool].self, from: data) {
            playingStates = dict
        }
    }

    func updatePosition(for videoID: String, seconds: Double) {
        positions[videoID] = seconds
        save()
    }

    func updatePlaying(for videoID: String, isPlaying: Bool) {
        playingStates[videoID] = isPlaying
        save()
    }

    func save() {
        defaults.set(currentIndex, forKey: keyIndex)
        if let data = try? JSONEncoder().encode(positions) {
            defaults.set(data, forKey: keyPositions)
        }
        if let data = try? JSONEncoder().encode(playingStates) {
            defaults.set(data, forKey: keyPlaying)
        }
    }
} 