import SwiftUI

struct DownloadSpaceUsage: Identifiable {
    let id: String
    let name: String
    let size: Int64
    let color: Color
}

struct DownloadsManagementView: View {
    @StateObject private var playbackService = PlaybackService.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var downloadItems: [DownloadSpaceUsage] = []
    @State private var totalSpace: Int64 = 0
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = true
    
    private let colors: [Color] = [
        .accentColor,
        .purple,
        .mint,
        .orange,
        .pink,
        .teal
    ]
    
    private let numberFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tint(themeManager.currentTheme.accentColor)
                    } else {
                        // Stats Summary
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Downloaded Items:")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                Text("\(downloadItems.count)")
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            }
                            
                            HStack {
                                Text("Total Space Used:")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                Text(numberFormatter.string(fromByteCount: totalSpace))
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(themeManager.currentTheme.elevatedSurfaceColor)
                        .cornerRadius(12)
                        
                        // Space Usage Graph
                        if !downloadItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Space Usage by Item")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Bar Graph
                                GeometryReader { geometry in
                                    HStack(spacing: 2) {
                                        ForEach(downloadItems) { item in
                                            let width = CGFloat(item.size) / CGFloat(totalSpace) * geometry.size.width
                                            item.color
                                                .frame(width: max(width, 2))
                                        }
                                    }
                                    .frame(height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .frame(height: 24)
                                
                                // Legend
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(downloadItems) { item in
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 12, height: 12)
                                            
                                            Text(item.name)
                                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                            
                                            Spacer()
                                            
                                            Text(numberFormatter.string(fromByteCount: item.size))
                                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                            .background(themeManager.currentTheme.elevatedSurfaceColor)
                            .cornerRadius(12)
                        }
                        
                        // Clear Downloads Button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Downloads")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                        .alert("Clear Downloads", isPresented: $showingDeleteConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Clear All", role: .destructive) {
                                Task {
                                    await clearAllDownloads()
                                }
                            }
                        } message: {
                            Text("This will remove all downloaded items and free up \(numberFormatter.string(fromByteCount: totalSpace)) of space. This action cannot be undone.")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await loadDownloadStats()
            }
        }
    }
    
    private func loadDownloadStats() async {
        isLoading = true
        defer { isLoading = false }
        
        let fileManager = FileManager.default
        var downloads: [DownloadSpaceUsage] = []
        var total: Int64 = 0
        var colorIndex = 0
        
        for (itemId, state) in playbackService.activeDownloads {
            if case .downloaded = state.status,
               let localURL = state.localURL,
               fileManager.fileExists(atPath: localURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: localURL.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    
                    downloads.append(DownloadSpaceUsage(
                        id: itemId,
                        name: state.itemName,
                        size: fileSize,
                        color: colors[colorIndex % colors.count]
                    ))
                    
                    total += fileSize
                    colorIndex += 1
                } catch {
                    print("Error getting file size: \(error)")
                }
            }
        }
        
        await MainActor.run {
            self.downloadItems = downloads.sorted { $0.size > $1.size }
            self.totalSpace = total
        }
    }
    
    private func clearAllDownloads() async {
        for item in downloadItems {
            do {
                try playbackService.deleteDownload(itemId: item.id)
            } catch {
                print("Error deleting download: \(error)")
            }
        }
        await loadDownloadStats()
    }
}

#Preview {
    NavigationStack {
        DownloadsManagementView()
            .environmentObject(ThemeManager())
    }
} 