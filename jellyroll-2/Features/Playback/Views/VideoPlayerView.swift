import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let item: MediaItem
    @StateObject private var viewModel = PlaybackViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AVPlayerControllerRepresentable(player: viewModel.player ?? AVPlayer(), dismiss: dismiss)
            .ignoresSafeArea()
            .navigationBarHidden(true)
            .task {
                await viewModel.play(item: item)
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
        uiViewController.player = player
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