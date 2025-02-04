import SwiftUI

// Import the module containing DownloadsViewModel
import Foundation

struct DownloadSpaceUsage: Identifiable {
    let id: String
    let name: String
    let size: Int64
    let color: Color
}

struct DownloadsManagementView: View {
    @StateObject private var viewModel = DownloadsViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
            if viewModel.downloads.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(themeManager.currentTheme.accentGradient)
                    
                    Text("No Downloads")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Text("Downloaded content will appear here")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            } else {
                List {
                    ForEach(viewModel.downloads) { download in
                        #if os(tvOS)
                        DownloadItemRow(download: download)
                            .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteDownload(download)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        #else
                        DownloadItemRow(download: download)
                            .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteDownload(download)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        #endif
                    }
                }
                #if !os(tvOS)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
        #if !os(tvOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle("Downloads")
        .task {
            await viewModel.loadDownloads()
        }
    }
}

struct DownloadItemRow: View {
    let download: DownloadedItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            JellyfinImage(
                itemId: download.id,
                imageType: .primary,
                aspectRatio: 2/3,
                cornerRadius: 8,
                fallbackIcon: "film"
            )
            .frame(width: 60)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(download.name)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(2)
                
                if let size = download.formattedSize {
                    Text(size)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Download Status
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        DownloadsManagementView()
            .environmentObject(ThemeManager())
    }
} 