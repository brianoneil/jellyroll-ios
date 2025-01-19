import SwiftUI

struct RecentlyAddedCard: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            JellyfinImage(
                itemId: item.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 12,
                fallbackIcon: "film"
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let year = item.yearText {
                        Text(year)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    if let genre = item.genreText {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.7))
                        Text(genre)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
} 