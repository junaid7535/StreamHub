import SwiftUI

struct ListStateView: View {
    enum Content {
        case loading(title: String)
        case empty(title: String, systemImage: String, description: String)
        case error(
            title: String,
            systemImage: String = "exclamationmark.triangle",
            message: String,
            retryTitle: String = "Retry",
            retryAction: () -> Void
        )
    }

    let content: Content

    var body: some View {
        switch content {
        case .loading(let title):
            ProgressView(title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty(let title, let systemImage, let description):
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(description)
            )

        case .error(let title, let systemImage, let message, let retryTitle, let retryAction):
            VStack(spacing: 12) {
                ContentUnavailableView(
                    title,
                    systemImage: systemImage,
                    description: Text(message)
                )

                Button(retryTitle) {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(retryTitle)
                .accessibilityHint("Attempts to load the list again.")
            }
            .padding()
        }
    }
}

#Preview("Loading") {
    ListStateView(content: .loading(title: "Loading..."))
}

#Preview("Empty") {
    ListStateView(
        content: .empty(
            title: "No Items",
            systemImage: "tray",
            description: "Items will appear here."
        )
    )
}

#Preview("Error") {
    ListStateView(
        content: .error(
            title: "Failed to Load",
            message: "Please try again.",
            retryAction: {}
        )
    )
}
