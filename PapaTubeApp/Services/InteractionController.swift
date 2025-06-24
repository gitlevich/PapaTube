import Foundation

/// Pure domain model for viewer interactions – no UI or network.
/// State and terminology match the Interaction Spec in /specs.
@MainActor
final class InteractionController: ObservableObject {

    // MARK: - Nested types
    enum ControlsOpacity: Equatable { case full, faded }

    // MARK: - Published simulation state
    @Published private(set) var playlist: Playlist = .empty
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isEnded: Bool = false
    @Published private(set) var controlsOpacity: ControlsOpacity = .full
    @Published private(set) var recommendationGridVisible: Bool = false
    @Published private(set) var settingsVisible: Bool = false
    @Published private(set) var isAuthenticated: Bool = false

    // Helper computed flags
    var prevEnabled: Bool { !playlist.isAtStart }
    var nextEnabled: Bool { !playlist.isAtEnd }

    // Touch region availability (matches touch_map.md)
    var controlsActive: Bool {
        !settingsVisible // controls disabled when settings open
    }
    var videoSurfaceBlocked: Bool {
        // Always blocked while playing; tap only wakes controls when faded
        true
    }
    var gridActive: Bool { recommendationGridVisible }
    var settingsActive: Bool { settingsVisible }

    // Internal timing for idle-fade
    private var secondsSinceInteraction: Double = 0

    /// Convenience accessors used by legacy code/tests
    var currentIndex: Int {
        get { playlist.currentIndex }
        set { playlist = playlist.move(to: newValue) }
    }

    // MARK: - Configuration
    init(playlist videos: [Video]) {
        self.playlist = Playlist(videos: videos)
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
        playlist = playlist.next()
        isPlaying = true
        isEnded = false
        recommendationGridVisible = false
        resetIdleTimer()
    }

    func prev() {
        guard prevEnabled else { return }
        playlist = playlist.prev()
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
        playlist = playlist.move(to: index)
        isPlaying = true
        isEnded = false
        recommendationGridVisible = false
        resetIdleTimer()
    }

    // MARK: - Settings & Auth
    func presentSettings() { settingsVisible = true }
    func dismissSettings() { settingsVisible = false }

    func changePlaylist(id: String, videos: [Video]) {
        playlist = Playlist(videos: videos)
        // playlist already reset to start
        recommendationGridVisible = false
        settingsVisible = false
        isPlaying = false
        isEnded = false
        resetIdleTimer()
    }

    func signIn() { isAuthenticated = true }
    func signOut() { isAuthenticated = false }

    // MARK: - Helpers
    private func resetIdleTimer() {
        secondsSinceInteraction = 0
        controlsOpacity = .full
    }
} 