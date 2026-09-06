import Foundation
import Observation
import SwiftData

struct HistoryItem: Identifiable, Equatable {
    let id: PersistentIdentifier
    let videoID: UUID
    let videoTitle: String
    let creatorName: String
    let watchedAt: Date
    let lastPlaybackTime: Double
    let resolvedVideo: Video?
}

enum PlaybackHistoryViewState: Equatable {
    case loading
    case loaded([HistoryItem])
    case empty
    case error(String)
}

@MainActor
@Observable
final class PlaybackHistoryViewModel {
    private(set) var state: PlaybackHistoryViewState = .loading

    @ObservationIgnored
    private let videoCatalog: [UUID: Video]
    @ObservationIgnored
    private let historyReader: any PlaybackHistoryStorageReading
    @ObservationIgnored
    private var hasLoaded = false

    init(
        videoCatalog: [UUID: Video],
        historyReader: any PlaybackHistoryStorageReading = SwiftDataPlaybackHistoryStorageReader()
    ) {
        self.videoCatalog = videoCatalog
        self.historyReader = historyReader
    }

    func loadIfNeeded(using context: ModelContext) {
        guard hasLoaded == false else { return }
        load(using: context)
        hasLoaded = true
    }

    func reload(using context: ModelContext) {
        hasLoaded = false
        loadIfNeeded(using: context)
    }

    func removeHistories(at offsets: IndexSet, from items: [HistoryItem], using context: ModelContext) {
        let targetItemIDs: [PersistentIdentifier] = offsets.compactMap { index in
            guard items.indices.contains(index) else { return nil }
            return items[index].id
        }

        do {
            let targetIDs = Set(targetItemIDs)
            let allHistories = try context.fetch(FetchDescriptor<PlaybackHistory>())

            for history in allHistories {
                if targetIDs.contains(history.persistentModelID) {
                    context.delete(history)
                }
            }

            try context.save()

            let remainingItems = items.enumerated()
                .filter { offsets.contains($0.offset) == false }
                .map(\.element)
            state = remainingItems.isEmpty ? .empty : .loaded(remainingItems)
        } catch {
            state = .error("Failed to remove playback history.")
        }
    }

    func clearAllHistories(using context: ModelContext) {
        let descriptor = FetchDescriptor<PlaybackHistory>()

        do {
            let histories = try context.fetch(descriptor)
            for history in histories {
                context.delete(history)
            }
            try context.save()
            state = .empty
        } catch {
            state = .error("Failed to clear playback history.")
        }
    }

    private func load(using context: ModelContext) {
        state = .loading

        do {
            let histories = try historyReader.fetchPlaybackHistories(using: context)
            let items: [HistoryItem] = histories.map {
                let resolvedVideo = videoCatalog[$0.videoID]
                return HistoryItem(
                    id: $0.persistentModelID,
                    videoID: $0.videoID,
                    videoTitle: resolvedVideo?.title ?? "Unknown Video",
                    creatorName: resolvedVideo?.creatorName ?? "Unknown Creator",
                    watchedAt: $0.watchedAt,
                    lastPlaybackTime: $0.lastPlaybackTime,
                    resolvedVideo: resolvedVideo
                )
            }

            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .error("Failed to load playback history.")
        }
    }
}
