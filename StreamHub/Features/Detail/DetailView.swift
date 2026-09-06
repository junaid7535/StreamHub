import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DetailViewModel
    private let dependencies: AppDependencies

    init(
        viewModel: DetailViewModel,
        dependencies: AppDependencies = AppDependencies()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.dependencies = dependencies
    }

    var body: some View {
        List {
            Section {
                AsyncImage(url: viewModel.video.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "play.rectangle")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )

                    @unknown default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.2))
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Video") {
                LabeledContent("Title", value: viewModel.video.title)
                LabeledContent("Creator", value: viewModel.video.creatorName)
            }

            Section("Metadata") {
                LabeledContent("Category", value: viewModel.video.category)
                LabeledContent("Duration", value: durationLabel(for: viewModel.video.durationSeconds))
            }

            Section("Related Videos") {
                if viewModel.relatedVideos.isEmpty {
                    Text("No related videos available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.relatedVideos) { relatedVideo in
                        NavigationLink(value: AppRoute.detail(relatedVideo)) {
                            VideoRowView(video: relatedVideo)
                        }
                    }
                }
            }
            
            Section("Actions") {
                NavigationLink(value: AppRoute.player(viewModel.video)) {
                    Label("Play Video", systemImage: "play.fill")
                        .font(.headline)
                }
                .accessibilityLabel("Play Video")
                .accessibilityHint("Opens the player for this video.")
                
                Button {
                    viewModel.toggleBookmark(using: modelContext)
                } label: {
                    Label(
                        viewModel.isBookmarked ? "Remove Bookmark" : "Add Bookmark",
                        systemImage: viewModel.isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }
                .accessibilityLabel(viewModel.isBookmarked ? "Remove Bookmark" : "Add Bookmark")
                .accessibilityHint("Updates bookmark status for this video.")
            }
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: AppRoute.self) { route in
            destinationView(for: route)
        }
        .task {
            viewModel.refreshBookmarkState(using: modelContext)
        }
        .alert("Error", isPresented: errorPresentedBinding) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }
    
    private var errorPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if newValue == false {
                    viewModel.clearError()
                }
            }
        )
    }

    private func durationLabel(for totalSeconds: Int) -> String {
        let safe = max(totalSeconds, 0)
        let hours = safe / 3600
        let minutes = (safe % 3600) / 60
        let seconds = safe % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
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
            PlayerView(viewModel: dependencies.makePlayerViewModel(for: video))
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
    NavigationStack {
        DetailView(
            viewModel: DetailViewModel(
                video: MockVideoRepository.defaultVideos[0]
            )
        )
    }
}
