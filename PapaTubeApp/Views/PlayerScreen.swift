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
    private var playlistService: YouTubePlaylistService { app.playlistService }
    private var player: YouTubePlayer { app.player }
    private var playbackStateStore: PlaybackStateStore { app.playbackStore }

    var body: some View {
        ZStack {
            if playlistService.videos.indices.contains(app.currentIndex) {
                VideoPlayerView(player: player)
                    .allowsHitTesting(false)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        playbackStateStore.save()
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

            // Block touches outside controls only during normal playback
            if !app.isEnded {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
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
            if app.currentIndex >= playlistService.videos.count {
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
                if let video = playlistService.videos[safe: app.currentIndex] {
                    playbackStateStore.updatePosition(for: video.id, seconds: seconds)
                }
            }
        }
        .onReceive(player.durationPublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { dur in
                duration = max(dur, 1)
        }
        .onChange(of: app.isPlaying) { playing in
            if playing {
                if let video = playlistService.videos[safe: app.currentIndex] {
                    playbackStateStore.updatePlaying(for: video.id, isPlaying: true)
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
                if let video = playlistService.videos[safe: app.currentIndex] {
                    playbackStateStore.updatePlaying(for: video.id, isPlaying: false)
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
            let atEnd   = (app.currentIndex >= max(0, playlistService.videos.count - 1)) && !playlistService.videos.isEmpty

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
        guard playlistService.videos.indices.contains(app.currentIndex) else { return }
        let video = playlistService.videos[app.currentIndex]
        // Configure resume point before we hand off to the FSM for actual loading.
        if let resume = playbackStateStore.positions[video.id], resume > 2 {
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
}

// MARK: - End of PlayerScreen 
