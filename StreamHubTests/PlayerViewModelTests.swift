import AVFoundation
import Foundation
import SwiftData
import Testing
@testable import StreamHub

@MainActor
struct PlayerViewModelTests {
    @Test
    func onDisappear_withExistingHistory_updatesInPlace() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]

        context.insert(
            PlaybackHistory(
                videoID: video.id,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_000),
                lastPlaybackTime: 5
            )
        )
        try context.save()

        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )
        viewModel.onAppear(using: context)
        viewModel.onDisappear(using: context)

        let videoID = video.id
        let descriptor = FetchDescriptor<PlaybackHistory>(
            predicate: #Predicate { history in
                history.videoID == videoID
            }
        )
        let rows = try context.fetch(descriptor)

        #expect(rows.count == 1)
    }

    @Test
    func onAppear_restoresSavedPosition_thenOnDisappear_keepsPosition() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let expectedTime = 37.0

        context.insert(
            PlaybackHistory(
                videoID: video.id,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_100),
                lastPlaybackTime: expectedTime
            )
        )
        try context.save()

        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )
        viewModel.onAppear(using: context)
        viewModel.onDisappear(using: context)

        let videoID = video.id
        let descriptor = FetchDescriptor<PlaybackHistory>(
            predicate: #Predicate { history in
                history.videoID == videoID
            }
        )
        let rows = try context.fetch(descriptor)
        let savedTime = rows.first?.lastPlaybackTime ?? 0

        #expect(rows.count == 1)
        #expect(abs(savedTime - expectedTime) < 0.001)
    }

    @Test
    func onAppear_withSavedPosition_setsResumeIndicatorText() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let expectedTime = 37.0

        context.insert(
            PlaybackHistory(
                videoID: video.id,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_200),
                lastPlaybackTime: expectedTime
            )
        )
        try context.save()

        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )
        viewModel.onAppear(using: context)

        #expect(viewModel.resumeIndicatorText == "Resumed from 0:37")
    }

    @Test
    func restartFromBeginning_clearsResumeIndicator() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]

        context.insert(
            PlaybackHistory(
                videoID: video.id,
                watchedAt: Date(timeIntervalSince1970: 1_700_000_300),
                lastPlaybackTime: 15
            )
        )
        try context.save()

        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )
        viewModel.onAppear(using: context)
        viewModel.restartFromBeginning()

        #expect(viewModel.resumeIndicatorText == nil)
        #expect(viewModel.isPlaying == true)
    }

    @Test
    func onAppear_withInvalidHistoryStore_setsRestoreErrorMessage() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer()),
            historyStore: RestoreFailingPlaybackHistoryStore()
        )

        viewModel.onAppear(using: context)

        #expect(viewModel.errorMessage == "Failed to restore playback position.")
    }

    @Test
    func onDisappear_withInvalidHistoryStore_setsSaveErrorMessage() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer()),
            historyStore: SaveFailingPlaybackHistoryStore()
        )

        viewModel.onAppear(using: context)
        viewModel.onDisappear(using: context)

        #expect(viewModel.errorMessage == "Failed to save playback history.")
    }

    @Test
    func selectPlaybackSpeed_whenPaused_updatesSelectionOnly() {
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )

        viewModel.selectPlaybackSpeed(.x1_5)

        #expect(viewModel.playbackSpeed == .x1_5)
        #expect(viewModel.isPlaying == false)
    }

    @Test
    func selectPlaybackSpeed_whenPlaying_appliesRateToPlayer() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let player = AVPlayer()
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: player)
        )

        viewModel.onAppear(using: context)
        viewModel.selectPlaybackSpeed(.x2_0)

        #expect(viewModel.isPlaying == true)
        #expect(viewModel.playbackSpeed == .x2_0)
        #expect(abs(Double(player.rate) - 2.0) < 0.001)
    }

    @Test
    func currentTimeLabel_whileScrubbing_usesScrubberPosition() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )

        viewModel.onAppear(using: context)
        viewModel.beginScrubbing()
        viewModel.updateScrubberPosition(to: 125)

        #expect(viewModel.currentTimeLabel == "2:05")
    }

    @Test
    func endScrubbing_updatesCurrentTimeToScrubberPosition() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )

        viewModel.onAppear(using: context)
        viewModel.beginScrubbing()
        viewModel.updateScrubberPosition(to: 42)
        viewModel.endScrubbing()

        #expect(viewModel.isScrubbing == false)
        #expect(abs(viewModel.currentTimeSeconds - 42) < 0.001)
        #expect(abs(viewModel.scrubberPositionSeconds - 42) < 0.001)
    }

    @Test
    func handlePlaybackFailure_enablesRetryState() {
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )

        viewModel.handlePlaybackFailure()

        #expect(viewModel.errorMessage == "Playback failed. Please try again.")
        #expect(viewModel.canRetryPlayback == true)
        #expect(viewModel.isBuffering == false)
    }

    @Test
    func retryPlayback_afterPlaybackFailure_clearsError() {
        let video = MockVideoRepository.defaultVideos[0]
        let viewModel = PlayerViewModel(
            video: video,
            playerClient: StubPlayerClient(player: AVPlayer())
        )
        viewModel.handlePlaybackFailure()

        viewModel.retryPlayback()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.canRetryPlayback == false)
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

private struct StubPlayerClient: PlayerClient {
    let player: AVPlayer

    func makePlayer(for video: Video) -> AVPlayer {
        player
    }
}

private struct RestoreFailingPlaybackHistoryStore: PlayerPlaybackHistoryStoring {
    func fetchHistory(for videoID: UUID, using context: ModelContext) throws -> PlaybackHistory? {
        throw APIError.failedToLoadVideos
    }

    func upsertHistory(
        for videoID: UUID,
        watchedAt: Date,
        lastPlaybackTime: Double,
        using context: ModelContext
    ) throws {}
}

private struct SaveFailingPlaybackHistoryStore: PlayerPlaybackHistoryStoring {
    func fetchHistory(for videoID: UUID, using context: ModelContext) throws -> PlaybackHistory? {
        nil
    }

    func upsertHistory(
        for videoID: UUID,
        watchedAt: Date,
        lastPlaybackTime: Double,
        using context: ModelContext
    ) throws {
        throw APIError.failedToLoadVideos
    }
}
