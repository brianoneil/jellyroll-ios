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
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    LayoutComponents.HeroSection(
                        imageId: item.id,
                        onBackTapped: dismiss
                    )
                    
                    // Content
                    VStack(spacing: 24) {
                        // Poster and Metadata Section
                        HStack(spacing: 16) {
                            // Poster
                            LayoutComponents.MediaPoster(
                                itemId: item.id,
                                progress: hasProgress ? progressPercentage : nil
                            )
                            .frame(height: 180)
                            
                            // Metadata
                            LayoutComponents.MediaMetadata(
                                title: item.name,
                                year: item.yearText,
                                runtime: item.formattedRuntime,
                                rating: item.officialRating,
                                genres: item.genres
                            )
                        }
                        .padding(.horizontal, 24)
                        .offset(y: -90)
                        .padding(.bottom, -90)
                        
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
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 24)
                        }
                        
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
                        .padding(.horizontal, 24)
                        
                        if let error = downloadError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
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
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: showingPlayer) {
                VideoPlayerView(item: item, startTime: item.userData.playbackPositionTicks.map { Double($0) / 10_000_000 })
            }
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