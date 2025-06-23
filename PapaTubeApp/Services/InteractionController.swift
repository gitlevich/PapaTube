import Foundation

/// Pure domain model for viewer interactions – no UI or network.
/// State and terminology match the Interaction Spec in /specs.
@MainActor
final class InteractionController: ObservableObject {

    // MARK: - Nested types
    enum ControlsOpacity: Equatable { case full, faded }

    // MARK: - Published simulation state
    @Published private(set) var playlist: [Video] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isEnded: Bool = false
    @Published private(set) var controlsOpacity: ControlsOpacity = .full
    @Published private(set) var recommendationGridVisible: Bool = false

    // Helper computed flags
    var prevEnabled: Bool { currentIndex > 0 }
    var nextEnabled: Bool { currentIndex < playlist.count - 1 }

    // Internal timing for idle-fade
    private var secondsSinceInteraction: Double = 0

    // MARK: - Configuration
    init(playlist: [Video]) {
        self.playlist = playlist
    }

    // MARK: - Inputs (reflect spec actions)
    func togglePlayPause() {
        guard !playlist.isEmpty else { return }
        isPlaying.toggle()
        if isPlaying { isEnded = false }
        resetIdleTimer()
    }

    func next() {
        guard nextEnabled else { return }
        currentIndex += 1
        isPlaying = true
        isEnded = false
        recommendationGridVisible = false
        resetIdleTimer()
    }

    func prev() {
        guard prevEnabled else { return }
        currentIndex -= 1
        isPlaying = true
        isEnded = false
        recommendationGridVisible = false
        resetIdleTimer()
    }

    func scrub(to targetSeconds: Double) {
        // For now just counts as an interaction.
        resetIdleTimer()
    }

    func tick(seconds: Double) { // advance simulated time
        secondsSinceInteraction += seconds
        if secondsSinceInteraction >= 5, isPlaying {
            controlsOpacity = .faded // idle-fade
        }
    }

    func wakeControls() {
        resetIdleTimer()
    }

    func videoEnded() {
        isPlaying = false
        isEnded = true
        controlsOpacity = .full
        recommendationGridVisible = true
    }

    func selectVideoFromGrid(index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index
        isPlaying = true
        isEnded = false
        recommendationGridVisible = false
        resetIdleTimer()
    }

    // MARK: - Helpers
    private func resetIdleTimer() {
        secondsSinceInteraction = 0
        controlsOpacity = .full
    }
} 