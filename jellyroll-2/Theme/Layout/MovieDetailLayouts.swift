import SwiftUI

/// Orientation-specific layouts for movie detail view
struct MovieDetailLayouts {
    /// Portrait layout for movie details
    struct PortraitLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var playbackService = PlaybackService.shared
        @State private var isDownloading = false
        @State private var downloadError: String?
        
        var body: some View {
            ZStack {
                // Background Image Layer
                LayoutComponents.BackdropImage(itemId: item.id)
                    .edgesIgnoringSafeArea(.all)
                
                // Optional overlay gradient to ensure content visibility
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
                ZStack(alignment: .bottom) {
                    // Top Navigation and Actions
                    VStack {
                        HStack(alignment: .top) {
                            // Back Button
                            Button(action: dismiss) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .padding(12)
                                    .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
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
                                    case .failed:
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
                                            Image(systemName: "exclamationmark.circle")
                                                .font(.system(size: 24))
                                                .foregroundColor(themeManager.currentTheme.iconColor)
                                        }
                                        .disabled(isDownloading)
                                    case .notDownloaded:
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
                                } else {
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
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .frame(width: 50)
                            .background(.ultraThinMaterial)
                            .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                    .safeAreaInset(edge: .top) { Color.clear.frame(height: 8) }
                    
                    // Content Card with blur effect
                    VStack(spacing: 0) {
                        // Content
                        VStack(alignment: .leading, spacing: 20) {
                            // Title
                            Text(item.name)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            
                            // Progress Bar (if movie is partially watched)
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
                            
                            // Rating and Info Row
                            HStack(spacing: 8) {
                                if let rating = item.communityRating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(themeManager.currentTheme.accentColor)
                                        Text(String(format: "%.1f", rating))
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                }
                                
                                if let year = item.yearText {
                                    if item.communityRating != nil {
                                        Text("•")
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.6))
                                    }
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
                            
                            // Genres
                            if !item.genres.isEmpty {
                                Text(item.genres.prefix(3).joined(separator: ", "))
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            
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
                                Button(action: { showingPlayer.wrappedValue = true }) {
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
                .edgesIgnoringSafeArea(.all)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
        }
    }
    
    /// Landscape layout for movie details
    struct LandscapeLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var playbackService = PlaybackService.shared
        @State private var isDownloading = false
        @State private var downloadError: String?
        
        var body: some View {
            HStack(spacing: 0) {
                // Left column with poster and buttons
                VStack(spacing: 24) {
                    LayoutComponents.MediaPoster(
                        itemId: item.id,
                        progress: hasProgress ? progressPercentage : nil,
                        width: 200
                    )
                    
                    // Play Button
                    Button(action: { showingPlayer.wrappedValue = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text(hasProgress ? "Resume" : "Play")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Download Button
                    if let downloadState = playbackService.getDownloadState(for: item.id) {
                        switch downloadState.status {
                        case .downloading:
                            Button(action: {
                                playbackService.cancelDownload(itemId: item.id)
                            }) {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Cancel Download")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            
                        case .downloaded:
                            Button(action: {
                                Task {
                                    try? playbackService.deleteDownload(itemId: item.id)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Delete Download")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            
                        case .failed:
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
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle")
                                    Text("Retry Download")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(isDownloading)
                            
                        case .notDownloaded:
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
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle")
                                    Text("Download")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.currentTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(isDownloading)
                        }
                    } else {
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
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle")
                                Text("Download")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isDownloading)
                    }
                    
                    if let error = downloadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
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
                            onBackTapped: dismiss
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
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                    Text("My List")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Trailer Button
                                VStack(spacing: 8) {
                                    Image(systemName: "film")
                                        .font(.system(size: 24))
                                    Text("Trailer")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Share Button
                                VStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 24))
                                    Text("Share")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Download Button/Status
                                if let downloadState = playbackService.getDownloadState(for: item.id) {
                                    switch downloadState.status {
                                    case .downloading:
                                        VStack(spacing: 8) {
                                            Button(action: {
                                                playbackService.cancelDownload(itemId: item.id)
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                        .frame(width: 28, height: 28)
                                                    
                                                    Circle()
                                                        .trim(from: 0, to: downloadState.progress)
                                                        .stroke(themeManager.currentTheme.accentColor, lineWidth: 2)
                                                        .frame(width: 28, height: 28)
                                                        .rotationEffect(.degrees(-90))
                                                    
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                                }
                                            }
                                            Text("Cancel")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        
                                    case .downloaded:
                                        VStack(spacing: 8) {
                                            Button(action: {
                                                Task {
                                                    try? playbackService.deleteDownload(itemId: item.id)
                                                }
                                            }) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                                            }
                                            Text("Downloaded")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                        
                                    case .failed:
                                        VStack(spacing: 8) {
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
                                                Image(systemName: "exclamationmark.circle")
                                                    .font(.system(size: 24))
                                            }
                                            Text("Try Again")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(.orange)
                                        .disabled(isDownloading)
                                        
                                    case .notDownloaded:
                                        VStack(spacing: 8) {
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
                                            }
                                            Text("Download")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .disabled(isDownloading)
                                    }
                                } else {
                                    VStack(spacing: 8) {
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
                                        }
                                        Text("Download")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    .disabled(isDownloading)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Featured Tagline
                            if item.taglines.count == 1, let tagline = item.taglines.first {
                                Text(tagline)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Overview
                            if let overview = item.overview {
                                Text(overview)
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .lineSpacing(4)
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
            .fullScreenCover(isPresented: showingPlayer) {
                VideoPlayerView(item: item, startTime: item.userData.playbackPositionTicks.map { Double($0) / 10_000_000 })
            }
        }
    }
} 