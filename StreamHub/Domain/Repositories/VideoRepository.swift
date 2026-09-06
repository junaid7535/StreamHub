import Foundation

protocol VideoRepository: Sendable {
    func fetchVideos() async throws -> [Video]
}

protocol VideoCatalogProviding {
    var videoCatalog: [UUID: Video] { get }
}
