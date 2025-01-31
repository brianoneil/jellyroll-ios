import SwiftUI

struct SeriesDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @State private var showingPlayer = false
    @StateObject private var playbackService = PlaybackService.shared
    @State private var isDownloading = false
    @State private var downloadError: String?
    
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
                SeriesDetailLayouts.LandscapeLayout(
                    item: item,
                    hasProgress: hasProgress,
                    progressPercentage: progressPercentage,
                    progressText: progressText,
                    showingPlayer: $showingPlayer,
                    dismiss: { dismiss() }
                )
            } else {
                SeriesDetailLayouts.PortraitLayout(
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
    }
}

// MARK: - Layout Namespace
enum SeriesDetailLayouts {
    struct PortraitLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        @Binding var showingPlayer: Bool
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var playbackService = PlaybackService.shared
        @State private var isDownloading = false
        @State private var downloadError: String?
        
        var body: some View {
            ZStack {
                // Background Image Layer
                LayoutComponents.BackdropImage(
                    itemId: item.id,
                    blurHash: item.imageBlurHashes["Primary"]?.values.first
                )
                .edgesIgnoringSafeArea(.all)
                
                // Optional overlay gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        themeManager.currentTheme.backgroundColor.opacity(0.2),
                        themeManager.currentTheme.backgroundColor.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content Layer
                ZStack(alignment: .bottom) {
                    // Top Navigation and Actions
                    VStack {
                        HStack(alignment: .top) {
                            // Back Button
                            Button(action: dismiss) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .padding(12)
                                    .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Right-side vertical controls
                            VStack(spacing: 16) {
                                Button(action: {}) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(themeManager.currentTheme.iconColor)
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 20))
                                        .foregroundColor(themeManager.currentTheme.iconColor)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .frame(width: 50)
                            .background(.ultraThinMaterial)
                            .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 36)
                        Spacer()
                    }
                    .safeAreaInset(edge: .top) { Color.clear.frame(height: 24) }
                    
                    // Content Card with blur effect
                    VStack(spacing: 0) {
                        // Content
                        VStack(alignment: .leading, spacing: 20) {
                            // Title
                            Text(item.name)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            
                            // Progress Bar (if series is partially watched)
                            if hasProgress {
                                VStack(spacing: 4) {
                                    GeometryReader { metrics in
                                        ZStack(alignment: .leading) {
                                            // Background bar
                                            Rectangle()
                                                .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
                                                .frame(height: 3)
                                            
                                            // Progress bar
                                            Rectangle()
                                                .fill(themeManager.currentTheme.accentGradient)
                                                .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 3)
                                        }
                                    }
                                    .frame(height: 3)
                                    
                                    Text(progressText)
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // Quick Info Row
                            HStack(spacing: 12) {
                                if let year = item.yearText {
                                    Text(year)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                
                                if let runtime = item.formattedRuntime {
                                    Text("•")
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
                                    Text(runtime)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                
                                if let officialRating = item.officialRating {
                                    Text("•")
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
                                    Text(officialRating)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                            }
                            .font(.system(size: 15))
                            
                            // Overview
                            if let overview = item.overview {
                                Text(overview)
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .lineSpacing(4)
                                    .lineLimit(3)
                            }
                            
                            // Action Buttons
                            HStack(spacing: 12) {
                                // Watch Now Button
                                Button(action: { showingPlayer = true }) {
                                    Text(hasProgress ? "Resume" : "Watch now")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(themeManager.currentTheme.accentGradient)
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .cornerRadius(8)
                                }
                                
                                // Trailer Button
                                Button(action: {}) {
                                    Text("Trailer")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(themeManager.currentTheme.surfaceColor.opacity(0.2))
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(24)
                    }
                    .background(.ultraThinMaterial)
                    .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .edgesIgnoringSafeArea(.all)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
        }
    }
    
    struct LandscapeLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        @Binding var showingPlayer: Bool
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var playbackService = PlaybackService.shared
        @State private var isDownloading = false
        @State private var downloadError: String?
        
        var body: some View {
            HStack(spacing: 0) {
                // Left column with poster and actions
                VStack(alignment: .leading, spacing: 24) {
                    // Poster
                    JellyfinImage(
                        itemId: item.id,
                        imageType: .primary,
                        aspectRatio: 2/3,
                        cornerRadius: 12,
                        fallbackIcon: "tv"
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Play Button
                        Button(action: { showingPlayer = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(hasProgress ? "Continue Watching" : "Play")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.currentTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Trailer Button
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "play.rectangle")
                                Text("Trailer")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.surfaceColor.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(24)
                .frame(width: 248)
                
                // Right column with scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        LayoutComponents.HeroSection(
                            imageId: item.id,
                            onBackTapped: dismiss,
                            blurHash: item.imageBlurHashes["Primary"]?.values.first
                        )
                        
                        VStack(spacing: 24) {
                            // Metadata
                            LayoutComponents.MediaMetadata(
                                title: item.name,
                                year: item.yearText,
                                runtime: item.formattedRuntime,
                                rating: item.officialRating,
                                genres: item.genres
                            )
                            .padding(.horizontal, 24)
                            
                            // Action Buttons Row
                            HStack(spacing: 32) {
                                // My List Button
                                VStack(spacing: 8) {
                                    Button(action: {}) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                    Text("My List")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Like Button
                                VStack(spacing: 8) {
                                    Button(action: {}) {
                                        Image(systemName: "heart")
                                            .font(.system(size: 24))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                    Text("Like")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            }
                            .padding(.horizontal, 24)
                            
                            // Overview
                            if let overview = item.overview {
                                Text(overview)
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .lineSpacing(4)
                                    .lineLimit(3)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .all)
            .navigationBarHidden(true)
        }
    }
} 