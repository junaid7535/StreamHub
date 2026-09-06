import AVFoundation
import Foundation
import Observation
import SwiftData

enum PlaybackSpeedOption: Double, CaseIterable, Identifiable {
    case x1_0 = 1.0
    case x1_25 = 1.25
    case x1_5 = 1.5
    case x2_0 = 2.0

    var id: Self { self }

    var title: String {
        switch self {
        case .x1_0:
            return "1.0x"
        case .x1_25:
            return "1.25x"
        case .x1_5:
            return "1.5x"
        case .x2_0:
            return "2.0x"
        }
    }

    var rate: Float {
        Float(rawValue)
    }
}

protocol PlaybackSpeedStoring {
    func loadPlaybackSpeed() -> PlaybackSpeedOption?
    func savePlaybackSpeed(_ speed: PlaybackSpeedOption)
}

struct UserDefaultsPlaybackSpeedStore: PlaybackSpeedStoring {
    private let userDefaults: UserDefaults
    private let key: String

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "streamhub.player.playbackSpeed"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func loadPlaybackSpeed() -> PlaybackSpeedOption? {
        let value = userDefaults.double(forKey: key)
        guard value > 0 else { return nil }
        return PlaybackSpeedOption(rawValue: value)
    }

    func savePlaybackSpeed(_ speed: PlaybackSpeedOption) {
        userDefaults.set(speed.rawValue, forKey: key)
    }
}

@MainActor
@Observable
final class PlayerViewModel {
    let video: Video
    let player: AVPlayer

    private(set) var isPlaying = false
    private(set) var resumedFromSeconds: Double?
    private(set) var errorMessage: String?
    private(set) var canRetryPlayback = false
    private(set) var playbackSpeed: PlaybackSpeedOption = .x1_0
    private(set) var currentTimeSeconds: Double = 0
    private(set) var durationSeconds: Double = 0
    private(set) var scrubberPositionSeconds: Double = 0
    private(set) var isScrubbing = false
    private(set) var isBuffering = false

    @ObservationIgnored
    private var hasStarted = false
    @ObservationIgnored
    private var restoredPlaybackTime: Double?
    @ObservationIgnored
    private let historyStore: any PlayerPlaybackHistoryStoring
    @ObservationIgnored
    private let playbackSpeedStore: any PlaybackSpeedStoring
    @ObservationIgnored
    private var timeObserverToken: Any?
    @ObservationIgnored
    private var timeControlObserver: NSKeyValueObservation?
    @ObservationIgnored
    private var currentItemObserver: NSKeyValueObservation?
    @ObservationIgnored
    private var itemStatusObserver: NSKeyValueObservation?

    private static let playbackFailedMessage = "Playback failed. Please try again."
    
    init(
        video: Video,
        playerClient: any PlayerClient,
        historyStore: any PlayerPlaybackHistoryStoring = SwiftDataPlayerPlaybackHistoryStore(),
        playbackSpeedStore: any PlaybackSpeedStoring = UserDefaultsPlaybackSpeedStore()
    ) {
        self.video = video
        self.player = playerClient.makePlayer(for: video)
        self.historyStore = historyStore
        self.playbackSpeedStore = playbackSpeedStore
        if let savedSpeed = playbackSpeedStore.loadPlaybackSpeed() {
            self.playbackSpeed = savedSpeed
        }
    }
    
    func onAppear(using context: ModelContext) {
        guard hasStarted == false else { return }
        hasStarted = true
        configurePlaybackFailureObservation()
        configureTimeControlObservation()
        configureTimeObservation()
        restorePlaybackPosition(using: context)
        startPlayback()
    }

