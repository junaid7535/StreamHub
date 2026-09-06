import Foundation
import SwiftData
import Testing
@testable import StreamHub

@MainActor
struct BookmarksViewModelTests {
    @Test
    func loadIfNeeded_withNoBookmarks_setsEmptyState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let viewModel = BookmarksViewModel()

        viewModel.loadIfNeeded(using: context)

        #expect(viewModel.state == .empty)
    }

    @Test
    func loadIfNeeded_withBookmark_setsLoadedState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let videoID = UUID()
        let savedAt = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(
            BookmarkVideo(
                videoID: videoID,
                title: "Sample Video",
                creatorName: "Sample Creator",
                createdAt: savedAt
            )
        )

        let viewModel = BookmarksViewModel()
        viewModel.loadIfNeeded(using: context)

        guard case .loaded(let items) = viewModel.state else {
            Issue.record("Expected loaded state.")
            return
        }

        #expect(items.count == 1)
        #expect(items.first?.id == videoID)
        #expect(items.first?.title == "Sample Video")
        #expect(items.first?.creatorName == "Sample Creator")
        #expect(items.first?.createdAt == savedAt)
    }

    @Test
    func removeBookmarks_withSingleLoadedItem_setsEmptyState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let item = BookmarkVideo(
            videoID: UUID(),
            title: "Delete Target",
            creatorName: "Tester"
        )
        context.insert(item)

        let viewModel = BookmarksViewModel()
        viewModel.loadIfNeeded(using: context)

        guard case .loaded(let loadedItems) = viewModel.state else {
            Issue.record("Expected loaded state before delete.")
            return
        }

        viewModel.removeBookmarks(at: IndexSet(integer: 0), from: loadedItems, using: context)

        #expect(viewModel.state == .empty)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            BookmarkVideo.self,
            PlaybackHistory.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
