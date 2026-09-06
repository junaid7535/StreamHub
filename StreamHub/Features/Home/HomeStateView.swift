import SwiftUI

struct HomeStateView: View {
    let state: HomeViewState
    let retryAction: @Sendable () async -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView("Loading videos...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView(
                "No Videos Available",
                systemImage: "film",
                description: Text("Available videos will appear here.")
            )

        case .error(let message):
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "Failed to Load Videos",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )

                Button("Retry") {
                    Task {
                        await retryAction()
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Retry")
                .accessibilityHint("Attempts to load videos again.")
            }
            .padding()

        case .loaded:
            EmptyView()
        }
    }
}

#Preview("loading") {
    HomeStateView(state: .loading, retryAction: {})
}

#Preview("empty") {
    HomeStateView(state: .empty, retryAction: {})
}

#Preview("error") {
    HomeStateView(state: .error("Please check your connection."), retryAction: {})
}
