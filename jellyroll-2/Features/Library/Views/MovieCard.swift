import SwiftUI

struct MovieCard: View {
    let item: MediaItem
    let style: Style
    
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
            ZStack(alignment: .bottom) {
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    fallbackIcon: "film"
                )
                .frame(maxWidth: style.imageWidth)
                .frame(height: style.imageHeight)
                
                // Progress Bar (only shown if there's progress)
                if hasProgress {
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            
                            // Progress
                            Rectangle()
                                .fill(JellyfinTheme.accentGradient)
                                .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 3)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 8)
                }
            }
            
            // Movie Title
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(JellyfinTheme.Text.primary)
                .lineLimit(style.titleLineLimit)
            
            // Movie Metadata
            HStack {
                if let year = item.yearText {
                    Text(year)
                }
                if let genre = item.genreText {
                    Text("•")
                    Text(genre)
                }
            }
            .font(.caption)
            .foregroundColor(JellyfinTheme.Text.secondary)
            
            // Rating
            if let rating = item.communityRating {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(JellyfinTheme.accentGradient)
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(JellyfinTheme.Text.secondary)
                }
                .font(.caption)
            }
        }
        .padding(8)
        .background(JellyfinTheme.elevatedSurfaceColor)
        .cornerRadius(12)
    }
} 