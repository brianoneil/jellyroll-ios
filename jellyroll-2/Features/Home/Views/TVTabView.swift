import SwiftUI

/// A tvOS-optimized tab view that provides a top-level navigation interface
struct TVTabView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedTab = Tab.home
    
    enum Tab {
        case home
        case movies
        case tvShows
        case music
        case downloads
        case settings
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .movies: return "Movies"
            case .tvShows: return "TV Shows"
            case .music: return "Music"
            case .downloads: return "Downloads"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .movies: return "film.fill"
            case .tvShows: return "tv.fill"
            case .music: return "music.note"
            case .downloads: return "arrow.down.circle.fill"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TVHomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            if !libraryViewModel.movieLibraries.isEmpty {
                TVMoviesView(libraries: libraryViewModel.movieLibraries)
                    .tabItem {
                        Label(Tab.movies.title, systemImage: Tab.movies.icon)
                    }
                    .tag(Tab.movies)
            }
            
            if !libraryViewModel.tvShowLibraries.isEmpty {
                TVShowsView(libraries: libraryViewModel.tvShowLibraries)
                    .tabItem {
                        Label(Tab.tvShows.title, systemImage: Tab.tvShows.icon)
                    }
                    .tag(Tab.tvShows)
            }
            
            if !libraryViewModel.musicLibraries.isEmpty {
                TVMusicView(libraries: libraryViewModel.musicLibraries)
                    .tabItem {
                        Label(Tab.music.title, systemImage: Tab.music.icon)
                    }
                    .tag(Tab.music)
            }
            
            DownloadsManagementView()
                .tabItem {
                    Label(Tab.downloads.title, systemImage: Tab.downloads.icon)
                }
                .tag(Tab.downloads)
            
            TVSettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .task {
            await libraryViewModel.loadLibraries()
        }
    }
}

#Preview {
    TVTabView()
        .environmentObject(LoginViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(LayoutManager())
} 