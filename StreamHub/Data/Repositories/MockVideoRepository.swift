import Foundation

struct MockVideoRepository: VideoRepository, VideoCatalogProviding {
    static let tokyoNightWalkID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let morningCodingSessionID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    enum Mode: Sendable {
        case success([Video])
        case empty
        case failure(APIError)
    }

    private let mode: Mode
    private let delayNanoseconds: UInt64

    init(mode: Mode = .success(Self.defaultVideos), delayNanoseconds: UInt64 = 300_000_000) {
        self.mode = mode
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchVideos() async throws -> [Video] {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch mode {
        case .success(let videos):
            return videos
        case .empty:
            return []
        case .failure(let error):
            throw error
        }
    }

    static var defaultVideos: [Video] {
        [
            Video(
                id: Self.tokyoNightWalkID,
                title: "Tokyo Night Walk",
                creatorName: "StreamHub Originals",
                thumbnailURL: URL(string: "https://picsum.photos/id/1011/368/207"),
                streamURL: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
                durationSeconds: 1_420,
                category: "Travel"
            ),
            Video(
                id: Self.morningCodingSessionID,
                title: "Morning Coding Session",
                creatorName: "Swift Cafe",
                thumbnailURL: URL(string: "https://picsum.photos/id/1025/368/207"),
                streamURL: URL(string: "https://test-streams.mux.dev/tos_ismc/main.m3u8")!,
                durationSeconds: 2_100,
                category: "Education"
            )
        ]
    }

    var videoCatalog: [UUID: Video] {
        let sourceVideos: [Video]
        switch mode {
        case .success(let videos):
            sourceVideos = videos
        case .empty, .failure:
            sourceVideos = Self.defaultVideos
        }

        return Dictionary(uniqueKeysWithValues: sourceVideos.map { ($0.id, $0) })
    }
}
