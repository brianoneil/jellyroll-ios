import SwiftUI

// Create a dedicated type for downloaded items
private struct DownloadedItem: Identifiable {
    let id: String
    let state: PlaybackService.DownloadState
    let offlineItem: OfflineMediaItem?
}

// Separate view for the download item card
private struct DownloadItemCard: View {
    let item: DownloadedItem
    let onPlay: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            // Movie thumbnail
            JellyfinImage(
                itemId: item.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 8,
                fallbackIcon: "film"
            )
            .frame(width: 80, height: 120)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.offlineItem?.name ?? "Downloaded Movie")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                if let overview = item.offlineItem?.overview {
                    Text(overview)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                }
                
                HStack {
                    Button(action: onPlay) {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onDelete) {
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

struct DownloadsView: View {
    @StateObject private var playbackService = PlaybackService.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingPlayer = false
    @State private var selectedItem: MediaItem?
    
    private var downloadedItems: [DownloadedItem] {
        playbackService.activeDownloads.compactMap { id, state in
            guard case .downloaded = state.status else { return nil }
            return DownloadedItem(
                id: id,
                state: state,
                offlineItem: playbackService.getOfflineItem(id: id)
            )
        }
    }
    
    private func playItem(_ item: DownloadedItem) {
        guard let offlineItem = item.offlineItem else { return }
        
        selectedItem = MediaItem(
            from: [
                "Id": offlineItem.id,
                "Name": offlineItem.name,
                "Type": offlineItem.type,
                "Overview": offlineItem.overview as Any,
                "Genres": offlineItem.genres,
                "Tags": offlineItem.taglines,
                "ImageBlurHashes": offlineItem.imageBlurHashes,
                "BackdropImageTags": offlineItem.backdropImageTags,
                "ImageTags": offlineItem.imageTags,
                "UserData": [
                    "PlaybackPositionTicks": offlineItem.userData.playbackPositionTicks as Any,
                    "PlayCount": offlineItem.userData.playCount,
                    "IsFavorite": offlineItem.userData.isFavorite,
                    "Played": offlineItem.userData.played,
                    "Key": ""
                ]
            ]
        )
        showingPlayer = true
    }
    
    private func deleteItem(_ item: DownloadedItem) {
        Task {
            try? await playbackService.deleteDownload(itemId: item.id)
            playbackService.deleteOfflineMetadata(id: item.id)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(downloadedItems) { item in
                        DownloadItemCard(
                            item: item,
                            onPlay: { playItem(item) },
                            onDelete: { deleteItem(item) }
                        )
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