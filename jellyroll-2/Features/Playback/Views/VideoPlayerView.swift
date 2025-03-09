import SwiftUI
import AVKit
import os

struct VideoPlayerView: View {
    let item: MediaItem
    let startTime: Double?
    @StateObject private var viewModel = PlaybackViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(item: MediaItem, startTime: Double? = nil) {
        self.item = item
        self.startTime = startTime
    }
    
    var body: some View {
        ZStack {
            if let player = viewModel.player {
                AVPlayerControllerRepresentable(player: player, dismiss: dismiss, viewModel: viewModel)
                    .ignoresSafeArea()
            } else {
                Color.black // Loading placeholder
                    .ignoresSafeArea()
            }
            
            // Error overlay
            if let error = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Media info
                        VStack(spacing: 8) {
                            JellyfinImage(
                                itemId: item.id,
                                imageType: .backdrop,
                                aspectRatio: 16/9,
                                cornerRadius: 12,
                                fallbackIcon: "film",
                                blurHash: item.imageBlurHashes["Backdrop"]?.values.first
                            )
                            .frame(height: 120)
                            
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            if let year = item.yearText {
                                Text(year)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Error message
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                            
                            Text("Playback Error")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Close button
                        Button(action: {
                            Task { @MainActor in
                                await viewModel.cleanup()
                                dismiss()
                            }
                        }) {
                            Text("Close")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.play(item: item)
            if let startTime = startTime {
                await viewModel.seek(to: startTime)
            }
        }
        .onDisappear {
            Task { @MainActor in
                await viewModel.cleanup()
            }
        }
        .trackScreenView("Video Player - \(item.name)")
    }
}

struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    let dismiss: DismissAction
    let viewModel: PlaybackViewModel
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "AVPlayerController")
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = true
        
        // Configure for HDR playback and ensure controls are always visible
        if #available(iOS 15.0, *) {
            controller.videoGravity = .resizeAspect
            controller.entersFullScreenWhenPlaybackBegins = true
            controller.exitsFullScreenWhenPlaybackEnds = true
        }
        
        // Keep controls visible
        controller.showsPlaybackControls = true
        
        // Add observer for rate changes to detect play/pause
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemTimeJumped,
            object: player.currentItem,
            queue: .main
        ) { _ in
            logger.debug("[Player] Time jumped notification received")
        }
        
        player.addObserver(context.coordinator, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: nil)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
        uiViewController.showsPlaybackControls = true
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, logger: logger, viewModel: viewModel)
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        let dismiss: DismissAction
        let logger: Logger
        let viewModel: PlaybackViewModel
        
        init(dismiss: DismissAction, logger: Logger, viewModel: PlaybackViewModel) {
            self.dismiss = dismiss
            self.logger = logger
            self.viewModel = viewModel
            super.init()
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == #keyPath(AVPlayer.timeControlStatus),
               let player = object as? AVPlayer {
                let status = player.timeControlStatus
                switch status {
                case .paused:
                    logger.debug("[Player] Player status changed to paused")
                    Task { @MainActor in
                        if viewModel.isPlaying { // Only toggle if we're not already in the desired state
                            await viewModel.togglePlayPause()
                        }
                    }
                case .playing:
                    logger.debug("[Player] Player status changed to playing")
                    Task { @MainActor in
                        if !viewModel.isPlaying { // Only toggle if we're not already in the desired state
                            await viewModel.togglePlayPause()
                        }
                    }
                case .waitingToPlayAtSpecifiedRate:
                    logger.debug("[Player] Player status changed to waiting")
                @unknown default:
                    logger.debug("[Player] Player status changed to unknown state")
                }
            }
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            logger.debug("[Player] Will begin full screen presentation")
            playerViewController.showsPlaybackControls = true
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            logger.debug("[Player] Will end full screen presentation")
            coordinator.animate(alongsideTransition: nil) { _ in
                self.dismiss()
            }
        }
    }
} 