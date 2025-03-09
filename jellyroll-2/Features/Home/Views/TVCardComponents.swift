import SwiftUI

#if os(tvOS)
/// A card component for displaying movie libraries
struct TVMovieCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let library: LibraryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            JellyfinImage(
                itemId: library.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 10,
                fallbackIcon: "film"
            )
            
            Text(library.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .lineLimit(1)
        }
    }
}

/// A card component for displaying TV show libraries
struct TVSeriesCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let library: LibraryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            JellyfinImage(
                itemId: library.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 10,
                fallbackIcon: "tv"
            )
            
            Text(library.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .lineLimit(1)
        }
    }
}

/// A card component for displaying music libraries
struct TVMusicCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let library: LibraryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            JellyfinImage(
                itemId: library.id,
                imageType: .primary,
                aspectRatio: 1,
                cornerRadius: 10,
                fallbackIcon: "music.note"
            )
            
            Text(library.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .lineLimit(1)
        }
    }
}
#endif 