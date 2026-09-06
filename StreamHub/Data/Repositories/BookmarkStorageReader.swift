import Foundation
import SwiftData

protocol BookmarkStorageReading: Sendable {
    func fetchBookmarks(using context: ModelContext) throws -> [BookmarkVideo]
}

struct SwiftDataBookmarkStorageReader: BookmarkStorageReading {
    func fetchBookmarks(using context: ModelContext) throws -> [BookmarkVideo] {
        let descriptor = FetchDescriptor<BookmarkVideo>(
            sortBy: [SortDescriptor(\BookmarkVideo.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
