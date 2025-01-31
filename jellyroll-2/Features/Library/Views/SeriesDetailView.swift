import SwiftUI
import UIKit

// MARK: - Tab Protocol
protocol SeriesDetailTabView: View {
    var item: MediaItem { get }
}

// MARK: - Tab Enum
enum SeriesDetailTab: Int, CaseIterable {
    case overview
    case episodes
    case castCrew
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .episodes: return "list.bullet.rectangle"
        case .castCrew: return "person.2"
        }
    }
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .episodes: return "Episodes"
        case .castCrew: return "Cast & Crew"
        }
    }
}

struct SeriesDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @State private var showingPlayer = false
    @StateObject private var playbackService = PlaybackService.shared
    @State private var isDownloading = false
    @State private var downloadError: String?
    @State private var selectedTab: SeriesDetailTab = .overview
    
    private var hasProgress: Bool {
        item.userData.playbackPositionTicks ?? 0 > 0
    }
    
    private var progressPercentage: Double {
        return PlaybackProgressUtility.calculateProgress(positionTicks: item.userData.playbackPositionTicks, totalTicks: item.runTimeTicks) ?? 0
    }
    
    private var progressText: String {
        return PlaybackProgressUtility.formatRemainingTime(
            positionTicks: item.userData.playbackPositionTicks,
            totalTicks: item.runTimeTicks
        ) ?? ""
    }
    
    var body: some View {
        Group {
            if layoutManager.isLandscape {
                SeriesDetailLayouts.LandscapeLayout(
                    item: item,
                    selectedTab: $selectedTab,
                    hasProgress: hasProgress,
                    progressPercentage: progressPercentage,
                    progressText: progressText,
                    showingPlayer: $showingPlayer,
                    dismiss: { dismiss() }
                )
            } else {
                SeriesDetailLayouts.PortraitLayout(
                    item: item,
                    selectedTab: $selectedTab,
                    hasProgress: hasProgress,
                    progressPercentage: progressPercentage,
                    progressText: progressText,
                    showingPlayer: $showingPlayer,
                    dismiss: { dismiss() }
                )
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item, startTime: item.userData.playbackPositionTicks.map { PlaybackProgressUtility.ticksToSeconds($0) })
        }
    }
}

// MARK: - Layout Namespace
enum SeriesDetailLayouts {
    struct PortraitLayout: View {
        let item: MediaItem
        @Binding var selectedTab: SeriesDetailTab
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        @Binding var showingPlayer: Bool
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var playbackService = PlaybackService.shared
        @State private var isDownloading = false
        @State private var downloadError: String?
        
