import SwiftUI
import OSLog

struct ContinueWatchingCard: View {
    let item: MediaItem
    let isSelected: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "ContinueWatchingCard")
    @State private var showingPlayer = false
    
    private var progressPercentage: Double {
        return PlaybackProgressUtility.calculateProgress(positionTicks: item.playbackPositionTicks, totalTicks: item.runTimeTicks) ?? 0
    }
    
    private var progressText: String {
        if let remainingTime = PlaybackProgressUtility.formatRemainingTime(
            positionTicks: item.playbackPositionTicks,
            totalTicks: item.runTimeTicks
        ) {
            return remainingTime
        } else {
            return "\(Int(round(progressPercentage * 100)))%"
        }
    }
    
    private var imageId: String {
        // For episodes, use the series ID if available
        if item.type.lowercased() == "episode", let seriesId = item.seriesId {
            return seriesId
        }
        return item.id
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            // Main Image with Metadata
            JellyfinImage(
                itemId: imageId,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 12,
                fallbackIcon: "play.circle.fill",
                blurHash: {
                    let hash = item.imageBlurHashes["Primary"]?.values.first
                    return hash
                }()
            )
            .overlay(
                // Bottom Metadata Overlay
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        // Show series name first for episodes
                        if item.type.lowercased() == "episode", let seriesName = item.seriesName {
                            Text(seriesName)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Additional metadata row
                        HStack(spacing: 4) {
                            if let year = item.yearText {
                                Text(year)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            if let genre = item.genreText {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(genre)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            if let episodeInfo = formatEpisodeInfo() {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(episodeInfo)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // Progress row
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(themeManager.currentTheme.accentColor)
                            Text(progressText)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        
                        // Progress Bar
                        GeometryReader { metrics in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                
                                Rectangle()
                                    .fill(themeManager.currentTheme.accentColor)
                                    .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(8)
                }
            )
            
            // Play Button (centered)
            if isSelected {
                Button(action: { showingPlayer = true }) {
                    Circle()
                        .fill(themeManager.currentTheme.accentGradient)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .scaleEffect(isSelected ? 1.0 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item, startTime: item.playbackPositionTicks.map { Double($0) / 10_000_000 })
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