import SwiftUI

struct DownloadsView: View {
    @StateObject private var playbackService = PlaybackService.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingPlayer = false
    @State private var selectedItem: MediaItem?
    
    private var downloadedItems: [(String, PlaybackService.DownloadState)] {
        playbackService.activeDownloads
            .filter { _, state in
                if case .downloaded = state.status {
                    return true
                }
                return false
            }
            .map { ($0, $1) }
    }
    
    private func createOfflineMediaItem(id: String) -> MediaItem {
        // Create a minimal MediaItem for offline playback
        return MediaItem(
            from: [
                "Id": id,
                "Name": "Downloaded Movie",
                "Type": "Movie",
                "Genres": [],
                "Tags": [],
                "ImageBlurHashes": [:],
                "BackdropImageTags": [],
                "ImageTags": [:],
                "UserData": [
                    "PlaybackPositionTicks": 0,
                    "PlayCount": 0,
                    "IsFavorite": false,
                    "Played": false,
                    "Key": ""
                ]
            ]
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(downloadedItems, id: \.0) { itemId, downloadState in
                        HStack {
                            // Movie thumbnail
                            JellyfinImage(
                                itemId: itemId,
                                imageType: .primary,
                                aspectRatio: 2/3,
                                cornerRadius: 8,
                                fallbackIcon: "film"
                            )
                            .frame(width: 80, height: 120)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Movie Title") // Replace with actual movie title
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                HStack {
                                    Button(action: {
                                        // Play downloaded movie
                                        if let url = downloadState.localURL {
                                            selectedItem = createOfflineMediaItem(id: itemId)
                                            showingPlayer = true
                                        }
                                    }) {
                                        Label("Play", systemImage: "play.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: {
                                        try? playbackService.deleteDownload(itemId: itemId)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .padding()
                        .background(themeManager.currentTheme.cardGradient)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Downloads")
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            if let item = selectedItem {
                VideoPlayerView(item: item)
            }
        }
    }
} 