        var body: some View {
            ZStack {
                // Background Image Layer
                LayoutComponents.BackdropImage(
                    itemId: item.id,
                    blurHash: item.imageBlurHashes["Primary"]?.values.first
                )
                .edgesIgnoringSafeArea(.all)
                
                // Optional overlay gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        themeManager.currentTheme.backgroundColor.opacity(0.2),
                        themeManager.currentTheme.backgroundColor.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content Layer
                ZStack(alignment: .trailing) {
                    Color.clear // Add a clear background to ensure transparency
                    
                    VerticalPageViewController(
                        pages: [
                            AnyView(
                                OverviewTab(
                                    item: item,
                                    hasProgress: hasProgress,
                                    progressPercentage: progressPercentage,
                                    progressText: progressText,
                                    showingPlayer: $showingPlayer
                                )
                            ),
                            AnyView(EpisodesTab(item: item)),
                            AnyView(CastCrewTab(item: item))
                        ],
                        currentPage: Binding(
                            get: { selectedTab.rawValue },
                            set: { selectedTab = SeriesDetailTab(rawValue: $0) ?? .overview }
                        )
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    // Tab Indicators
                    VStack(spacing: 24) {
                        ForEach(SeriesDetailTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedTab == tab ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 4)
                    .background(.ultraThinMaterial)
                    .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.trailing, 16)
                    .padding(.vertical, 32)
                    
                    // Back Button (Top Left)
                    VStack {
                        HStack {
                            Button(action: dismiss) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .padding(12)
                                    .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 36)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
            .background(Color.clear)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
        }
    }
    
    struct LandscapeLayout: View {
        let item: MediaItem
        @Binding var selectedTab: SeriesDetailTab
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        @Binding var showingPlayer: Bool
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var playbackService = PlaybackService.shared
        @State private var isDownloading = false
        @State private var downloadError: String?
        
        var body: some View {
            HStack(spacing: 0) {
                // Left column with poster and actions
                VStack(alignment: .leading, spacing: 24) {
                    // Poster
                    JellyfinImage(
                        itemId: item.id,
                        imageType: .primary,
                        aspectRatio: 2/3,
                        cornerRadius: 12,
                        fallbackIcon: "tv"
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Play Button
                        Button(action: { showingPlayer = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(hasProgress ? "Continue Watching" : "Play")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.currentTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Trailer Button
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "play.rectangle")
                                Text("Trailer")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.surfaceColor.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(24)
                .frame(width: 248)
                
                // Right column with scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        LayoutComponents.HeroSection(
                            imageId: item.id,
                            onBackTapped: dismiss,
                            blurHash: item.imageBlurHashes["Primary"]?.values.first
                        )
                        
                        VStack(spacing: 24) {
                            // Metadata
                            LayoutComponents.MediaMetadata(
                                title: item.name,
                                year: item.yearText,
                                runtime: item.formattedRuntime,
                                rating: item.officialRating,
                                genres: item.genres
                            )
                            .padding(.horizontal, 24)
                            
                            // Action Buttons Row
                            HStack(spacing: 32) {
                                // My List Button
                                VStack(spacing: 8) {
                                    Button(action: {}) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                    Text("My List")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Like Button
                                VStack(spacing: 8) {
                                    Button(action: {}) {
                                        Image(systemName: "heart")
                                            .font(.system(size: 24))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                    Text("Like")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            }
                            .padding(.horizontal, 24)
                    
                    // Overview
                    if let overview = item.overview {
                            Text(overview)
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .lineSpacing(4)
                                    .lineLimit(3)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 24)
            }
        }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .all)
        .navigationBarHidden(true)
        }
    }
}

// MARK: - Tab Views
struct OverviewTab: View, SeriesDetailTabView {
    let item: MediaItem
    let hasProgress: Bool
    let progressPercentage: Double
    let progressText: String
    @Binding var showingPlayer: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Spacer()
            
            // Content Card with blur effect
            VStack(spacing: 0) {
                // Content
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text(item.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    // Progress Bar (if series is partially watched)
                    if hasProgress {
                        VStack(spacing: 4) {
                            GeometryReader { metrics in
                                ZStack(alignment: .leading) {
                                    // Background bar
                                    Rectangle()
                                        .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
                                        .frame(height: 3)
                                    
                                    // Progress bar
                                    Rectangle()
                                        .fill(themeManager.currentTheme.accentGradient)
                                        .frame(width: max(0, min(metrics.size.width * progressPercentage, metrics.size.width)), height: 3)
                                }
                            }
                            .frame(height: 3)
                            
                            Text(progressText)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Quick Info Row
                    HStack(spacing: 12) {
                        if let year = item.yearText {
                            Text(year)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        if let runtime = item.formattedRuntime {
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
                            Text(runtime)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        if let officialRating = item.officialRating {
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
                            Text(officialRating)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .font(.system(size: 15))
                    
                    // Overview
                    if let overview = item.overview {
                        Text(overview)
                            .font(.system(size: 15))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .lineSpacing(4)
                            .lineLimit(3)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Watch Now Button
                        Button(action: { showingPlayer = true }) {
                            Text(hasProgress ? "Resume" : "Watch now")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themeManager.currentTheme.accentGradient)
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                .cornerRadius(8)
                        }
                        
                        // Trailer Button
                        Button(action: {}) {
                            Text("Trailer")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themeManager.currentTheme.surfaceColor.opacity(0.2))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
            }
            .background(.ultraThinMaterial)
            .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

struct CastCrewTab: View, SeriesDetailTabView {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Cast & Crew")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    // Placeholder for cast & crew list
                    Text("Cast & Crew information coming soon")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding(24)
            }
            .background(.ultraThinMaterial)
            .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

struct EpisodesTab: View, SeriesDetailTabView {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel: SeriesDetailViewModel
    
    init(item: MediaItem) {
        self.item = item
        _viewModel = StateObject(wrappedValue: SeriesDetailViewModel(item: item))
    }
    
    var body: some View {
        VStack {
            // Empty space at top to show background image
            Spacer()
                .frame(height: 160)
            
            // Content section with background
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    // Seasons Horizontal Scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.seasons) { season in
                                SeasonCard(
                                    season: season,
                                    isSelected: season.id == viewModel.selectedSeason?.id
                                )
                                .onTapGesture {
                                    viewModel.selectSeason(season)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 160)
                    .padding(.top, 24)
                    
                    // Episodes List
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    } else if let error = viewModel.error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.episodes) { episode in
                                    EpisodeRow(episode: episode)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(.ultraThinMaterial)
            .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.trailing, 60) // Add extra padding on the right for page controls
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
        .onAppear {
            viewModel.loadSeasons(for: item.id)
        }
    }
}

struct SeasonCard: View {
    let season: MediaItem
    let isSelected: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            JellyfinImage(
                itemId: season.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 8,
                fallbackIcon: "tv"
            )
            .frame(width: 90, height: 135)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 2)
            )
            
            Text(season.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .lineLimit(1)
        }
    }
}

struct EpisodeRow: View {
    let episode: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Episode Thumbnail
            JellyfinImage(
                itemId: episode.id,
                imageType: .primary,
                aspectRatio: 16/9,
                cornerRadius: 8,
                fallbackIcon: "tv"
            )
            .frame(width: 140, height: 80)
            
            // Episode Info
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                if let overview = episode.overview {
                    Text(overview)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                }
                
                if let runtime = episode.formattedRuntime {
                    Text(runtime)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(themeManager.currentTheme.surfaceColor.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - UIPageViewController wrapper
struct VerticalPageViewController: UIViewControllerRepresentable {
    var pages: [AnyView]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        // Make everything transparent
        pageViewController.view.backgroundColor = .clear
        if let scrollView = pageViewController.view.subviews.first as? UIScrollView {
            scrollView.backgroundColor = .clear
            // Make all scroll view subviews transparent
            scrollView.subviews.forEach { $0.backgroundColor = .clear }
        }
        
        // Set up the initial view controller
        let initialVC = context.coordinator.controllers[currentPage]
        initialVC.view.backgroundColor = .clear
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
        
        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = context.coordinator.controllers.firstIndex(of: currentViewController) {
            if currentIndex != currentPage {
                let direction: UIPageViewController.NavigationDirection = currentIndex < currentPage ? .forward : .reverse
                let nextViewController = context.coordinator.controllers[currentPage]
                nextViewController.view.backgroundColor = .clear
                pageViewController.setViewControllers([nextViewController], direction: direction, animated: true)
            }
        } else {
            let initialVC = context.coordinator.controllers[currentPage]
            initialVC.view.backgroundColor = .clear
            pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: VerticalPageViewController
        var controllers: [UIViewController]

        init(_ pageViewController: VerticalPageViewController) {
            parent = pageViewController
            controllers = parent.pages.map { 
                let hostingController = UIHostingController(rootView: $0)
                hostingController.view.backgroundColor = .clear
                return hostingController
            }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index == 0 { return nil }
            return controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index + 1 == controllers.count { return nil }
            return controllers[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
            }
        }
    }
} 