import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let item: MediaItem
    @StateObject private var viewModel = PlaybackViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VideoPlayer(player: viewModel.player ?? AVPlayer())
                    .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(item.name)
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