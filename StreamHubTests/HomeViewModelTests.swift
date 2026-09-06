import Testing
@testable import StreamHub

@MainActor
struct HomeViewModelTests {
    @Test
    func loadIfNeeded_withEmptyRepository_setsEmptyState() async {
        let repository = MockVideoRepository(mode: .empty, delayNanoseconds: 0)
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .empty)
    }

    @Test
    func reload_afterInitialLoad_fetchesAgainAndUpdatesState() async {
        let first = [MockVideoRepository.defaultVideos[0]]
        let second = [MockVideoRepository.defaultVideos[1]]
        let repository = SequencedVideoRepository(responses: [first, second])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        #expect(viewModel.state == .loaded(first))

        await viewModel.reload()
        #expect(viewModel.state == .loaded(second))
    }

    @Test
    func displayedVideos_withQuery_filtersByTitleAndCreator() {
        let repository = MockVideoRepository(mode: .success(MockVideoRepository.defaultVideos), delayNanoseconds: 0)
        let viewModel = HomeViewModel(repository: repository)
        let videos = MockVideoRepository.defaultVideos

        viewModel.query = "swift"
        let resultsByCreator = viewModel.displayedVideos(from: videos)
        #expect(resultsByCreator.map(\.id) == [MockVideoRepository.morningCodingSessionID])

        viewModel.query = "tokyo"
        let resultsByTitle = viewModel.displayedVideos(from: videos)
        #expect(resultsByTitle.map(\.id) == [MockVideoRepository.tokyoNightWalkID])
    }

    @Test
    func displayedVideos_withTitleAscendingSort_returnsAlphabeticalOrder() {
        let repository = MockVideoRepository(mode: .success(MockVideoRepository.defaultVideos), delayNanoseconds: 0)
        let viewModel = HomeViewModel(repository: repository)
        let videos = MockVideoRepository.defaultVideos

        viewModel.sortOption = .titleAscending

        let results = viewModel.displayedVideos(from: videos)
        #expect(results.map(\.id) == [
            MockVideoRepository.morningCodingSessionID,
            MockVideoRepository.tokyoNightWalkID
        ])
    }

    @Test
    func displayedVideos_withTitleDescendingSort_returnsReverseAlphabeticalOrder() {
        let repository = MockVideoRepository(mode: .success(MockVideoRepository.defaultVideos), delayNanoseconds: 0)
        let viewModel = HomeViewModel(repository: repository)
        let videos = MockVideoRepository.defaultVideos

        viewModel.sortOption = .titleDescending

        let results = viewModel.displayedVideos(from: videos)
        #expect(results.map(\.id) == [
            MockVideoRepository.tokyoNightWalkID,
            MockVideoRepository.morningCodingSessionID
        ])
    }

    @Test
    func displayedVideos_withActiveQueryAndNoMatch_returnsEmpty() {
        let repository = MockVideoRepository(mode: .success(MockVideoRepository.defaultVideos), delayNanoseconds: 0)
        let viewModel = HomeViewModel(repository: repository)
        let videos = MockVideoRepository.defaultVideos

        viewModel.query = "no-match-keyword"

        let results = viewModel.displayedVideos(from: videos)
        #expect(viewModel.hasActiveSearchQuery == true)
        #expect(results.isEmpty)
    }
}

private actor SequencedVideoRepository: VideoRepository {
    private var responses: [[Video]]

    init(responses: [[Video]]) {
        self.responses = responses
    }

    func fetchVideos() async throws -> [Video] {
        guard responses.isEmpty == false else { return [] }
        return responses.removeFirst()
    }
}
