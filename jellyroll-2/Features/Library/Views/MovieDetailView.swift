import SwiftUI

struct MovieDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @State private var showingPlayer = false
    
    private var hasProgress: Bool {
        item.userData.playbackPositionTicks ?? 0 > 0
    }
    
    private var progressPercentage: Double {
        guard let runtime = item.runTimeTicks, runtime > 0 else { return 0 }
        let position = item.userData.playbackPositionTicks ?? 0
        return Double(position) / Double(runtime)
    }
    
    private var progressText: String {
        let position = item.userData.playbackPositionTicks ?? 0
        let totalSeconds = Int(Double(position) / 10_000_000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    var body: some View {
        Group {
            if layoutManager.isLandscape {
                MovieDetailLayouts.LandscapeLayout(
                    item: item,
                    hasProgress: hasProgress,
                    progressPercentage: progressPercentage,
                    progressText: progressText,
                    showingPlayer: $showingPlayer,
                    dismiss: { dismiss() }
                )
            } else {
                MovieDetailLayouts.PortraitLayout(
                    item: item,
                    hasProgress: hasProgress,
                    progressPercentage: progressPercentage,
                    progressText: progressText,
                    showingPlayer: $showingPlayer,
                    dismiss: { dismiss() }
                )
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item, startTime: item.userData.playbackPositionTicks.map { Double($0) / 10_000_000 })
        }
    }
} 