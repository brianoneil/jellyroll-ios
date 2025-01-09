import SwiftUI

/// Orientation-specific layouts for movie detail view
struct MovieDetailLayouts {
    /// Portrait layout for movie details
    struct PortraitLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    LayoutComponents.HeroSection(
                        imageId: item.id,
                        onBackTapped: dismiss
                    )
                    
                    // Content
                    VStack(spacing: 24) {
                        // Poster and Metadata Section
                        HStack(spacing: 16) {
                            // Poster
                            LayoutComponents.MediaPoster(
                                itemId: item.id,
                                progress: hasProgress ? progressPercentage : nil
                            )
                            .frame(height: 180)
                            
                            // Metadata
                            LayoutComponents.MediaMetadata(
                                title: item.name,
                                year: item.yearText,
                                runtime: item.formattedRuntime,
                                rating: item.officialRating,
                                genres: item.genres
                            )
                        }
                        .padding(.horizontal, 24)
                        .offset(y: -90)
                        .padding(.bottom, -90)
                        
                        // Featured Tagline
                        if item.taglines.count == 1, let tagline = item.taglines.first {
                            Text(tagline)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Play Button
                        Button(action: { showingPlayer.wrappedValue = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text(hasProgress ? "Resume" : "Play")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.currentTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        
                        // Overview
                        if let overview = item.overview {
                            Text(overview)
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    /// Landscape layout for movie details
    struct LandscapeLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            HStack(spacing: 0) {
                // Left column with poster and play button
                VStack(spacing: 24) {
                    LayoutComponents.MediaPoster(
                        itemId: item.id,
                        progress: hasProgress ? progressPercentage : nil,
                        width: 200
                    )
                    
                    Button(action: { showingPlayer.wrappedValue = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text(hasProgress ? "Resume" : "Play")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(24)
                .frame(width: 248)
                
                // Right column with scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        LayoutComponents.HeroSection(
                            imageId: item.id,
                            onBackTapped: dismiss
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
                            
                            // Featured Tagline
                            if item.taglines.count == 1, let tagline = item.taglines.first {
                                Text(tagline)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Overview
                            if let overview = item.overview {
                                Text(overview)
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .all)
        }
    }
} 