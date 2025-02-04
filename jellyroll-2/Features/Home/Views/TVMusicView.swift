import SwiftUI

/// A tvOS-optimized view for browsing music libraries
struct TVMusicView: View {
    let libraries: [LibraryItem]
    @StateObject private var libraryViewModel = LibraryViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedAlbum: MediaItem?
    @State private var selectedCategory: MusicCategory = .albums
    
    enum MusicCategory {
        case albums
        case artists
        case genres
        case playlists
        
        var title: String {
            switch self {
            case .albums: return "Albums"
            case .artists: return "Artists"
            case .genres: return "Genres"
            case .playlists: return "Playlists"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                // Category Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 24) {
                        ForEach([MusicCategory.albums, .artists, .genres, .playlists], id: \.self) { category in
                            Button(category.title) {
                                selectedCategory = category
                            }
                            .buttonStyle(.tvCard(isSelected: selectedCategory == category))
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Music Grid
                ForEach(libraries) { library in
                    let musicItems = libraryViewModel.getMusicItems(for: library.id)
                    
                    if !musicItems.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            if libraries.count > 1 {
                                Text(library.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .padding(.horizontal)
                            }
                            
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 48)
                                ],
                                spacing: 48
                            ) {
                                ForEach(musicItems) { item in
                                    MusicCard(item: item)
                                        .frame(height: 300)
                                        .focusable()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 48)
        }
    }
}

struct MusicCard: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JellyfinImage(
                itemId: item.id,
                imageType: .primary,
                aspectRatio: 1,
                cornerRadius: 8,
                fallbackIcon: "music.note"
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(1)
                
                if let artistText = item.artistText {
                    Text(artistText)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    TVMusicView(libraries: [])
        .environmentObject(ThemeManager())
} 