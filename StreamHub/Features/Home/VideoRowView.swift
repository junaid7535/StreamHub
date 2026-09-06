import SwiftUI

struct VideoRowView: View {
    let video: Video

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.secondary)
                        )

                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                }
            }
            .frame(width: 92, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(video.creatorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VideoRowView(
        video: Video(
            title: "Preview Video",
            creatorName: "Creator",
            streamURL: URL(string: "https://example.com/video.m3u8")!
        )
    )
    .padding()
}
