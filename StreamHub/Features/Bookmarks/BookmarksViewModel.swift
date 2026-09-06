import Foundation
import Observation
import SwiftData

struct BookmarkItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let creatorName: String
    let createdAt: Date
}

enum BookmarksViewState: Equatable {
    case loading
    case loaded([BookmarkItem])
    case empty
    case error(String)
}

enum BookmarkSortOption: CaseIterable, Equatable, Identifiable {
    case recent
    case titleAscending

    var id: Self { self }

    var title: String {
        switch self {
        case .recent:
            return "Recent"
        case .titleAscending:
            return "Title A-Z"
        }
    }
}

@MainActor
@Observable
final class BookmarksViewModel {
    private(set) var state: BookmarksViewState = .loading
    var sortOption: BookmarkSortOption = .recent {
        didSet {
            applySortToLoadedState()
        }
    }

    @ObservationIgnored
    private let bookmarkReader: any BookmarkStorageReading
    @ObservationIgnored
    private var hasLoaded = false

    init(bookmarkReader: any BookmarkStorageReading = SwiftDataBookmarkStorageReader()) {
        self.bookmarkReader = bookmarkReader
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

    func removeBookmarks(at offsets: IndexSet, from items: [BookmarkItem], using context: ModelContext) {
        let targetIDs: [UUID] = offsets.compactMap { index in
            guard items.indices.contains(index) else { return nil }
            return items[index].id
        }

        do {
            for videoID in targetIDs {
                let targetID = videoID
                let descriptor = FetchDescriptor<BookmarkVideo>(
                    predicate: #Predicate { bookmark in
                        bookmark.videoID == targetID
                    }
                )
                if let existing = try context.fetch(descriptor).first {
                    context.delete(existing)
                }
            }

            try context.save()

            let remainingItems = items.enumerated()
                .filter { offsets.contains($0.offset) == false }
                .map(\.element)
            let sortedItems = sortBookmarks(remainingItems)
            state = sortedItems.isEmpty ? .empty : .loaded(sortedItems)
        } catch {
            state = .error("Failed to remove bookmark.")
        }
    }

    private func load(using context: ModelContext) {
        state = .loading

        do {
            let bookmarks = try bookmarkReader.fetchBookmarks(using: context)
            let items = bookmarks.map {
                BookmarkItem(
                    id: $0.videoID,
                    title: $0.title,
                    creatorName: $0.creatorName,
                    createdAt: $0.createdAt
                )
            }

            let sortedItems = sortBookmarks(items)
            state = sortedItems.isEmpty ? .empty : .loaded(sortedItems)
        } catch {
            state = .error("Failed to load bookmarks.")
        }
    }

    private func applySortToLoadedState() {
        guard case .loaded(let items) = state else { return }
        state = .loaded(sortBookmarks(items))
    }

    private func sortBookmarks(_ items: [BookmarkItem]) -> [BookmarkItem] {
        switch sortOption {
        case .recent:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .titleAscending:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
