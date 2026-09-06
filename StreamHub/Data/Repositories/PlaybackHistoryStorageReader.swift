import Foundation
import SwiftData

protocol PlaybackHistoryStorageReading: Sendable {
    func fetchPlaybackHistories(using context: ModelContext) throws -> [PlaybackHistory]
}

struct SwiftDataPlaybackHistoryStorageReader: PlaybackHistoryStorageReading {
    func fetchPlaybackHistories(using context: ModelContext) throws -> [PlaybackHistory] {
        let descriptor = FetchDescriptor<PlaybackHistory>(
            sortBy: [SortDescriptor(\PlaybackHistory.watchedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
