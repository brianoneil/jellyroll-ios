import SwiftUI

#if os(tvOS)
/// A card component for displaying continue watching items
struct TVContinueWatchingCard: View {
    let item: MediaItem
    let isSelected: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingPlayer = false
    
    private var progressPercentage: Double {
        PlaybackProgressUtility.calculateProgress(positionTicks: item.playbackPositionTicks, totalTicks: item.runTimeTicks) ?? 0
    }
    
    var body: some View {
        ZStack {
            // Background Image
            JellyfinImage(
                itemId: item.id,
                imageType: .backdrop,
                aspectRatio: 16/9,
                cornerRadius: 16,
                fallbackIcon: "play.circle.fill"
            )
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.8),
                        .black.opacity(0.4),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            
            // Content Overlay
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                
                // Title and Metadata
                VStack(alignment: .leading, spacing: 8) {
                    if item.type.lowercased() == "episode", let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Progress Bar
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(themeManager.currentTheme.accentColor)
                                .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                    
                    // Additional Info
                    HStack(spacing: 16) {
                        if let remainingTime = PlaybackProgressUtility.formatRemainingTime(
                            positionTicks: item.playbackPositionTicks,
                            totalTicks: item.runTimeTicks
                        ) {
                            Label(remainingTime, systemImage: "clock")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        if let episodeInfo = item.episodeInfo {
                            Text(episodeInfo)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .font(.callout)
                }
                .padding(24)
            }
            
            // Play Button Overlay when focused
            if isSelected {
                Button(action: { showingPlayer = true }) {
                    Label("Resume", systemImage: "play.fill")
                        .font(.title3)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accentColor)
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item, startTime: item.playbackPositionTicks.map { Double($0) / 10_000_000 })
        }
    }
}

/// A card component for displaying recently added items
struct TVRecentlyAddedCard: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Image
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 16,
                    fallbackIcon: item.type.lowercased() == "series" ? "tv" : "film"
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isFocused ? themeManager.currentTheme.accentColor : Color.clear,
                            lineWidth: 4
                        )
                )
                
                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if let year = item.yearText {
                            Text(year)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        if let genre = item.genreText {
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.7))
                            Text(genre)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .font(.callout)
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
        .fullScreenCover(isPresented: $showingDetail) {
            if item.type.lowercased() == "movie" {
                MovieDetailView(item: item)
            } else if item.type.lowercased() == "series" {
                SeriesDetailView(item: item)
            }
        }
    }
}
#endif 