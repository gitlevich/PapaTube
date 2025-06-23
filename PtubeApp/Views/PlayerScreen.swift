import SwiftUI
import YouTubePlayerKit
import Combine

struct PlayerScreen: View {
    @StateObject private var playlistService = PlaylistService()
    @StateObject private var playbackState = PlaybackStateStore()
    @State private var showControls = true
    private let buttonSize: CGFloat = 60
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var isScrubbing = false
    @State private var isPausedOverlayVisible = false
    @StateObject private var player = YouTubePlayer(
        source: .video(id: ""),
        parameters: .init(autoPlay: true,
                          showControls: false,
                          showFullscreenButton: false,
                          showCaptions: false)
    )

    var body: some View {
        ZStack {
            if playlistService.videos.indices.contains(playbackState.currentIndex) {
                VideoPlayerView(player: player)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        playbackState.save()
                    }
            } else {
                ProgressView("Loading playlist…")
            }

            if isPausedOverlayVisible {
                Color.black.opacity(0.8)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if showControls {
                controlsOverlay
            }
        }
        .onTapGesture {
            showControls.toggle()
        }
        .onAppear {
            playlistService.sync()
            loadCurrent()
        }
        .onChange(of: playbackState.currentIndex) { _ in
            loadCurrent()
        }
        .onReceive(player.currentTimePublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { seconds in
            if !isScrubbing {
                currentTime = seconds
                if let video = playlistService.videos[safe: playbackState.currentIndex] {
                    playbackState.updatePosition(for: video.id, seconds: seconds)
                }
            }
        }
        .onReceive(player.durationPublisher
            .map { $0.converted(to: UnitDuration.seconds).value }
            .eraseToAnyPublisher()) { dur in
                duration = max(dur, 1)
        }
        .onReceive(player.playbackStatePublisher.eraseToAnyPublisher()) { state in
            if state == .ended {
                next()
            }
            isPausedOverlayVisible = (state == .paused)
        }
    }

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { playlistService.sync() }) {
                    Image(systemName: "arrow.triangle.2.circlepath").padding()
                }
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
                .accentColor(.red)
                .padding(.horizontal)
            }

            HStack(spacing: 40) {
                Button(action: prev) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }
                Button(action: playPause) {
                    Image(systemName: "playpause.fill")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }
                Button(action: next) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }
            }.padding(.bottom, 32)
        }
        .foregroundColor(.white)
        .shadow(radius: 4)
    }

    private func prev() {
        playbackState.currentIndex = max(0, playbackState.currentIndex - 1)
    }

    private func next() {
        playbackState.currentIndex = min(playlistService.videos.count - 1, playbackState.currentIndex + 1)
    }

    private func playPause() {
        Task {
            if let state = try? await player.getPlaybackState(), state == .playing {
                try? await player.pause()
            } else {
                try? await player.play()
            }
        }
    }

    private func loadCurrent() {
        guard playlistService.videos.indices.contains(playbackState.currentIndex) else { return }
        let video = playlistService.videos[playbackState.currentIndex]
        Task {
            try? await player.load(source: .video(id: video.id))
            if let resume = playbackState.positions[video.id], resume > 2 {
                let target = Measurement(value: resume, unit: UnitDuration.seconds)
                try? await player.seek(to: target, allowSeekAhead: true)
            }
            try? await player.play()
        }
    }
} 