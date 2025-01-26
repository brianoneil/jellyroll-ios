import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var showingSettings = false
    @State private var selectedItemIndex = 0
    @State private var selectedTab = 0
    @State private var dragOffset: CGFloat = 0
    
    private var tabs: [TabComponents.TabItem] {
        var items = [
            TabComponents.TabItem(title: "Home", icon: "jamm-logo")
        ]
        
        if !libraryViewModel.movieLibraries.isEmpty {
            items.append(TabComponents.TabItem(title: "Movies", icon: "film"))
        }
        
        if !libraryViewModel.tvShowLibraries.isEmpty {
            items.append(TabComponents.TabItem(title: "Series", icon: "tv"))
        }
        
        if !libraryViewModel.musicLibraries.isEmpty {
            items.append(TabComponents.TabItem(title: "Music", icon: "music.note"))
        }
        
        return items
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    // Dynamic Background
                    if selectedTab == 0 && !libraryViewModel.continueWatching.isEmpty {
                        themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                        
                        JellyfinImage(
                            itemId: libraryViewModel.continueWatching[selectedItemIndex].id,
                            imageType: .backdrop,
                            aspectRatio: 16/9,
                            cornerRadius: 0,
                            fallbackIcon: "play.circle.fill"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(2.0, anchor: .center)
                        .blur(radius: 30)
                        .opacity(0.7)
                        .ignoresSafeArea()
                        
                        // Theme-based overlay for better contrast
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.backgroundColor.opacity(0.9),
                                themeManager.currentTheme.backgroundColor.opacity(0.5),
                                themeManager.currentTheme.backgroundColor.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                    
                    // Theme background for other tabs
                    themeManager.currentTheme.backgroundColor
                        .opacity(selectedTab == 0 ? 0 : 1)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Top Navigation Bar
                        topNavigationBar
                        
                        if layoutManager.isPad && layoutManager.isLandscape {
                            // iPad landscape layout with side tabs
                            HStack(spacing: 0) {
                                TabComponents.AdaptiveTabBar(tabs: tabs, selectedTab: $selectedTab)
                                mainContent
                            }
                        } else {
                            // Default layout with top tabs
                            TabComponents.AdaptiveTabBar(tabs: tabs, selectedTab: $selectedTab)
                            mainContent
                        }
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                .task {
                    await libraryViewModel.loadLibraries()
                }
            }
        }
    }
    
    private var mainContent: some View {
        Group {
            switch selectedTab {
            case 0:
                // Home Tab with new Continue Watching design
                if libraryViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(themeManager.currentTheme.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = libraryViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .padding()
                } else if libraryViewModel.continueWatching.isEmpty || themeManager.debugEmptyContinueWatching {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 16) {
                                Image("jamm-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 72)
                                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                                Text("Time to start your next adventure!")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Text("Your watch history will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            
                            // Recently Added Section
                            if !libraryViewModel.latestMedia.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recently Added")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(libraryViewModel.latestMedia) { item in
                                                RecentlyAddedCard(item: item)
                                                    .frame(width: 160)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Continue Watching Carousel
                            GeometryReader { geometry in
                                let itemWidth = min(geometry.size.width * 0.7, 300)
                                let spacing: CGFloat = 8  // Reduced spacing between cards
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: spacing) {
                                        ForEach(Array(libraryViewModel.continueWatching.enumerated()), id: \.element.id) { index, item in
                                            ContinueWatchingCard(item: item, isSelected: index == selectedItemIndex)
                                                .frame(width: itemWidth)
                                                .onTapGesture {
                                                    withAnimation {
                                                        selectedItemIndex = index
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal, (geometry.size.width - itemWidth) / 2)
                                }
                                .content.offset(x: -CGFloat(selectedItemIndex) * (itemWidth + spacing) + dragOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation.width
                                        }
                                        .onEnded { value in
                                            let predictedEndOffset = value.predictedEndTranslation.width
                                            let swipeThreshold: CGFloat = itemWidth / 3
                                            
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                dragOffset = 0
                                                if predictedEndOffset > swipeThreshold && selectedItemIndex > 0 {
                                                    selectedItemIndex -= 1
                                                } else if predictedEndOffset < -swipeThreshold && selectedItemIndex < libraryViewModel.continueWatching.count - 1 {
                                                    selectedItemIndex += 1
                                                }
                                            }
                                        }
                                )
                                .scrollDisabled(true)
                                .frame(height: 500)
                            }
                            .frame(height: 500)
                            .padding(.top, 24)
                            
                            // Recently Added Section
                            if !libraryViewModel.latestMedia.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recently Added")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(libraryViewModel.latestMedia) { item in
                                                RecentlyAddedCard(item: item)
                                                    .frame(width: 160)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
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
    
    private var topNavigationBar: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "airplayvideo")
                        .foregroundStyle(themeManager.currentTheme.primaryTextColor)
                }
                
                Button(action: { showingSettings.toggle() }) {
                    Circle()
                        .fill(themeManager.currentTheme.accentGradient)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(loginViewModel.user?.name.prefix(1).uppercased() ?? "?"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// Movies Tab View
struct MoviesTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject private var layoutManager: LayoutManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var columns: [GridItem] {
        let columnCount = layoutManager.isLandscape ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(libraries) { library in
                    if !libraryViewModel.getMovieItems(for: library.id).isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            if libraries.count > 1 {
                                Text(library.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .padding(.horizontal)
                            }
                            
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(libraryViewModel.getMovieItems(for: library.id)) { item in
                                    MovieCard(item: item, style: .grid)
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
}

// Series Tab View
struct SeriesTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(libraries) { library in
                    if !libraryViewModel.getTVShowItems(for: library.id).isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            if libraries.count > 1 {
                                Text(library.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .padding(.horizontal)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(libraryViewModel.getTVShowItems(for: library.id)) { item in
                                        MovieCard(item: item, style: .grid)
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
}

// Music Tab View
struct MusicTabView: View {
    let libraries: [LibraryItem]
    @ObservedObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(libraries) { library in
                    if !libraryViewModel.getMusicItems(for: library.id).isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(library.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(libraryViewModel.getMusicItems(for: library.id)) { item in
                                        MovieCard(item: item, style: .grid)
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
} 