import Foundation

enum APIError: Error, Equatable, LocalizedError, Sendable {
    case failedToLoadVideos

    var errorDescription: String? {
        switch self {
        case .failedToLoadVideos:
            return "Failed to load videos."
        }
    }
}
