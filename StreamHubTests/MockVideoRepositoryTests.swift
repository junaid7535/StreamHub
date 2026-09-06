import Testing
@testable import StreamHub

struct MockVideoRepositoryTests {
    @Test
    func fetchVideos_throwsConfiguredError() async {
        let repository = await MockVideoRepository(mode: .failure(.failedToLoadVideos), delayNanoseconds: 0)

        await #expect(throws: APIError.failedToLoadVideos) {
            _ = try await repository.fetchVideos()
        }
    }
}
