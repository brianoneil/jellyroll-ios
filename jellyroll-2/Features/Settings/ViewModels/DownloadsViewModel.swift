import Foundation
import OSLog

// Model to represent a downloaded item
struct DownloadedItem: Identifiable {
    let id: String
    let name: String
    let localURL: URL
    let size: Int64?
    
    var formattedSize: String? {
        guard let size = size else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

@MainActor
class DownloadsViewModel: ObservableObject {
    private let playbackService = PlaybackService.shared
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "DownloadsViewModel")
    
    @Published private(set) var downloads: [DownloadedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    func loadDownloads() async {
        isLoading = true
        defer { isLoading = false }
        
        let fileManager = FileManager.default
        var downloadedItems: [DownloadedItem] = []
        
        for (itemId, state) in playbackService.activeDownloads {
            if case .downloaded = state.status,
               let localURL = state.localURL,
               fileManager.fileExists(atPath: localURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: localURL.path)
                    let fileSize = attributes[.size] as? Int64
                    
                    downloadedItems.append(DownloadedItem(
                        id: itemId,
                        name: state.itemName,
                        localURL: localURL,
                        size: fileSize
                    ))
                } catch {
                    logger.error("Error getting file size for \(itemId): \(error.localizedDescription)")
                }
            }
        }
        
        await MainActor.run {
            self.downloads = downloadedItems.sorted { $0.name < $1.name }
        }
    }
    
    func deleteDownload(_ download: DownloadedItem) async {
        do {
            try playbackService.deleteDownload(itemId: download.id)
            await loadDownloads()
        } catch {
            logger.error("Error deleting download \(download.id): \(error.localizedDescription)")
            self.error = error
        }
    }
} 