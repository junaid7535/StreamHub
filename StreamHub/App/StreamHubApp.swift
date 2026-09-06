import SwiftData
import SwiftUI

@main
struct StreamHubApp: App {
    private let dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            HomeView(dependencies: dependencies)
        }
        .modelContainer(for: [BookmarkVideo.self, PlaybackHistory.self])
    }
}
