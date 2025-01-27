import SwiftUI

struct SeriesDetailView: View {
    let item: MediaItem
    @StateObject private var viewModel: SeriesDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showingPlayer = false
    @State private var selectedEpisode: MediaItem?
    
    init(item: MediaItem) {
        self.item = item
        _viewModel = StateObject(wrappedValue: SeriesDetailViewModel(item: item))
    }
    
    private var pageIndicator: some View {
        VStack(spacing: 8) {
            ForEach(0..<2) { index in
                Circle()
                    .fill(currentPage == index ? 
                          AnyShapeStyle(themeManager.currentTheme.accentGradient) :
                          AnyShapeStyle(themeManager.currentTheme.surfaceColor))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Image Layer
                JellyfinImage(
                    itemId: item.id,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 0,
                    fallbackIcon: "tv",
                    blurHash: item.imageBlurHashes["Primary"]?.values.first
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                .clipped()
                .offset(y: -geometry.safeAreaInsets.top)
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            themeManager.currentTheme.backgroundColor.opacity(0.2),
                            themeManager.currentTheme.backgroundColor.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

                // Content
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                }
                        }
                        Spacer()
                    }
                    .padding()
                    .zIndex(1)
                    
                    // Pages Container
                    let pageHeight = max(0, geometry.size.height - 80) // Account for header and ensure positive
                    
                    ZStack {
                        // Series Info Page
                        SeriesInfoPage(item: item)
                            .frame(maxWidth: .infinity, maxHeight: pageHeight)
                            .offset(y: currentPage == 0 ? min(dragOffset, pageHeight) : -pageHeight)
                        
                        // Seasons Page
                        SeasonsPage(
                            viewModel: viewModel,
                            selectedEpisode: $selectedEpisode,
                            showingPlayer: $showingPlayer
                        )
                        .frame(maxWidth: .infinity, maxHeight: pageHeight)
                        .offset(y: currentPage == 1 ? max(-pageHeight, dragOffset) : pageHeight)
                    }
                    .clipped()
                }
                
                // Page Indicator
                VStack {
                    Spacer()
                        .frame(height: 120) // Position it in the middle
                    pageIndicator
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let predictedEndOffset = value.predictedEndTranslation.height
                        let swipeThreshold: CGFloat = geometry.size.height / 4
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                            if predictedEndOffset > swipeThreshold && currentPage > 0 {
                                currentPage -= 1
                            } else if predictedEndOffset < -swipeThreshold && currentPage < 1 {
                                currentPage += 1
                            }
                        }
                    }
            )
        }
        .task {
            await viewModel.loadSeasons()
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            if let episode = selectedEpisode {
                VideoPlayerView(item: episode, startTime: episode.userData.playbackPositionTicks.map { PlaybackProgressUtility.ticksToSeconds($0) })
            }
        }
    }
}

// MARK: - Series Info Page
private struct SeriesInfoPage: View {
    let item: MediaItem
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var layoutManager: LayoutManager
    @StateObject private var playbackService = PlaybackService.shared
    @State private var isDownloading = false
    @State private var downloadError: String?
    
