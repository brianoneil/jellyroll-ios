import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                JellyfinTheme.backgroundColor(for: themeManager.currentMode).ignoresSafeArea()
                
                // Top Navigation Bar
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(themeManager.accentGradient)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Image(systemName: "airplayvideo")
                                .foregroundStyle(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .foregroundStyle(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                                .overlay(
                                    Circle()
                                        .fill(themeManager.accentGradient)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 6, y: -6),
                                        alignment: .topTrailing
                                )
                        }
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Circle()
                                .fill(themeManager.accentGradient)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(String(loginViewModel.user?.name.prefix(1).uppercased() ?? "?"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 52) // Height for navigation bar
                    
                    // Library Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            TabButton(title: "Home", isSelected: selectedTab == 0, themeManager: themeManager) {
                                selectedTab = 0
                            }
                            
                            if !libraryViewModel.movieLibraries.isEmpty {
                                TabButton(title: "Movies", isSelected: selectedTab == 1, themeManager: themeManager) {
                                    selectedTab = 1
                                }
                            }
                            
                            if !libraryViewModel.tvShowLibraries.isEmpty {
                                TabButton(title: "Series", isSelected: selectedTab == 2, themeManager: themeManager) {
                                    selectedTab = 2
                                }
                            }
                            
                            if !libraryViewModel.musicLibraries.isEmpty {
                                TabButton(title: "Music", isSelected: selectedTab == 3, themeManager: themeManager) {
                                    selectedTab = 3
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 2)
                    
                    // Content Area
                    ScrollView {
                        if libraryViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                        } else if let errorMessage = libraryViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            switch selectedTab {
                            case 0:
                                HomeTabView(libraries: libraryViewModel.libraries, libraryViewModel: libraryViewModel, themeManager: themeManager)
                                    .padding(.top, 16)
                            case 1:
                                MoviesTabView(libraries: libraryViewModel.movieLibraries, libraryViewModel: libraryViewModel, themeManager: themeManager)
                                    .padding(.top, 16)
                            case 2:
                                SeriesTabView(libraries: libraryViewModel.tvShowLibraries, libraryViewModel: libraryViewModel, themeManager: themeManager)
                                    .padding(.top, 16)
                            case 3:
                                MusicTabView(libraries: libraryViewModel.musicLibraries, libraryViewModel: libraryViewModel, themeManager: themeManager)
                                    .padding(.top, 16)
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(themeManager.currentMode == .dark ? .dark : .light)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await libraryViewModel.loadLibraries()
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? JellyfinTheme.Text.primary(for: themeManager.currentMode) : JellyfinTheme.Text.tertiary(for: themeManager.currentMode))
                
                if isSelected {
                    Rectangle()
                        .fill(themeManager.accentGradient)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
    }
}

struct HomeTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    let themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !libraryViewModel.continueWatching.isEmpty {
                    // Featured Continue Watching Section
                    TabView {
                        ForEach(libraryViewModel.continueWatching) { item in
                            ContinueWatchingCard(item: item, themeManager: themeManager)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets())
                }
                
                if !libraryViewModel.latestMedia.isEmpty {
                    // Latest Media Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Latest Additions")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(libraryViewModel.latestMedia) { item in
                                    LatestMediaItem(item: item, themeManager: themeManager)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top, 16)
        }
        .edgesIgnoringSafeArea([.leading, .trailing])
    }
}

struct MoviesTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    let themeManager: ThemeManager
    
    // Grid layout with 2 columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(libraries) { library in
                    if !libraryViewModel.getMovieItems(for: library.id).isEmpty {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(libraryViewModel.getMovieItems(for: library.id)) { item in
                                MovieCard(item: item, style: .grid, themeManager: themeManager)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct LatestMediaItem: View {
    let item: MediaItem
    let themeManager: ThemeManager
    
    var body: some View {
        if item.type.lowercased() == "movie" {
            MovieCard(item: item, style: .list, themeManager: themeManager)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    fallbackIcon: "film"
                )
                .frame(width: 160, height: 240)
                
                Text(item.name)
                    .fontWeight(.medium)
                    .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                    .lineLimit(1)
                
                if let year = item.yearText {
                    Text(year)
                        .font(.system(size: 12))
                        .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                }
            }
            .padding(8)
            .background(JellyfinTheme.cardGradient(for: themeManager.currentMode))
            .cornerRadius(12)
        }
    }
}

struct SeriesTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(libraries) { library in
                if !libraryViewModel.getTVShowItems(for: library.id).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(libraryViewModel.getTVShowItems(for: library.id)) { item in
                                SeriesItem(item: item, themeManager: themeManager)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

struct MusicTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(libraries) { library in
                if !libraryViewModel.getMusicItems(for: library.id).isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(library.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(libraryViewModel.getMusicItems(for: library.id)) { item in
                                    MusicItem(item: item, themeManager: themeManager)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

struct SeriesItem: View {
    let item: MediaItem
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            JellyfinImage(
                itemId: item.id,
                imageType: .primary,
                aspectRatio: 2/3,
                fallbackIcon: "tv"
            )
            .frame(width: 160, height: 240)
            
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                .lineLimit(1)
            
            HStack {
                if let year = item.yearText {
                    Text(year)
                }
                if let genre = item.genreText {
                    Text("•")
                    Text(genre)
                }
            }
            .font(.caption)
            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
        }
        .padding(8)
        .background(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
        .cornerRadius(12)
    }
}

struct MusicItem: View {
    let item: MediaItem
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            JellyfinImage(
                itemId: item.id,
                imageType: .primary,
                aspectRatio: 1,
                fallbackIcon: "music.note"
            )
            .frame(width: 160, height: 160)
            
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                .lineLimit(1)
            
            if let artist = item.artistText, let year = item.yearText {
                Text("\(artist) • \(year)")
                    .font(.caption)
                    .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
        .cornerRadius(12)
    }
} 