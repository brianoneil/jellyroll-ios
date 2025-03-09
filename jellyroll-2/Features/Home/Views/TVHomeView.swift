import SwiftUI
import AVKit

/// A tvOS-optimized home screen that showcases featured content and continue watching items
#if os(tvOS)
struct TVHomeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedItem: MediaItem?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 48) {
                // Featured Content Section
                if let featured = libraryViewModel.continueWatching.first {
                    FeaturedContentSection(featured: featured)
                }
                
                // Continue Watching Section
                if !libraryViewModel.continueWatching.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Continue Watching")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            .padding(.horizontal, 48)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 32) {
                                ForEach(libraryViewModel.continueWatching) { item in
                                    TVContinueWatchingCard(item: item, isSelected: selectedItem == item)
                                        .frame(width: 600)
                                        .focusable()
                                        .onPlayPauseCommand {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal, 48)
                        }
                    }
                }
                
                // Recently Added Section
                if !libraryViewModel.latestMedia.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Recently Added")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            .padding(.horizontal, 48)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 32) {
                                ForEach(libraryViewModel.latestMedia) { item in
                                    TVRecentlyAddedCard(item: item)
                                        .frame(width: 300)
                                        .focusable()
                                }
                            }
                            .padding(.horizontal, 48)
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

/// Featured content section component
struct FeaturedContentSection: View {
    let featured: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingPlayer = false
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        Button(action: { showingPlayer = true }) {
            ZStack(alignment: .bottomLeading) {
                // Background Image
                JellyfinImage(
                    itemId: featured.id,
                    imageType: .backdrop,
                    aspectRatio: 16/9,
                    cornerRadius: 0,
                    fallbackIcon: "play.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 700)
                
                // Gradient Overlay
                LinearGradient(
                    colors: [
                        .black.opacity(0.8),
                        .black.opacity(0.4),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Content Info
                VStack(alignment: .leading, spacing: 16) {
                    Text(featured.name)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let overview = featured.overview {
                        Text(overview)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .frame(maxWidth: 800, alignment: .leading)
                    }
                    
                    HStack(spacing: 24) {
                        if let year = featured.yearText {
                            Text(year)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        if let genre = featured.genreText {
                            Text(genre)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        if let runtime = featured.formattedRuntime {
                            Text(runtime)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    if isFocused {
                        Label("Play", systemImage: "play.fill")
                            .font(.title2)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(themeManager.currentTheme.accentColor)
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                            .padding(.top, 16)
                    }
                }
                .padding(48)
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: featured)
        }
    }
}

/// Continue watching section component
struct ContinueWatchingSection: View {
    let items: [MediaItem]
    @Binding var selectedItem: MediaItem?
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                Text("Continue Watching")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 32) {
                        ForEach(items) { item in
                            ContinueWatchingCard(item: item, isSelected: selectedItem == item)
                                .frame(width: 400)
                                .focusable()
                                #if os(tvOS)
                                .onPlayPauseCommand {
                                    selectedItem = item
                                }
                                #endif
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

/// Recently added section component
struct RecentlyAddedSection: View {
    let items: [MediaItem]
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                Text("Recently Added")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 32) {
                        ForEach(items) { item in
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
                            .buttonStyle(TVCardButtonStyle(isSelected: false))
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
                            .buttonStyle(TVCardButtonStyle(isSelected: false))
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
                        .buttonStyle(TVCardButtonStyle(isSelected: false))
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
                        .buttonStyle(TVCardButtonStyle(isSelected: false))
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

// MARK: - TV-Optimized Cards
struct TVContinueWatchingCard: View {
    let item: MediaItem
    let isSelected: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingPlayer = false
    
    private var progressPercentage: Double {
        PlaybackProgressUtility.calculateProgress(positionTicks: item.playbackPositionTicks, totalTicks: item.runTimeTicks) ?? 0
    }
    
    var body: some View {
        ZStack {
            // Background Image
            JellyfinImage(
                itemId: item.id,
                imageType: .backdrop,
                aspectRatio: 16/9,
                cornerRadius: 16,
                fallbackIcon: "play.circle.fill"
            )
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.8),
                        .black.opacity(0.4),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            
            // Content Overlay
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                
                // Title and Metadata
                VStack(alignment: .leading, spacing: 8) {
                    if item.type.lowercased() == "episode", let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Progress Bar
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(themeManager.currentTheme.accentColor)
                                .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                    
                    // Additional Info
                    HStack(spacing: 16) {
                        if let remainingTime = PlaybackProgressUtility.formatRemainingTime(
                            positionTicks: item.playbackPositionTicks,
                            totalTicks: item.runTimeTicks
                        ) {
                            Label(remainingTime, systemImage: "clock")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        if let episodeInfo = item.episodeInfo {
                            Text(episodeInfo)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .font(.callout)
                }
                .padding(24)
            }
            
            // Play Button Overlay when focused
            if isSelected {
                Button(action: { showingPlayer = true }) {
                    Label("Resume", systemImage: "play.fill")
                        .font(.title3)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accentColor)
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item, startTime: item.playbackPositionTicks.map { Double($0) / 10_000_000 })
        }
    }
}

struct TVRecentlyAddedCard: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Image
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 16,
                    fallbackIcon: item.type.lowercased() == "series" ? "tv" : "film"
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isFocused ? themeManager.currentTheme.accentColor : Color.clear,
                            lineWidth: 4
                        )
                )
                
                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if let year = item.yearText {
                            Text(year)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        if let genre = item.genreText {
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.7))
                            Text(genre)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .font(.callout)
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
        .fullScreenCover(isPresented: $showingDetail) {
            if item.type.lowercased() == "movie" {
                MovieDetailView(item: item)
            } else if item.type.lowercased() == "series" {
                SeriesDetailView(item: item)
            }
        }
    }
}

#Preview("TV Home") {
    TVHomeView()
        .environmentObject(ThemeManager())
}
#endif 