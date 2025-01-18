import SwiftUI

/// Shared layout components that can be used across different orientations
struct LayoutComponents {
    /// Hero section layout for media details
    struct HeroSection: View {
        let imageId: String
        let onBackTapped: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @EnvironmentObject private var layoutManager: LayoutManager
        
        var body: some View {
            ZStack(alignment: .top) {
                // Backdrop
                JellyfinImage(
                    itemId: imageId,
                    imageType: .backdrop,
                    aspectRatio: layoutManager.isLandscape ? 21/9 : 16/9,
                    cornerRadius: 0,
                    fallbackIcon: "film"
                )
                .frame(maxWidth: .infinity)
                .frame(height: layoutManager.isLandscape ? 320 : 260)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.3),
                            .black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                }
                
                // Back button
                Button(action: onBackTapped) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    /// Media poster with optional progress indicator
    struct MediaPoster: View {
        let itemId: String
        var progress: Double? = nil
        var width: CGFloat = 120
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            VStack(spacing: 0) {
                JellyfinImage(
                    itemId: itemId,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 12,
                    fallbackIcon: "film"
                )
                .frame(width: width)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                
                if let progress = progress {
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(themeManager.currentTheme.surfaceColor.opacity(0.2))
                                .frame(height: 3)
                            
                            Rectangle()
                                .fill(themeManager.currentTheme.accentGradient)
                                .frame(width: max(0, min(metrics.size.width * progress, metrics.size.width)), height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    /// Media metadata display (title, year, runtime, etc.)
    struct MediaMetadata: View {
        let title: String
        let year: String?
        let runtime: String?
        let rating: String?
        let genres: [String]
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                // Quick Info Row
                HStack(spacing: 12) {
                    if let year = year {
                        Text(year)
                    }
                    
                    if let runtime = runtime {
                        Text("•")
                        Text(runtime)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                // Rating
                if let rating = rating {
                    Text(rating)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.currentTheme.surfaceColor.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Genres
                if !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Backdrop image for media details
    struct BackdropImage: View {
        let itemId: String
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            GeometryReader { geometry in
                JellyfinImage(
                    itemId: itemId,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 0,
                    fallbackIcon: "film"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                .clipped()
                .offset(y: -geometry.safeAreaInsets.top)
            }
            .ignoresSafeArea()
        }
    }
}

struct SeparatedHStack<Content: View>: View {
    let content: Content
    let separator: AnyView
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8, separator: AnyView, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.separator = separator
        self.spacing = spacing
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            content
        }
    }
}

extension View {
    func separatedBy<S: View>(_ separator: S) -> some View {
        HStack(spacing: 4) {
            self
            separator
        }
    }
} 