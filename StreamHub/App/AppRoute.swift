import Foundation

enum AppRoute: Hashable {
    case detail(Video)
    case player(Video)
    case bookmarks
    case history
}
