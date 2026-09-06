import Foundation
import SwiftData
import Testing
@testable import StreamHub

@MainActor
struct PlaybackHistoryViewModelTests {
    @Test
    func loadIfNeeded_withNoHistories_setsEmptyState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let viewModel = PlaybackHistoryViewModel(videoCatalog: makeVideoCatalog())

        viewModel.loadIfNeeded(using: context)

        #expect(viewModel.state == .empty)
    }

    @Test
    func loadIfNeeded_withHistory_setsLoadedState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let videoID = MockVideoRepository.tokyoNightWalkID
        let watchedAt = Date(timeIntervalSince1970: 1_700_000_123)
        let playbackTime = 42.5
        context.insert(
            PlaybackHistory(
                videoID: videoID,
                watchedAt: watchedAt,
                lastPlaybackTime: playbackTime
            )
        )

        let viewModel = PlaybackHistoryViewModel(videoCatalog: makeVideoCatalog())
        viewModel.loadIfNeeded(using: context)

        guard case .loaded(let items) = viewModel.state else {
            Issue.record("Expected loaded state.")
            return
        }

        #expect(items.count == 1)
        #expect(items.first?.videoID == videoID)
        #expect(items.first?.videoTitle == "Tokyo Night Walk")
        #expect(items.first?.creatorName == "StreamHub Originals")
        #expect(items.first?.watchedAt == watchedAt)
        #expect(items.first?.lastPlaybackTime == playbackTime)
        #expect(items.first?.resolvedVideo?.id == videoID)
    }

    @Test
    func loadIfNeeded_withUnknownVideoID_usesFallbackMetadata() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let unknownVideoID = UUID()
        context.insert(
            PlaybackHistory(
                videoID: unknownVideoID,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_200),
                lastPlaybackTime: 10
            )
        )

        let viewModel = PlaybackHistoryViewModel(videoCatalog: makeVideoCatalog())
        viewModel.loadIfNeeded(using: context)

        guard case .loaded(let items) = viewModel.state else {
            Issue.record("Expected loaded state.")
            return
        }

        #expect(items.count == 1)
        #expect(items.first?.videoID == unknownVideoID)
        #expect(items.first?.videoTitle == "Unknown Video")
        #expect(items.first?.creatorName == "Unknown Creator")
        #expect(items.first?.resolvedVideo == nil)
    }

    @Test
    func removeHistories_withSingleLoadedItem_setsEmptyState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        context.insert(
            PlaybackHistory(
                videoID: MockVideoRepository.tokyoNightWalkID,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_300),
                lastPlaybackTime: 8
            )
        )

        let viewModel = PlaybackHistoryViewModel(videoCatalog: makeVideoCatalog())
        viewModel.loadIfNeeded(using: context)

        guard case .loaded(let loadedItems) = viewModel.state else {
            Issue.record("Expected loaded state before delete.")
            return
        }

        viewModel.removeHistories(at: IndexSet(integer: 0), from: loadedItems, using: context)

        #expect(viewModel.state == .empty)
    }

    @Test
    func clearAllHistories_withLoadedItems_setsEmptyState() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        context.insert(
            PlaybackHistory(
                videoID: MockVideoRepository.tokyoNightWalkID,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_400),
                lastPlaybackTime: 11
            )
        )
        context.insert(
            PlaybackHistory(
                videoID: MockVideoRepository.morningCodingSessionID,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_500),
                lastPlaybackTime: 20
            )
        )

        let viewModel = PlaybackHistoryViewModel(videoCatalog: makeVideoCatalog())
        viewModel.loadIfNeeded(using: context)
        viewModel.clearAllHistories(using: context)

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

    private func makeVideoCatalog() -> [UUID: Video] {
        Dictionary(uniqueKeysWithValues: MockVideoRepository.defaultVideos.map { ($0.id, $0) })
    }
}
