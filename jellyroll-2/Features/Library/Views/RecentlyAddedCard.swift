import SwiftUI

struct RecentlyAddedCard: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingDetail = false
    @State private var showingMessage = false
    
    var body: some View {
        Button(action: {
            if item.type.lowercased() == "movie" || item.type.lowercased() == "series" {
                showingDetail = true
            } else {
                showingMessage = true
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 12,
                    fallbackIcon: item.type.lowercased() == "series" ? "tv" : "film",
                    blurHash: {
                        let hash = item.imageBlurHashes["Primary"]?.values.first
                        return hash
                    }()
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
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetail) {
            if item.type.lowercased() == "movie" {
                MovieDetailView(item: item)
            } else if item.type.lowercased() == "series" {
                SeriesDetailView(item: item)
            }
        }
        .alert("Coming Soon", isPresented: $showingMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Details for \(item.type) items coming soon!")
        }
    }
} 