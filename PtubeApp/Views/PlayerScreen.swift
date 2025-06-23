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
    private var fsm: PlaybackStateMachine { app.fsm }
    private var playbackStateStore: PlaybackStateStore { app.playbackStore }

    var body: some View {
        ZStack {
            if playlistService.videos.indices.contains(fsm.currentIndex) {
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

            controlsOverlay
                .zIndex(2)

            // Block touches that are outside our controls
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .zIndex(1)

            // Dim the iOS home indicator area – static, no fade
            Color.black.opacity(0.4)
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(false)
                .zIndex(1)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .onAppear {
            app.refreshPlaylist()
            fsm.load(index: fsm.currentIndex)
        }
        .onChange(of: fsm.currentIndex) { _ in
            loadCurrent()
        }
        .onChange(of: app.playlist) { _ in
            if fsm.currentIndex >= playlistService.videos.count {
                fsm.load(index: 0)
            } else {
                loadCurrent()
            }
        }
        .onReceive(player.currentTimePublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { seconds in
            if !isScrubbing {
                currentTime = seconds
                if let video = playlistService.videos[safe: fsm.currentIndex] {
                    playbackStateStore.updatePosition(for: video.id, seconds: seconds)
                }
            }
        }
        .onReceive(player.durationPublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { dur in
                duration = max(dur, 1)
        }
        .onChange(of: fsm.mode) { newMode in
            switch newMode {
            case .playing:
                if let video = playlistService.videos[safe: fsm.currentIndex] {
                    playbackStateStore.updatePlaying(for: video.id, isPlaying: true)
                }
                extraBottom = 0
                controlsLocked = false
                buttonOpacity = 1
                scheduleButtonFade()
                isPausedOverlayVisible = false
            case .paused, .idle, .loading:
                if let video = playlistService.videos[safe: fsm.currentIndex] {
                    playbackStateStore.updatePlaying(for: video.id, isPlaying: false)
                }
                fadeWork?.cancel()
                withAnimation { buttonOpacity = 1 }
                if case .paused = newMode {
                    isPausedOverlayVisible = true
                } else {
                    isPausedOverlayVisible = false
                }
            case .ended:
                if fsm.currentIndex < playlistService.videos.count - 1 {
                    fsm.next()
                } else {
                    controlsVisible = true
                    controlsLocked = true
                    extraBottom = 120
                }
                withAnimation { buttonOpacity = 1 }
                isPausedOverlayVisible = false
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

            // Scrub bar
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

            let atStart = fsm.atStart
            let atEnd   = fsm.atEnd && !playlistService.videos.isEmpty

            HStack(spacing: 40) {
                Button(action: { fsm.prev() }) {
                    Image(systemName: "backward.end")
                        .font(.system(size: buttonSize, weight: .heavy))
                }
                .buttonStyle(.plain)
                .opacity(atStart ? 0.3 : 1.0)
                .disabled(atStart)

                Button(action: { fsm.togglePlayPause() }) {
                    Image(systemName: fsm.isPlaying ? "pause" : "play")
                        .font(.system(size: buttonSize, weight: .heavy))
                }.buttonStyle(.plain)

                Button(action: { fsm.next() }) {
                    Image(systemName: "forward.end")
                        .font(.system(size: buttonSize, weight: .heavy))
                }
                .buttonStyle(.plain)
                .opacity(atEnd ? 0.3 : 1.0)
                .disabled(atEnd)
            }
            .padding(.bottom, 32 + extraBottom)
        }
        .shadow(radius: 4)
        .foregroundColor(Color.white.opacity(buttonOpacity))
    }

    private func scheduleButtonFade() {
        fadeWork?.cancel()
        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.4)) { buttonOpacity = 0.15 }
        }
        fadeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func loadCurrent() {
        guard playlistService.videos.indices.contains(fsm.currentIndex) else { return }
        let video = playlistService.videos[fsm.currentIndex]
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

        fsm.load(index: fsm.currentIndex)
    }
}

// MARK: - End of PlayerScreen 
