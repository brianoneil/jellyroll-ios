import SwiftUI

struct MovieCard: View {
    let item: MediaItem
    let style: Style
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isHovered = false
    @State private var showingPlayer = false
    @State private var showingDetail = false
    
    enum Style {
        case grid
        case list
        
        var imageWidth: CGFloat {
            switch self {
            case .grid: return .infinity
            case .list: return 160
            }
        }
        
        var imageHeight: CGFloat {
            switch self {
            case .grid: return 240
            case .list: return 240
            }
        }
        
        var titleLineLimit: Int {
            switch self {
            case .grid: return 2
            case .list: return 1
            }
        }
    }
    
    init(item: MediaItem, style: Style = .list) {
        self.item = item
        self.style = style
    }
    
    private var progressPercentage: Double {
        if let position = item.playbackPositionTicks,
           let total = item.runTimeTicks,
           total > 0 {
            return Double(position) / Double(total)
        }
        return 0
    }
    
    private var hasProgress: Bool {
        return progressPercentage > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster Image with Progress Overlay
            ZStack(alignment: .bottomTrailing) {
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 8,
                    fallbackIcon: "film",
                    blurHash: {
                        let hash = item.imageBlurHashes["Primary"]?.values.first
                        return hash
                    }()
                )
                .frame(maxWidth: style.imageWidth)
                .frame(height: style.imageHeight)
                
                VStack(alignment: .trailing) {
                    Spacer()
                    
                    // Play button
                    Button(action: {
                        showingPlayer = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(10)
                        .background(themeManager.currentTheme.accentGradient)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .padding([.trailing, .bottom], 12)
                }
                
                // Progress Bar (only shown if there's progress)
                if hasProgress {
                    VStack {
                        Spacer()
                        GeometryReader { metrics in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.2))
                                    .frame(height: 3)
                                
                                // Progress
                                Rectangle()
                                    .fill(themeManager.currentTheme.accentGradient)
                                    .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 8)
                    }
                    .background(
                        LinearGradient(
                            colors: [.clear, themeManager.currentTheme.backgroundColor.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Movie Title
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(style.titleLineLimit)
                
                // Movie Metadata
                HStack(spacing: 4) {
                    if let year = item.yearText {
                        Text(year)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    if let genre = item.genreText {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                        Text(genre)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    if let rating = item.communityRating {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(themeManager.currentTheme.accentGradient)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(themeManager.currentTheme.cardGradient)
        .cornerRadius(12)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item, startTime: item.playbackPositionTicks.map { Double($0) / 10_000_000 })
        }
        .fullScreenCover(isPresented: $showingDetail) {
            NavigationStack {
                MovieDetailView(item: item)
            }
        }
    }
} 