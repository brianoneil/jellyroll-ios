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
        return PlaybackProgressUtility.calculateProgress(positionTicks: item.userData.playbackPositionTicks, totalTicks: item.runTimeTicks) ?? 0
    }
    
    private var progressText: String {
        return PlaybackProgressUtility.formatRemainingTime(
            positionTicks: item.userData.playbackPositionTicks,
            totalTicks: item.runTimeTicks
        ) ?? ""
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
            VideoPlayerView(item: item, startTime: item.userData.playbackPositionTicks.map { PlaybackProgressUtility.ticksToSeconds($0) })
        }
        .trackScreenView("Movie Details - \(item.name)")
    }
} 