import SwiftUI

#if os(tvOS)
/// A tvOS-optimized view for browsing movie libraries
struct TVMoviesView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedGenre: String?
    @State private var selectedMovie: MediaItem?
    let libraries: [LibraryItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                // Genre Selection
                TVMovieGenreSelectionView(selectedGenre: $selectedGenre, genres: libraryViewModel.allGenres)
                
                // Movies Grid
                ForEach(libraries) { library in
                    let movies = libraryViewModel.getMovieItems(for: library.id)
                    let filteredMovies = selectedGenre == nil ? movies : movies.filter { $0.genres.contains(selectedGenre!) }
                    
                    if !filteredMovies.isEmpty {
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
                                ForEach(filteredMovies) { movie in
                                    MovieCard(item: movie)
                                        .frame(height: 400)
                                        .focusable()
                                        .onPlayPauseCommand {
                                            selectedMovie = movie
                                        }
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
        .fullScreenCover(item: $selectedMovie) { movie in
            VideoPlayerView(item: movie)
        }
    }
}

/// Genre selection view component for movies
struct TVMovieGenreSelectionView: View {
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

#Preview("TV Movies") {
    TVMoviesView(libraries: [])
        .environmentObject(ThemeManager())
}
#endif 