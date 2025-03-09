import SwiftUI

/// A tvOS-optimized view for browsing TV show libraries
#if os(tvOS)
struct TVShowsView: View {
    let libraries: [LibraryItem]
    @StateObject private var libraryViewModel = LibraryViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedShow: MediaItem?
    @State private var selectedGenre: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                // Genre Selection
                TVShowGenreSelectionView(selectedGenre: $selectedGenre, genres: libraryViewModel.allGenres)
                
                // Shows Grid
                ForEach(libraries) { library in
                    LibraryShowsView(
                        library: library,
                        shows: libraryViewModel.getTVShowItems(for: library.id),
                        selectedGenre: selectedGenre,
                        showLibraryName: libraries.count > 1
                    )
                }
            }
            .padding(.vertical, 48)
        }
        .task {
            await libraryViewModel.loadLibraries()
        }
    }
}

/// Genre selection view component for TV shows
struct TVShowGenreSelectionView: View {
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

/// Library shows view component
struct LibraryShowsView: View {
    let library: LibraryItem
    let shows: [MediaItem]
    let selectedGenre: String?
    let showLibraryName: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var filteredShows: [MediaItem] {
        guard let genre = selectedGenre else { return shows }
        return shows.filter { $0.genres.contains(genre) }
    }
    
    var body: some View {
        if !filteredShows.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                if showLibraryName {
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
                    ForEach(filteredShows) { show in
                        NavigationLink(destination: SeriesDetailView(item: show)) {
                            TVShowCard(show: show)
                                .frame(height: 400)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TVShowCard: View {
    let show: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Poster Image
            JellyfinImage(
                itemId: show.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 8,
                fallbackIcon: "tv"
            )
            
            // Show Info
            VStack(alignment: .leading, spacing: 4) {
                Text(show.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(1)
                
                if let year = show.productionYear {
                    Text(String(year))
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
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

#Preview("TV Shows") {
    TVShowsView(libraries: [])
        .environmentObject(ThemeManager())
}
#endif 