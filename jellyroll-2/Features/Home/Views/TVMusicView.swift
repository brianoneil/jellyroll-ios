import SwiftUI

#if os(tvOS)
/// A tvOS-optimized view for browsing music libraries
struct TVMusicView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedGenre: String?
    let libraries: [LibraryItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                // Genre Selection
                TVMusicGenreSelectionView(selectedGenre: $selectedGenre, genres: libraryViewModel.allGenres)
                
                // Music Grid
                ForEach(libraries) { library in
                    let albums = libraryViewModel.getMusicItems(for: library.id)
                    let filteredAlbums = selectedGenre == nil ? albums : albums.filter { $0.genres.contains(selectedGenre!) }
                    
                    if !filteredAlbums.isEmpty {
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
                                ForEach(filteredAlbums) { album in
                                    TVMusicCard(album: album)
                                        .frame(height: 300)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 48)
        }
        .task {
            await libraryViewModel.loadLibraries()
        }
    }
}

struct TVMusicCard: View {
    let album: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Album Art
            JellyfinImage(
                itemId: album.id,
                imageType: .primary,
                aspectRatio: 1,
                cornerRadius: 8,
                fallbackIcon: "music.note"
            )
            
            // Album Info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(1)
                
                if let artist = album.artistText {
                    Text(artist)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.elevatedSurfaceColor)
                .brightness(isFocused ? 0.1 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

/// Genre selection view component for music
struct TVMusicGenreSelectionView: View {
    @Binding var selectedGenre: String?
    let genres: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 24) {
                Button("All") {
                    selectedGenre = nil
                }
                .buttonStyle(TVCardButtonStyle(isSelected: selectedGenre == nil))
                
                ForEach(genres, id: \.self) { genre in
                    Button(genre) {
                        selectedGenre = genre
                    }
                    .buttonStyle(TVCardButtonStyle(isSelected: selectedGenre == genre))
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview("TV Music") {
    TVMusicView(libraries: [])
        .environmentObject(ThemeManager())
}
#endif 