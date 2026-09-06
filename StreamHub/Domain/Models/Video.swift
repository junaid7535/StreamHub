import Foundation

struct Video: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let title: String
    let creatorName: String
    let thumbnailURL: URL?
    let streamURL: URL
    let durationSeconds: Int
    let category: String

    init(
        id: UUID = UUID(),
        title: String,
        creatorName: String,
        thumbnailURL: URL? = nil,
        streamURL: URL,
        durationSeconds: Int = 0,
        category: String = "General"
    ) {
        self.id = id
        self.title = title
        self.creatorName = creatorName
        self.thumbnailURL = thumbnailURL
        self.streamURL = streamURL
        self.durationSeconds = durationSeconds
        self.category = category
    }
}
