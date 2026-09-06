import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class DetailViewModel {
    let video: Video

    private(set) var isBookmarked = false
    private(set) var errorMessage: String?
    @ObservationIgnored
    private let relatedVideoCatalog: [Video]

    init(
        video: Video,
        relatedVideoCatalog: [Video] = MockVideoRepository.defaultVideos
    ) {
        self.video = video
        self.relatedVideoCatalog = relatedVideoCatalog
    }

    var relatedVideos: [Video] {
        rankedRelatedVideos(limit: 3)
    }

    private func rankedRelatedVideos(limit: Int) -> [Video] {
        relatedVideoCatalog
            .enumerated()
            .filter { _, candidate in
                candidate.id != video.id
            }
            .map { index, candidate in
                RelatedVideoCandidate(
                    video: candidate,
                    score: relatedScore(for: candidate),
                    catalogOrder: index
                )
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }

                let titleOrder = lhs.video.title.localizedCaseInsensitiveCompare(rhs.video.title)
                if titleOrder != .orderedSame {
                    return titleOrder == .orderedAscending
                }

                return lhs.catalogOrder < rhs.catalogOrder
            }
            .prefix(limit)
            .map(\.video)
    }

    private func relatedScore(for candidate: Video) -> Int {
        var score = 0
        if candidate.creatorName == video.creatorName {
            score += 100
        }
        return score
    }

    func refreshBookmarkState(using context: ModelContext) {
        let videoID = video.id
        let descriptor = FetchDescriptor<BookmarkVideo>(
            predicate: #Predicate { bookmark in
                bookmark.videoID == videoID
            }
        )

        do {
            isBookmarked = try context.fetch(descriptor).isEmpty == false
        } catch {
            errorMessage = "Failed to load bookmark status."
        }
    }

    func toggleBookmark(using context: ModelContext) {
        let videoID = video.id
        let descriptor = FetchDescriptor<BookmarkVideo>(
            predicate: #Predicate { bookmark in
                bookmark.videoID == videoID
            }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
                isBookmarked = false
            } else {
                let bookmark = BookmarkVideo(
                    videoID: videoID,
                    title: video.title,
                    creatorName: video.creatorName
                )
                context.insert(bookmark)
                isBookmarked = true
            }

            try context.save()
        } catch {
            refreshBookmarkState(using: context)
            errorMessage = "Failed to update bookmark."
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

private struct RelatedVideoCandidate {
    let video: Video
    let score: Int
    let catalogOrder: Int
}
