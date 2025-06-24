import SwiftUI
import YouTubePlayerKit
import Combine
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct PlayerScreen: View {
    private let buttonSize: CGFloat = 60

    // UI state
    @State private var controlsVisible = true
    @State private var controlsLocked = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var isScrubbing = false
    @State private var isPausedOverlayVisible = false
    @State private var showSettings = false
    @State private var extraBottom: CGFloat = 0
    @State private var buttonOpacity: Double = 1.0
    @State private var fadeWork: DispatchWorkItem?

    @EnvironmentObject var app: AppModel
    private var playlistStore: PlaylistStore { app.playlistStore }
    private var player: YouTubePlayer {
        if let rp = app.player as? RealPlayer { return rp.wrapped }
        // Fallback for future: if stored player is already YouTubePlayer
        if let yp = app.player as? YouTubePlayer { return yp }
        fatalError("Unsupported player type")
    }

    var body: some View {
        ZStack {
            if playlistStore.videos.indices.contains(app.currentIndex) {
                VideoPlayerView(player: player)
                    // Disable touches during normal playback, re-enable when the YouTube end-screen grid appears.
                    .allowsHitTesting(app.isEnded)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        app.save()
                        Task { try? await player.pause() }
                    }
            } else {
                ProgressView("Loading playlist…")
            }

            if isPausedOverlayVisible {
                Color.black
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if controlsVisible {
                controlsOverlay
                    .zIndex(2)
            }

            // Recommendation grid overlay shown when current video finished.
            if app.isEnded {
                RecommendationGrid(
                    videos: recommendationVideos,
                    onSelect: { video in
                        if let idx = playlistStore.videos.firstIndex(of: video) {
                            // Load selected video and start playing immediately.
                            app.isEnded = false
                            app.load(index: idx)
                            app.togglePlayPause()
                        }
                    })
                    .transition(.opacity)
                    .zIndex(3)
            }

            // Block touches outside controls only during normal playback
            if !app.isEnded {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .onTapGesture { wakeControls() }
                    .accessibilityIdentifier("overlayTapArea")
                    .zIndex(1)
            }

            if !app.isEnded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .onAppear {
            app.refreshPlaylist()
            if !app.playlist.isEmpty {
                app.load(index: app.currentIndex)
            }
        }
        .onChange(of: app.currentIndex) { _ in
            // User navigated to a different video – show controls fully then fade again
            buttonOpacity = 1
            scheduleButtonFade()
            loadCurrent()
        }
        .onChange(of: app.playlist) { _ in
            if app.currentIndex >= playlistStore.videos.count {
                app.load(index: 0)
            } else {
                loadCurrent()
            }
        }
        .onReceive(player.currentTimePublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { seconds in
            if !isScrubbing {
                currentTime = seconds
                if let video = playlistStore.videos[safe: app.currentIndex] {
                    app.updatePosition(for: video.id, seconds: seconds)
                }
                // Fallback end-of-video detection – some videos don't emit `.ended`.
                // When we are within the last 0.5 s of the total duration mark the video as ended
                // so that the recommendation grid becomes interactive and the overlay hides.
                if duration > 1, seconds >= duration - 0.5 {
                    if !app.isEnded {
                        app.isEnded = true
                    }
                } else if app.isEnded {
                    // Reset flag if user scrubbed backwards or a new video started
                    app.isEnded = false
                }
            }
        }
        .onReceive(player.durationPublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { dur in
                duration = max(dur, 1)
        }
        .onReceive(player.playbackStatePublisher) { state in
            switch state {
            case .ended:
                app.isEnded = true
            default:
                break
            }
        }
        .onChange(of: app.isPlaying) { playing in
            if playing {
                if let video = playlistStore.videos[safe: app.currentIndex] {
                    app.updatePlaying(for: video.id, isPlaying: true)
                }
                extraBottom = 0
                controlsLocked = false
                buttonOpacity = 1
                scheduleButtonFade()
                // Hide recommendation strip after playback resumes.
                if !app.isEnded { isPausedOverlayVisible = true } else { isPausedOverlayVisible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation { isPausedOverlayVisible = false }
                }
            } else {
                if let video = playlistStore.videos[safe: app.currentIndex] {
                    app.updatePlaying(for: video.id, isPlaying: false)
                }
                fadeWork?.cancel()
                withAnimation { buttonOpacity = 1 }
                if !app.isEnded { isPausedOverlayVisible = true } else { isPausedOverlayVisible = false }
            }
        }
        .onChange(of: app.isEnded) { ended in
            if ended {
                isPausedOverlayVisible = false // allow recommendation grid
                controlsLocked = true
                extraBottom = 120
                controlsVisible = false
            } else {
                controlsLocked = false
                extraBottom = 0
                controlsVisible = true
                buttonOpacity = 1
                scheduleButtonFade()
            }
        }
    }

    // Precomputed list for recommendation grid (skip current video)
    private var recommendationVideos: [Video] {
        playlistStore.videos.enumerated().filter { $0.offset != app.currentIndex }.map { $0.element }
    }

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .padding()
                }.buttonStyle(.plain)
            }
            Spacer()

            // Scrub bar – fades together with buttons
            if duration > 1 {
                Slider(value: Binding(get: { currentTime }, set: { newVal in
                    currentTime = newVal
                }), in: 0...duration, onEditingChanged: { editing in
                    isScrubbing = editing
                    if !editing {
                        let target = Measurement(value: currentTime, unit: UnitDuration.seconds)
                        Task { try? await player.seek(to: target, allowSeekAhead: true) }
                    }
                })
                .accentColor(Color.red.opacity(0.9))
                .padding(.horizontal)
            }

            let atStart = (app.currentIndex == 0)
            let atEnd   = (app.currentIndex >= max(0, playlistStore.videos.count - 1)) && !playlistStore.videos.isEmpty

            // Control buttons (fade separately)
            HStack(spacing: 40) {
                Button(action: { app.prev() }) {
                    Image(systemName: "backward.end")
                        .font(.system(size: buttonSize, weight: .heavy))
                }
                .buttonStyle(.plain)
                .opacity(atStart ? 0.3 : 1.0)
                .disabled(atStart)

                Button(action: { app.togglePlayPause() }) {
                    Image(systemName: app.isPlaying ? "pause" : "play")
                        .font(.system(size: buttonSize, weight: .heavy))
                }.buttonStyle(.plain)

                Button(action: { app.next() }) {
                    Image(systemName: "forward.end")
                        .font(.system(size: buttonSize, weight: .heavy))
                }
                .buttonStyle(.plain)
                .opacity(atEnd ? 0.3 : 1.0)
                .disabled(atEnd)
            }
            .padding(.bottom, 32 + extraBottom)
        }
        .opacity(buttonOpacity) // fade entire overlay (slider + buttons)
        .shadow(radius: 4)
        .foregroundColor(Color.white)
    }

    private func scheduleButtonFade() {
        guard app.isPlaying else { return } // fade only while playback running
        fadeWork?.cancel()
        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.4)) { buttonOpacity = 0.15 }
        }
        fadeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func loadCurrent() {
        guard playlistStore.videos.indices.contains(app.currentIndex) else { return }
        let video = playlistStore.videos[app.currentIndex]
        // Configure resume point before we hand off to the FSM for actual loading.
        if let resume = app.positions[video.id], resume > 2 {
            var params = player.parameters
            params.startTime = Measurement(value: resume, unit: UnitDuration.seconds)
            player.parameters = params
        } else {
            var params = player.parameters
            params.startTime = nil
            player.parameters = params
        }

        app.load(index: app.currentIndex)
    }

    // MARK: - Helper to re-show controls on user tap
    private func wakeControls() {
        guard !controlsLocked else { return }
        withAnimation { buttonOpacity = 1 }
        controlsVisible = true
        scheduleButtonFade()
    }
}

// MARK: - End of PlayerScreen 

#if DEBUG
#if canImport(ViewInspector)
import ViewInspector
extension PlayerScreen: Inspectable {}
#endif
#endif 
