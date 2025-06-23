import SwiftUI
import Combine
import YouTubePlayerKit

/// Root state container – owns playlist fetching, playback state persistence and the FSM.
@MainActor
final class AppModel: ObservableObject {
    // MARK: - Sub-objects
    let playlistService = YouTubePlaylistService()
    let playbackStore = PlaybackStateStore()
    let player: YouTubePlayer
    let fsm: PlaybackStateMachine

    // Surface playlist so views can simply observe one property.
    @Published private(set) var playlist: [Video] = []

    private var bag = Set<AnyCancellable>()

    init() {
        player = YouTubePlayer(
            source: .video(id: ""),
            parameters: .init(autoPlay: false,
                              showControls: false,
                              showFullscreenButton: false,
                              showCaptions: false))

        fsm = PlaybackStateMachine(playlist: playlistService, player: player)

        // Relay playlist updates.
        playlistService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] st in
                if case let .loaded(vids) = st {
                    self?.playlist = vids
                }
            }
            .store(in: &bag)

        // Start with cached/remote playlist.
        Task { await playlistService.refresh() }
    }

    // MARK: - User intents (simply forward)
    func next()  { fsm.next() }
    func prev()  { fsm.prev() }
    func togglePlayPause() { fsm.togglePlayPause() }
    func refreshPlaylist() { Task { await playlistService.refresh() } }

    // Persist when app backgrounds.
    func save() { playbackStore.save() }
} 