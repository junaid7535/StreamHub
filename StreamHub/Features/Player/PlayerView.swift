import AVKit
import SwiftUI
import SwiftData

struct PlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            VideoPlayer(player: viewModel.player)
                .ignoresSafeArea(edges: .bottom)

            if viewModel.isBuffering {
                VStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Buffering...")
                        .font(.footnote)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Buffering")
                .accessibilityHint("The video is loading.")
            }

            VStack {
                if let resumeText = viewModel.resumeIndicatorText {
                    HStack(spacing: 10) {
                        Label(resumeText, systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        Button("Restart") {
                            viewModel.restartFromBeginning()
                        }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel("Restart from Beginning")
                        .accessibilityHint("Seeks to the beginning and keeps playback on.")
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    HStack {
                        Text(viewModel.currentTimeLabel)
                            .monospacedDigit()
                            .font(.footnote)
                        Spacer(minLength: 0)
                        Text(viewModel.durationLabel)
                            .monospacedDigit()
                            .font(.footnote)
                    }

                    Slider(
                        value: Binding(
                            get: { viewModel.scrubberPositionSeconds },
                            set: { newValue in
                                viewModel.updateScrubberPosition(to: newValue)
                            }
                        ),
                        in: 0...max(viewModel.durationSeconds, viewModel.scrubberPositionSeconds, 1),
                        onEditingChanged: { isEditing in
                            if isEditing {
                                viewModel.beginScrubbing()
                            } else {
                                viewModel.endScrubbing()
                            }
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Playback Position")
                .accessibilityHint("Shows current time and lets you scrub the video timeline.")

                HStack {
                    Spacer(minLength: 0)

                    Menu {
                        ForEach(PlaybackSpeedOption.allCases) { option in
                            Button {
                                viewModel.selectPlaybackSpeed(option)
                            } label: {
                                if viewModel.playbackSpeed == option {
                                    Label(option.title, systemImage: "checkmark")
                                } else {
                                    Text(option.title)
                                }
                            }
                        }
                    } label: {
                        Label("Speed \(viewModel.playbackSpeed.title)", systemImage: "speedometer")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityLabel("Playback Speed")
                    .accessibilityHint("Changes video playback speed.")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                HStack(spacing: 24) {
                    Button {
                        viewModel.seek(by: -10)
                    } label: {
                        Label("Back 10 Seconds", systemImage: "gobackward.10")
                    }
                    .accessibilityLabel("Back 10 Seconds")

                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Label(
                            viewModel.isPlaying ? "Pause" : "Play",
                            systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill"
                        )
                    }
                    .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

                    Button {
                        viewModel.seek(by: 10)
                    } label: {
                        Label("Forward 10 Seconds", systemImage: "goforward.10")
                    }
                    .accessibilityLabel("Forward 10 Seconds")
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 24)
            }
        }
            .navigationTitle("Player")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.onAppear(using: modelContext)
            }
            .onDisappear {
                viewModel.onDisappear(using: modelContext)
            }
            .alert("Error", isPresented: errorPresentedBinding) {
                if viewModel.canRetryPlayback {
                    Button("Retry") {
                        viewModel.retryPlayback()
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
    }
    
    private var errorPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if newValue == false {
                    viewModel.clearError()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        PlayerView(
            viewModel: PlayerViewModel(
                video: MockVideoRepository.defaultVideos[0],
                playerClient: DefaultPlayerClient()
            )
        )
    }
}
