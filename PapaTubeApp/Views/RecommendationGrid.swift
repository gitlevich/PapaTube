import SwiftUI

struct RecommendationGrid: View {
    let videos: [Video]
    let onSelect: (Video) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videos) { video in
                    AsyncImage(url: thumbnailURL(for: video)) { phase in
                        if let img = phase.image {
                            img
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } else if phase.error != nil {
                            Color.gray
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()
                    .overlay(
                        Text(video.title)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            , alignment: .bottom
                    )
                    .onTapGesture { onSelect(video) }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func thumbnailURL(for video: Video) -> URL? {
        URL(string: "https://img.youtube.com/vi/\(video.id)/hqdefault.jpg")
    }
} 