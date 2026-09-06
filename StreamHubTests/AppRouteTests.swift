import Foundation

@testable import StreamHub

@MainActor
struct AppRouteTests {
    @Test
    func detailRoute_withSameVideo_isEqual() {
        let video = Video(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "Route Video",
            creatorName: "Tester",
            streamURL: URL(string: "https://example.com/route.m3u8")!
        )

        let lhs = AppRoute.detail(video)
        let rhs = AppRoute.detail(video)

        #expect(lhs == rhs)
    }

    @Test
    func detailAndPlayerRoute_withSameVideo_areDifferent() {
        let video = Video(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "Route Video",
            creatorName: "Tester",
            streamURL: URL(string: "https://example.com/route2.m3u8")!
        )

        let detail = AppRoute.detail(video)
        let player = AppRoute.player(video)

        #expect(detail != player)
    }
}
