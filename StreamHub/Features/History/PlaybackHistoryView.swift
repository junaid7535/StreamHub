import SwiftData
import SwiftUI

struct PlaybackHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlaybackHistoryViewModel
    @State private var selectedDetailVideo: Video?
    @State private var selectedPlayerVideo: Video?
    private let dependencies: AppDependencies

    init(
        viewModel: PlaybackHistoryViewModel = PlaybackHistoryViewModel(
            videoCatalog: Dictionary(uniqueKeysWithValues: MockVideoRepository.defaultVideos.map { ($0.id, $0) })
        ),
        dependencies: AppDependencies = AppDependencies()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.dependencies = dependencies
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ListStateView(content: .loading(title: "Loading playback history..."))

            case .empty:
                ListStateView(
                    content: .empty(
                        title: "No Playback History",
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                        description: "Played videos will appear here."
                    )
                )

            case .error(let message):
                ListStateView(
                    content: .error(
                        title: "Failed to Load History",
                        message: message,
                        retryAction: {
                            viewModel.reload(using: modelContext)
                        }
                    )
                )

            case .loaded(let items):
                List {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.tint)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.videoTitle)
                                    .font(.headline)
                                    .lineLimit(2)

                                Text(item.creatorName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Text("Played: \(ListDisplayFormatter.dateTime(item.watchedAt))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Text("Last Time: \(ListDisplayFormatter.duration(seconds: item.lastPlaybackTime))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let video = item.resolvedVideo {
                                    HStack(spacing: 14) {
                                        Button {
                                            selectedDetailVideo = video
                                        } label: {
                                            Label("Detail", systemImage: "info.circle")
                                                .font(.footnote.weight(.semibold))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Open Detail")
                                        .accessibilityHint("Opens the detail screen for this video.")

                                        Button {
                                            selectedPlayerVideo = video
                                        } label: {
                                            Label("Play Again", systemImage: "play.fill")
                                                .font(.footnote.weight(.semibold))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Play Again")
                                        .accessibilityHint("Opens the player and starts this video.")
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        viewModel.removeHistories(at: offsets, from: items, using: modelContext)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDetailVideo) { video in
            DetailView(
                viewModel: dependencies.makeDetailViewModel(for: video),
                dependencies: dependencies
            )
        }
        .navigationDestination(item: $selectedPlayerVideo) { video in
            PlayerView(viewModel: dependencies.makePlayerViewModel(for: video))
        }
        .toolbar {
            if case .loaded = viewModel.state {
                Button("Clear All", role: .destructive) {
                    viewModel.clearAllHistories(using: modelContext)
                }
                .accessibilityLabel("Clear All History")
                .accessibilityHint("Removes all playback history items.")
            }
        }
        .onAppear {
            viewModel.reload(using: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        PlaybackHistoryView()
    }
    .modelContainer(for: [BookmarkVideo.self, PlaybackHistory.self], inMemory: true)
}
