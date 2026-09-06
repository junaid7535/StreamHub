import Foundation
import SwiftData

@Model
final class BookmarkVideo {
    @Attribute(.unique) var videoID: UUID
    var title: String
    var creatorName: String
    var createdAt: Date

    init(videoID: UUID, title: String, creatorName: String, createdAt: Date = .now) {
        self.videoID = videoID
        self.title = title
        self.creatorName = creatorName
        self.createdAt = createdAt
    }
}
