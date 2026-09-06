import Foundation
import Observation

enum HomeViewState: Equatable {
    case loading
    case loaded([Video])
    case empty
    case error(String)
}

enum HomeSortOption: String, CaseIterable, Equatable, Identifiable {
    case `default`
    case titleAscending
    case titleDescending

    var id: Self { self }

    var title: String {
        switch self {
        case .default:
            return "Default"
        case .titleAscending:
            return "Title A-Z"
        case .titleDescending:
            return "Title Z-A"
        }
    }
}

@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: HomeViewState = .loading
    var query = ""
    var sortOption: HomeSortOption = .default
    var hasActiveSearchQuery: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @ObservationIgnored
    private let repository: any VideoRepository
    @ObservationIgnored
    private var hasLoaded = false

    init(repository: any VideoRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard hasLoaded == false else { return }
        await loadVideos()
        hasLoaded = true
    }

    func reload() async {
        hasLoaded = false
        await loadIfNeeded()
    }

    func displayedVideos(from videos: [Video]) -> [Video] {
        sortVideos(filteredVideos(from: videos))
    }

    func filteredVideos(from videos: [Video]) -> [Video] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return videos }

        return videos.filter { video in
            video.title.localizedCaseInsensitiveContains(trimmedQuery)
                || video.creatorName.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private func sortVideos(_ videos: [Video]) -> [Video] {
        switch sortOption {
        case .default:
            return videos
        case .titleAscending:
            return videos.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDescending:
            return videos.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }
    }

    private func loadVideos() async {
        state = .loading

        do {
            let videos = try await repository.fetchVideos()
            state = videos.isEmpty ? .empty : .loaded(videos)
        } catch {
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               description.isEmpty == false {
                state = .error(description)
            } else {
                state = .error("An unknown error occurred.")
            }
        }
    }
}
