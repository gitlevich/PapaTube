import SwiftUI
import YouTubePlayerKit

struct VideoPlayerView: View {
    @ObservedObject var player: YouTubePlayer

    var body: some View {
        YouTubePlayerView(player)
            .edgesIgnoringSafeArea(.all)
    }
} 