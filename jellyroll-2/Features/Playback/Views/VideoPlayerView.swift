import SwiftUI
import AVKit

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
                AVPlayerControllerRepresentable(player: player, dismiss: dismiss)
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
                            dismiss()
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
    }
}

struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    let dismiss: DismissAction
    
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
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
        // Ensure controls remain visible
        uiViewController.showsPlaybackControls = true
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
            super.init()
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            // Ensure controls are visible when entering full screen
            playerViewController.showsPlaybackControls = true
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animate(alongsideTransition: nil) { _ in
                self.dismiss()
            }
        }
    }
} 