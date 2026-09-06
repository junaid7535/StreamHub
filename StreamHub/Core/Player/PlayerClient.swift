import AVFoundation
import Foundation

protocol PlayerClient {
    func makePlayer(for video: Video) -> AVPlayer
}

struct DefaultPlayerClient: PlayerClient {
    func makePlayer(for video: Video) -> AVPlayer {
        AVPlayer(url: video.streamURL)
    }
}