    var body: some View {
        // Content Layer
        VStack(spacing: 0) {
            // Top Navigation and Actions
            HStack(alignment: .top, spacing: 16) {
                Spacer()
                
                // Right-side vertical controls
                VStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.currentTheme.iconColor)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "heart")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.currentTheme.iconColor)
                    }
                    
                    // Download Button/Status
                    if let downloadState = playbackService.getDownloadState(for: item.id) {
                        switch downloadState.status {
                        case .downloading:
                            Button(action: {
                                playbackService.cancelDownload(itemId: item.id)
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(themeManager.currentTheme.surfaceColor.opacity(0.3), lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                    
                                    Circle()
                                        .trim(from: 0, to: downloadState.progress)
                                        .stroke(themeManager.currentTheme.accentGradient, lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.currentTheme.iconColor)
                                }
                            }
                        case .downloaded:
                            Button(action: {
                                Task {
                                    try? playbackService.deleteDownload(itemId: item.id)
                                }
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                            }
                        case .failed, .notDownloaded:
                            Button(action: {
                                Task {
                                    isDownloading = true
                                    do {
                                        _ = try await playbackService.downloadMovie(item: item)
                                    } catch {
                                        downloadError = error.localizedDescription
                                    }
                                    isDownloading = false
                                }
                            }) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeManager.currentTheme.iconColor)
                            }
                            .disabled(isDownloading)
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .frame(width: 50)
                .background(.ultraThinMaterial)
                .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, layoutManager.isLandscape ? 16 : 8)
            
            Spacer()
            
            // Bottom Content Card
            VStack(spacing: 24) {
                // Title and Metadata
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    // Info Row
                    HStack(spacing: 12) {
                        if let year = item.yearText {
                            Text(year)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        if let rating = item.officialRating {
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
                            Text(rating)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .font(.system(size: 15))
                    
                    // Genres
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
                
                // Overview
                if let overview = item.overview {
                    Text(overview)
                        .font(.system(size: 15))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineSpacing(4)
                }
                
                // Swipe indicator
                VStack(spacing: 4) {
                    Text("Swipe up for seasons")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(themeManager.currentTheme.accentGradient)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Seasons Page
private struct SeasonsPage: View {
    @ObservedObject var viewModel: SeriesDetailViewModel
    @Binding var selectedEpisode: MediaItem?
    @Binding var showingPlayer: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var expandedSeasonId: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Swipe indicator
            VStack(spacing: 4) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                Text("Swipe down for details")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .padding(.vertical, 8)
            
            // Seasons List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(viewModel.seasons) { season in
                        SeasonCard(
                            season: season,
                            episodes: viewModel.episodes[season.id] ?? [],
                            isExpanded: expandedSeasonId == season.id,
                            selectedEpisode: $selectedEpisode,
                            showingPlayer: $showingPlayer
                        ) { isExpanded in
                            if isExpanded {
                                expandedSeasonId = season.id
                                Task {
                                    await viewModel.loadEpisodes(for: season.id)
                                }
                            } else {
                                expandedSeasonId = nil
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Season Card
private struct SeasonCard: View {
    let season: MediaItem
    let episodes: [MediaItem]
    let isExpanded: Bool
    @Binding var selectedEpisode: MediaItem?
    @Binding var showingPlayer: Bool
    let onExpandToggle: (Bool) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Season Header
            Button(action: { onExpandToggle(!isExpanded) }) {
                HStack {
                    JellyfinImage(
                        itemId: season.id,
                        imageType: .primary,
                        aspectRatio: 16/9,
                        cornerRadius: 8,
                        fallbackIcon: "tv"
                    )
                    .frame(width: 80, height: 45)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(season.name)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        Text("\(episodes.count) Episodes")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding()
                .background(themeManager.currentTheme.surfaceColor)
                .cornerRadius(12)
            }
            
            // Episodes List
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(episodes) { episode in
                        Button(action: {
                            selectedEpisode = episode
                            showingPlayer = true
                        }) {
                            HStack(spacing: 12) {
                                // Episode Thumbnail
                                JellyfinImage(
                                    itemId: episode.id,
                                    imageType: .primary,
                                    aspectRatio: 16/9,
                                    cornerRadius: 6,
                                    fallbackIcon: "play.tv"
                                )
                                .frame(width: 120, height: 67.5)
                                
                                // Episode Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(episode.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .lineLimit(2)
                                    
                                    if let episodeInfo = episode.episodeInfo {
                                        Text(episodeInfo)
                                            .font(.system(size: 13))
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                    
                                    if let runtime = episode.formattedRuntime {
                                        Text(runtime)
                                            .font(.system(size: 13))
                                            .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                                    }
                                }
                                
                                Spacer()
                                
                                // Play Button
                                Circle()
                                    .fill(themeManager.currentTheme.accentGradient)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(themeManager.currentTheme.surfaceColor.opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
} 