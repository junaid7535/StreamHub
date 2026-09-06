import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    private let dependencies: AppDependencies

    init(
        viewModel: HomeViewModel? = nil,
        dependencies: AppDependencies = AppDependencies()
    ) {
        _viewModel = State(initialValue: viewModel ?? dependencies.makeHomeViewModel())
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("StreamHub")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Menu("Sort") {
                                ForEach(HomeSortOption.allCases) { option in
                                    Button {
                                        viewModel.sortOption = option
                                    } label: {
                                        if viewModel.sortOption == option {
                                            Label(option.title, systemImage: "checkmark")
                                        } else {
                                            Text(option.title)
                                        }
                                    }
                                }
                            }

                            NavigationLink(value: AppRoute.bookmarks) {
                                Label("Bookmarks", systemImage: "bookmark")
                            }

                            NavigationLink(value: AppRoute.history) {
                                Label("History", systemImage: "clock")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Open Library Menu")
                        .accessibilityHint("Shows Bookmarks and History.")
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
                .searchable(text: $viewModel.query, prompt: "Search videos or creators")
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loaded(let videos):
            let displayedVideos = viewModel.displayedVideos(from: videos)

            if displayedVideos.isEmpty && viewModel.hasActiveSearchQuery {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No videos matched \"\(viewModel.query)\".")
                )
            } else {
                List(displayedVideos) { video in
                    NavigationLink(value: AppRoute.detail(video)) {
                        VideoRowView(video: video)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.reload()
                }
            }

        case .loading, .empty, .error:
            HomeStateView(state: viewModel.state) {
                await viewModel.reload()
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .detail(let video):
            DetailView(
                viewModel: dependencies.makeDetailViewModel(for: video),
                dependencies: dependencies
            )
        case .player(let video):
            PlayerView(
                viewModel: dependencies.makePlayerViewModel(for: video)
            )
        case .bookmarks:
            BookmarksView(viewModel: dependencies.makeBookmarksViewModel())
        case .history:
            PlaybackHistoryView(
                viewModel: dependencies.makePlaybackHistoryViewModel(),
                dependencies: dependencies
            )
        }
    }
}

#Preview {
    let dependencies = AppDependencies(
        videoRepository: MockVideoRepository(mode: .success(MockVideoRepository.defaultVideos), delayNanoseconds: 0),
        playerClient: DefaultPlayerClient()
    )

    HomeView(dependencies: dependencies)
}
