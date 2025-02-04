import SwiftUI

/// A tvOS-optimized view for browsing movie libraries
struct TVMoviesView: View {
    let libraries: [LibraryItem]
    @StateObject private var libraryViewModel = LibraryViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedMovie: MediaItem?
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
        .fullScreenCover(item: $selectedMovie) { movie in
            VideoPlayerView(item: movie)
        }
    }
}

/// A custom button style for tvOS cards
struct TVCardButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

extension ButtonStyle where Self == TVCardButtonStyle {
    static func tvCard(isSelected: Bool) -> TVCardButtonStyle {
        TVCardButtonStyle(isSelected: isSelected)
    }
}

#Preview {
    TVMoviesView(libraries: [])
        .environmentObject(ThemeManager())
} 