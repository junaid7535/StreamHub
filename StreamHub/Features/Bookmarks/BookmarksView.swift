import SwiftData
import SwiftUI

struct BookmarksView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BookmarksViewModel

    init(viewModel: BookmarksViewModel = BookmarksViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ListStateView(content: .loading(title: "Loading bookmarks..."))

            case .empty:
                ListStateView(
                    content: .empty(
                        title: "No Bookmarks",
                        systemImage: "bookmark",
                        description: "Bookmarked videos appear here."
                    )
                )

            case .error(let message):
                ListStateView(
                    content: .error(
                        title: "Failed to Load Bookmarks",
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
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(.tint)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Text(item.creatorName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Text("Saved: \(ListDisplayFormatter.dateTime(item.createdAt))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            "\(item.title), by \(item.creatorName). Saved \(ListDisplayFormatter.dateTime(item.createdAt))."
                        )
                    }
                    .onDelete { offsets in
                        viewModel.removeBookmarks(at: offsets, from: items, using: modelContext)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(BookmarkSortOption.allCases) { option in
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
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
                .accessibilityLabel("Sort Bookmarks")
                .accessibilityHint("Changes bookmark list order.")
            }
        }
        .onAppear {
            viewModel.reload(using: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        BookmarksView()
    }
    .modelContainer(for: [BookmarkVideo.self, PlaybackHistory.self], inMemory: true)
}
