import SwiftUI

#if os(tvOS)
/// A tvOS-optimized tab view that provides a top-level navigation interface
struct TVTabView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                TVHomeView()
                    .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            // Movies Tab
            NavigationStack {
                TVMoviesView(libraries: libraryViewModel.movieLibraries)
                    .navigationTitle("Movies")
            }
            .tabItem {
                Label("Movies", systemImage: "film")
            }
            .tag(1)
            
            // TV Shows Tab
            NavigationStack {
                TVShowsView(libraries: libraryViewModel.tvShowLibraries)
                    .navigationTitle("TV Shows")
            }
            .tabItem {
                Label("TV Shows", systemImage: "tv")
            }
            .tag(2)
            
            // Music Tab
            NavigationStack {
                TVMusicView(libraries: libraryViewModel.musicLibraries)
                    .navigationTitle("Music")
            }
            .tabItem {
                Label("Music", systemImage: "music.note")
            }
            .tag(3)
            
            // Settings Tab
            NavigationStack {
                TVSettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .task {
            await libraryViewModel.loadLibraries()
        }
    }
}

#Preview("TV Tab View") {
    TVTabView()
        .environmentObject(ThemeManager())
        .environmentObject(LoginViewModel())
}
#endif 