import SwiftUI
import AVKit

/// A tvOS-optimized home screen that showcases featured content and continue watching items
struct TVHomeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedItem: MediaItem?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                // Featured Content Section
                if let featured = libraryViewModel.continueWatching.first {
                    FeaturedSection(item: featured)
                        .frame(height: 600)
                }
                
                // Continue Watching Section
                if !libraryViewModel.continueWatching.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Continue Watching")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 32) {
                                ForEach(libraryViewModel.continueWatching) { item in
                                    ContinueWatchingCard(item: item)
                                        .frame(width: 400)
                                        .focusable()
                                        .onPlayPauseCommand {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Recently Added Section
                if !libraryViewModel.latestMedia.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Recently Added")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 32) {
                                ForEach(libraryViewModel.latestMedia) { item in
                                    RecentlyAddedCard(item: item)
                                        .frame(width: 300)
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
        .task {
            await libraryViewModel.loadLibraries()
        }
        .fullScreenCover(item: $selectedItem) { item in
            VideoPlayerView(item: item)
        }
    }
}

/// A large featured content section that appears at the top of the home screen
struct FeaturedSection: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            JellyfinImage(
                itemId: item.id,
                imageType: .backdrop,
                aspectRatio: 16/9,
                cornerRadius: 0,
                fallbackIcon: "play.circle.fill"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    .black.opacity(0.7),
                    .black.opacity(0.3),
                    .clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content Info
            VStack(alignment: .leading, spacing: 16) {
                Text(item.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let overview = item.overview {
                    Text(overview)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .frame(maxWidth: 600, alignment: .leading)
                }
                
                Button(action: {}) {
                    Label("Play", systemImage: "play.fill")
                        .font(.title3)
                        .padding()
                        .background(themeManager.currentTheme.accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .focusable()
            }
            .padding(48)
        }
        .focusable()
        .cornerRadius(20)
    }
}

// MARK: - TV-Optimized Card Button Style
struct CardButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Continue Watching Section
struct TVContinueWatchingSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let items: [MediaItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Continue Watching")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        ContinueWatchingCard(item: item, isSelected: false)
                            .frame(width: 400, height: 300)
                            .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Recently Added Section
struct TVRecentlyAddedSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let items: [MediaItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recently Added")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        RecentlyAddedCard(item: item)
                            .frame(width: 300)
                            .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Movies Section
struct TVMoviesSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let libraries: [LibraryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Movies")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(libraries) { library in
                        NavigationLink(destination: MoviesTabView(libraries: [library], libraryViewModel: LibraryViewModel())) {
                            TVMovieCard(library: library)
                                .frame(width: 250, height: 375)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - TV Shows Section
struct TVShowsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let libraries: [LibraryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TV Shows")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(libraries) { library in
                        NavigationLink(destination: SeriesTabView(libraries: [library], libraryViewModel: LibraryViewModel())) {
                            TVSeriesCard(library: library)
                                .frame(width: 250, height: 375)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Music Section
struct TVMusicSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let libraries: [LibraryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Music")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(libraries) { library in
                        NavigationLink(destination: MusicTabView(libraries: [library], libraryViewModel: LibraryViewModel())) {
                            TVMusicCard(library: library)
                                .frame(width: 250, height: 250)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - TV-Optimized Card Components
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

#Preview {
    TVHomeView()
        .environmentObject(ThemeManager())
} 