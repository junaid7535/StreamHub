import Foundation
import SwiftData

@Model
final class PlaybackHistory {
    var videoID: UUID
    var watchedAt: Date
    var lastPlaybackTime: Double

    init(videoID: UUID, watchedAt: Date = .now, lastPlaybackTime: Double = 0) {
        self.videoID = videoID
        self.watchedAt = watchedAt
        self.lastPlaybackTime = lastPlaybackTime
    }
}
