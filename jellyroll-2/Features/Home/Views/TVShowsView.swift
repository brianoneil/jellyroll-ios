import SwiftUI

/// A tvOS-optimized view for browsing TV show libraries
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
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 24) {
                        Button("All") {
                            selectedGenre = nil
                        }
                        .buttonStyle(.tvCard(isSelected: selectedGenre == nil))
                        
                        ForEach(libraryViewModel.allGenres, id: \.self) { genre in
                            Button(genre) {
                                selectedGenre = genre
                            }
                            .buttonStyle(.tvCard(isSelected: selectedGenre == genre))
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Shows Grid
                ForEach(libraries) { library in
                    let shows = libraryViewModel.getTVShowItems(for: library.id)
                    let filteredShows = selectedGenre == nil ? shows : shows.filter { $0.genres.contains(selectedGenre!) }
                    
                    if !filteredShows.isEmpty {
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
                                ForEach(filteredShows) { show in
                                    TVShowCard(item: show)
                                        .frame(height: 400)
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

struct TVShowCard: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        NavigationLink(destination: SeriesDetailView(item: item)) {
            VStack(alignment: .leading, spacing: 16) {
                // Poster Image
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 8,
                    fallbackIcon: "tv"
                )
                
                // Show Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .lineLimit(1)
                    
                    if let year = item.productionYear {
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
        .buttonStyle(.plain)
    }
}

#Preview {
    TVShowsView(libraries: [])
        .environmentObject(ThemeManager())
} 