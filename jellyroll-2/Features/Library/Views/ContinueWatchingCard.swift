import SwiftUI
import OSLog

struct ContinueWatchingCard: View {
    let item: MediaItem
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "ContinueWatchingCard")
    @State private var isHovered = false
    
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
            if let firstNumber = remainingTime.first(where: { $0.isNumber }),
               let lastNumberIndex = remainingTime.lastIndex(where: { $0.isNumber }) {
                let index = remainingTime.index(after: lastNumberIndex)
                let numbers = remainingTime[...lastNumberIndex]
                let text = remainingTime[index...]
                return "\(numbers) \(text)"
            }
            return remainingTime
        } else {
            return "\(Int(round(progressPercentage * 100)))%"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background Image
                JellyfinImage(
                    itemId: item.id,
                    imageType: .backdrop,
                    aspectRatio: 16/9,
                    cornerRadius: 12,
                    fallbackIcon: "play.circle.fill"
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Play Button Overlay (visible on hover)
                if isHovered {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(JellyfinTheme.accentGradient)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Content Overlay
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    // Title and metadata
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(JellyfinTheme.textGradient)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // Metadata row
                        HStack(spacing: 8) {
                            // Episode info for TV shows
                            if let episodeInfo = formatEpisodeInfo() {
                                Text(episodeInfo)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            // Year
                            if let year = item.yearText {
                                Text(year)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            // Genre
                            if let genre = item.genreText {
                                Text(genre)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // Progress info
                        HStack(spacing: 8) {
                            // Progress indicator
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(JellyfinTheme.accentGradient)
                                Text(progressText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    
                    // Progress Bar
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress
                            Rectangle()
                                .fill(JellyfinTheme.accentGradient)
                                .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 4)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 4)
                }
                .background(
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.3),
                            .black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
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