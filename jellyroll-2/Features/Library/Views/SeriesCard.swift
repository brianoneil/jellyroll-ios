import SwiftUI

struct SeriesCard: View {
    let item: MediaItem
    let style: Style
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isHovered = false
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster Image
            JellyfinImage(
                itemId: item.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 8,
                fallbackIcon: "tv",
                blurHash: item.imageBlurHashes["Primary"]?.values.first
            )
            .frame(maxWidth: style.imageWidth)
            .frame(height: style.imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Series Title
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(style.titleLineLimit)
                
                // Series Metadata
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
        .fullScreenCover(isPresented: $showingDetail) {
            NavigationStack {
                SeriesDetailView(item: item)
            }
        }
    }
} 