import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let item: MediaItem
    let startTime: Double?
    @StateObject private var viewModel = PlaybackViewModel()
    @Environment(\.dismiss) private var dismiss
    
    init(item: MediaItem, startTime: Double? = nil) {
        self.item = item
        self.startTime = startTime
    }
    
    var body: some View {
        Group {
            if let player = viewModel.player {
                AVPlayerControllerRepresentable(player: player, dismiss: dismiss)
                    .ignoresSafeArea()
            } else {
                Color.black // Loading placeholder
                    .ignoresSafeArea()
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
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
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
            // Handle full screen presentation if needed
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animate(alongsideTransition: nil) { _ in
                self.dismiss()
            }
        }
    }
} 