    func onDisappear(using context: ModelContext) {
        player.pause()
        isPlaying = false
        isBuffering = false
        tearDownObservers()
        hasStarted = false
        savePlaybackHistory(using: context)
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
            isBuffering = false
        } else {
            startPlayback()
        }
    }

    func seek(by seconds: Double) {
        let currentSeconds = player.currentTime().seconds
        let durationSeconds = player.currentItem?.duration.seconds ?? .infinity
        let targetUnclamped = (currentSeconds.isFinite ? currentSeconds : 0) + seconds

        let lowerBound = 0.0
        let upperBound = durationSeconds.isFinite ? max(durationSeconds, 0) : .infinity
        let targetSeconds = min(max(targetUnclamped, lowerBound), upperBound)

        seekTo(seconds: targetSeconds)
    }

    func restartFromBeginning() {
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        player.seek(to: time)
        resumedFromSeconds = nil
        restoredPlaybackTime = 0

        if isPlaying == false {
            startPlayback()
        } else {
            applyPlaybackSpeed()
        }
    }

    func selectPlaybackSpeed(_ option: PlaybackSpeedOption) {
        playbackSpeed = option
        playbackSpeedStore.savePlaybackSpeed(option)
        applyPlaybackSpeed()
    }

    func beginScrubbing() {
        isScrubbing = true
    }

    func updateScrubberPosition(to seconds: Double) {
        scrubberPositionSeconds = max(seconds, 0)
    }

    func endScrubbing() {
        isScrubbing = false
        seekTo(seconds: scrubberPositionSeconds)
    }

    var resumeIndicatorText: String? {
        guard let seconds = resumedFromSeconds, seconds.isFinite, seconds > 0 else { return nil }
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let remainingSeconds = total % 60
        return String(format: "Resumed from %d:%02d", minutes, remainingSeconds)
    }

    func clearError() {
        errorMessage = nil
        canRetryPlayback = false
    }

    func retryPlayback() {
        clearError()
        isBuffering = true
        currentTimeSeconds = 0
        durationSeconds = 0
        scrubberPositionSeconds = 0

        let item = AVPlayerItem(url: video.streamURL)
        player.replaceCurrentItem(with: item)
        startPlayback()
    }

    var currentTimeLabel: String {
        formatTime(isScrubbing ? scrubberPositionSeconds : currentTimeSeconds)
    }

    var durationLabel: String {
        formatTime(durationSeconds)
    }

    private func startPlayback() {
        player.play()
        isPlaying = true
        applyPlaybackSpeed()
        updateBufferingState()
    }

    private func applyPlaybackSpeed() {
        guard isPlaying else { return }
        player.rate = playbackSpeed.rate
    }

    private func seekTo(seconds: Double) {
        let lowerBound = 0.0
        let upperBound = durationSeconds > 0 ? durationSeconds : .infinity
        let clamped = min(max(seconds, lowerBound), upperBound)

        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: time)
        currentTimeSeconds = clamped
        scrubberPositionSeconds = clamped
    }

    private func configureTimeObservation() {
        guard timeObserverToken == nil else { return }
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.updatePlaybackProgress(time)
            }
        }
    }

    private func configureTimeControlObservation() {
        guard timeControlObserver == nil else { return }
        timeControlObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.updateBufferingState()
            }
        }
    }

    private func configurePlaybackFailureObservation() {
        guard currentItemObserver == nil else { return }

        currentItemObserver = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor in
                self?.observeStatus(of: player.currentItem)
            }
        }
    }

    private func observeStatus(of item: AVPlayerItem?) {
        itemStatusObserver?.invalidate()
        guard let item else { return }

        itemStatusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor in
                if item.status == .failed {
                    self?.handlePlaybackFailure()
                }
            }
        }
    }

    func handlePlaybackFailure() {
        isBuffering = false
        errorMessage = Self.playbackFailedMessage
        canRetryPlayback = true
    }

    private func updatePlaybackProgress(_ time: CMTime) {
        let current = time.seconds.isFinite ? max(time.seconds, 0) : 0
        let duration = player.currentItem?.duration.seconds ?? 0
        let safeDuration = duration.isFinite ? max(duration, 0) : 0

        currentTimeSeconds = current
        durationSeconds = safeDuration

        if isScrubbing == false {
            scrubberPositionSeconds = current
        }

        updateBufferingState()
    }

    private func updateBufferingState() {
        isBuffering = isPlaying && player.timeControlStatus == .waitingToPlayAtSpecifiedRate
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.towardZero))
        let minutes = total / 60
        let remainingSeconds = total % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func savePlaybackHistory(using context: ModelContext) {
        do {
            let currentTime = player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0
            let playbackTime: Double
            if currentTime > 0 {
                playbackTime = currentTime
            } else if let restored = restoredPlaybackTime, restored > 0 {
                // AVPlayer seek can be asynchronous; keep restored position if playback has not advanced yet.
                playbackTime = restored
            } else {
                playbackTime = 0
            }

            try historyStore.upsertHistory(
                for: video.id,
                watchedAt: .now,
                lastPlaybackTime: playbackTime,
                using: context
            )
            restoredPlaybackTime = playbackTime
        } catch {
            errorMessage = "Failed to save playback history."
            canRetryPlayback = false
        }
    }

    private func restorePlaybackPosition(using context: ModelContext) {
        do {
            guard let existing = try historyStore.fetchHistory(for: video.id, using: context) else { return }
            let seconds = existing.lastPlaybackTime
            guard seconds.isFinite, seconds > 0 else { return }
            restoredPlaybackTime = seconds
            resumedFromSeconds = seconds

            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            player.seek(to: time)
            currentTimeSeconds = seconds
            scrubberPositionSeconds = seconds
        } catch {
            errorMessage = "Failed to restore playback position."
            canRetryPlayback = false
        }
    }

    private func tearDownObservers() {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        self.timeObserverToken = nil
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        currentItemObserver?.invalidate()
        currentItemObserver = nil
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
    }
}

protocol PlayerPlaybackHistoryStoring: Sendable {
    func fetchHistory(for videoID: UUID, using context: ModelContext) throws -> PlaybackHistory?
    func upsertHistory(
        for videoID: UUID,
        watchedAt: Date,
        lastPlaybackTime: Double,
        using context: ModelContext
    ) throws
}

struct SwiftDataPlayerPlaybackHistoryStore: PlayerPlaybackHistoryStoring {
    func fetchHistory(for videoID: UUID, using context: ModelContext) throws -> PlaybackHistory? {
        let targetVideoID = videoID
        let descriptor = FetchDescriptor<PlaybackHistory>(
            predicate: #Predicate { history in
                history.videoID == targetVideoID
            }
        )
        return try context.fetch(descriptor).first
    }

    func upsertHistory(
        for videoID: UUID,
        watchedAt: Date,
        lastPlaybackTime: Double,
        using context: ModelContext
    ) throws {
        if let existing = try fetchHistory(for: videoID, using: context) {
            existing.watchedAt = watchedAt
            existing.lastPlaybackTime = lastPlaybackTime
        } else {
            let history = PlaybackHistory(
                videoID: videoID,
                watchedAt: watchedAt,
                lastPlaybackTime: lastPlaybackTime
            )
            context.insert(history)
        }

        try context.save()
    }
}
