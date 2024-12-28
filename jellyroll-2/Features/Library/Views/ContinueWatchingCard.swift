import SwiftUI
import OSLog

struct ContinueWatchingCard: View {
    let item: MediaItem
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "ContinueWatchingCard")
    
    private var progressPercentage: Double {
        logger.notice("🎬 PROGRESS DEBUG [Item: \(item.name)] ==================")
        logger.notice("🎬 Position Ticks: \(item.playbackPositionTicks?.description ?? "nil")")
        logger.notice("🎬 Runtime Ticks: \(item.runTimeTicks?.description ?? "nil")")
        
        let manualProgress: Double
        if let position = item.playbackPositionTicks,
           let total = item.runTimeTicks,
           total > 0 {
            manualProgress = Double(position) / Double(total)
            logger.notice("🎬 Calculated Progress: \(String(format: "%.4f", manualProgress))")
        } else {
            manualProgress = 0
            logger.notice("🎬 No valid progress data available")
        }
        logger.notice("🎬 ============================================")
        
        return manualProgress
    }
    
    private var progressText: String {
        if let remainingTime = item.remainingTime {
            return remainingTime
        } else {
            return "\(Int(round(progressPercentage * 100)))%"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background Image
                JellyfinImage(
                    itemId: item.id,
                    imageType: .backdrop,
                    aspectRatio: 16/9,
                    cornerRadius: 0,
                    fallbackIcon: "play.circle.fill"
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Content Overlay
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    // Title and metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(JellyfinTheme.textGradient)
                        
                        HStack(spacing: 8) {
                            // Episode info for TV shows
                            if let episodeInfo = formatEpisodeInfo() {
                                Text(episodeInfo)
                                    .font(.system(size: 16))
                                    .foregroundColor(JellyfinTheme.Text.secondary)
                            }
                            
                            // Progress info
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(JellyfinTheme.accentGradient)
                                    .frame(width: 6, height: 6)
                                Text(progressText)
                                    .font(.system(size: 16))
                                    .foregroundColor(JellyfinTheme.Text.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Progress Bar
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 3)
                            
                            // Progress
                            Rectangle()
                                .fill(JellyfinTheme.accentGradient)
                                .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 3)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 3)
                }
                .background(JellyfinTheme.overlayGradient)
            }
        }
    }
    
    private func formatEpisodeInfo() -> String? {
        if item.type.lowercased() == "episode",
           let seasonNumber = item.seasonNumber,
           let episodeNumber = item.episodeNumber {
            return "S\(seasonNumber):E\(episodeNumber)"
        }
        return nil
    }
} 