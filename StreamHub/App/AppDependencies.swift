struct AppDependencies {
    let videoRepository: any VideoRepository
    let playerClient: any PlayerClient

    init(
        videoRepository: any VideoRepository = MockVideoRepository(),
        playerClient: any PlayerClient = DefaultPlayerClient()
    ) {
        self.videoRepository = videoRepository
        self.playerClient = playerClient
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(repository: videoRepository)
    }

    func makeDetailViewModel(for video: Video) -> DetailViewModel {
        DetailViewModel(video: video)
    }

    func makePlayerViewModel(for video: Video) -> PlayerViewModel {
        PlayerViewModel(
            video: video,
            playerClient: playerClient
        )
    }

    func makeBookmarksViewModel() -> BookmarksViewModel {
        BookmarksViewModel()
    }

    func makePlaybackHistoryViewModel() -> PlaybackHistoryViewModel {
        let catalogProvider = videoRepository as? any VideoCatalogProviding
        let videoCatalog = catalogProvider?.videoCatalog ?? [:]

        return PlaybackHistoryViewModel(
            videoCatalog: videoCatalog
        )
    }
}
