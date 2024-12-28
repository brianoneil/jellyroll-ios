import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Image(systemName: "play.circle.fill") // Replace with app logo
                        .font(.title)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Image(systemName: "airplayvideo")
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .overlay(
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 6, y: -6),
                                    alignment: .topTrailing
                                )
                        }
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Circle()
                                .fill(Color.accentColor)
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
                .padding(.bottom)
                
                // Library Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        TabButton(title: "Home", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        
                        if !libraryViewModel.movieLibraries.isEmpty {
                            TabButton(title: "Movies", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                        }
                        
                        if !libraryViewModel.tvShowLibraries.isEmpty {
                            TabButton(title: "Series", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                        }
                        
                        if !libraryViewModel.musicLibraries.isEmpty {
                            TabButton(title: "Music", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
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
                            HomeTabView(libraries: libraryViewModel.libraries, libraryViewModel: libraryViewModel)
                        case 1:
                            MoviesTabView(libraries: libraryViewModel.movieLibraries, libraryViewModel: libraryViewModel)
                        case 2:
                            SeriesTabView(libraries: libraryViewModel.tvShowLibraries, libraryViewModel: libraryViewModel)
                        case 3:
                            MusicTabView(libraries: libraryViewModel.musicLibraries, libraryViewModel: libraryViewModel)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            await libraryViewModel.loadLibraries()
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.primary : Color.clear)
                    .frame(height: 2)
            }
        }
    }
}

struct HomeTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            if !libraryViewModel.continueWatching.isEmpty {
                // Continue Watching Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Continue Watching")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(libraryViewModel.continueWatching) { item in
                                ContinueWatchingItem(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            
            if !libraryViewModel.latestMedia.isEmpty {
                // Latest Media Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Latest Additions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(libraryViewModel.latestMedia) { item in
                                LatestMediaItem(item: item)
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

struct MoviesTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(libraries) { library in
                if !libraryViewModel.getMovieItems(for: library.id).isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(library.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(libraryViewModel.getMovieItems(for: library.id)) { item in
                                    MovieItem(item: item)
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

struct SeriesTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(libraries) { library in
                if !libraryViewModel.getTVShowItems(for: library.id).isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(library.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(libraryViewModel.getTVShowItems(for: library.id)) { item in
                                    SeriesItem(item: item)
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

struct MusicTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(libraries) { library in
                if !libraryViewModel.getMusicItems(for: library.id).isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(library.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(libraryViewModel.getMusicItems(for: library.id)) { item in
                                    MusicItem(item: item)
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

struct ContinueWatchingItem: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 240, height: 135)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
            
            Text(item.name)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if let episodeInfo = item.episodeInfo, let remainingTime = item.remainingTime {
                Text("\(episodeInfo) • \(remainingTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let progress = item.playbackProgress {
                ProgressView(value: progress)
                    .tint(.accentColor)
            }
        }
        .frame(width: 240)
    }
}

struct LatestMediaItem: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 160, height: 240)
                .overlay(
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
            
            Text(item.name)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if let year = item.yearText {
                Text(year)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 160)
    }
}

struct MovieItem: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 160, height: 240)
                .overlay(
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
            
            Text(item.name)
                .fontWeight(.medium)
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
            .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}

struct SeriesItem: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 160, height: 240)
                .overlay(
                    Image(systemName: "tv")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
            
            Text(item.name)
                .fontWeight(.medium)
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
            .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}

struct MusicItem: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 160, height: 160)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
            
            Text(item.name)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if let artist = item.artistText, let year = item.yearText {
                Text("\(artist) • \(year)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 160)
    }
} 