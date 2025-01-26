import Foundation
import OSLog

@MainActor
class LibraryViewModel: ObservableObject {
    private let libraryService = LibraryService.shared
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "LibraryViewModel")
    
    @Published var libraries: [LibraryItem] = []
    @Published var continueWatching: [MediaItem] = []
    @Published var latestMedia: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Single dictionary to store all media items by type and library ID
    @Published private var mediaItems: [LibraryType: [String: [MediaItem]]] = [
        .movies: [:],
        .tvshows: [:],
        .music: [:]
    ]
    
    func loadLibraries() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.libraries = try await libraryService.getLibraries()
            logger.debug("Loaded \(self.libraries.count) libraries")
            
            // Load continue watching and latest media for home tab
            async let continueWatchingItems = libraryService.getContinueWatching()
            async let latestMediaItems = libraryService.getLatestMedia()
            
            let (watching, latest) = try await (continueWatchingItems, latestMediaItems)
            self.continueWatching = watching
            self.latestMedia = latest
            
            // Load items for each library type
            await loadLibraryItems()
            
        } catch LibraryError.invalidToken {
            errorMessage = "Please log in again"
            logger.error("Invalid token while loading libraries")
        } catch LibraryError.networkError(let networkError) {
            errorMessage = "Network error: \(networkError.localizedDescription)"
            logger.error("Network error while loading libraries: \(networkError.localizedDescription)")
        } catch LibraryError.serverError(let message) {
            errorMessage = "Server error: \(message)"
            logger.error("Server error while loading libraries: \(message)")
        } catch {
            errorMessage = "An unexpected error occurred"
            logger.error("Unexpected error while loading libraries: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func loadLibraryItems() async {
        await withTaskGroup(of: Void.self) { group in
            for library in libraries {
                group.addTask {
                    do {
                        let items = try await self.libraryService.getLibraryItems(libraryId: library.id)
                        let type = LibraryType(from: library.collectionType)
                        if type != .unknown {
                            await self.updateMediaItems(type: type, libraryId: library.id, items: items)
                        }
                    } catch {
                        self.logger.error("Error loading items for library \(library.name): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateMediaItems(type: LibraryType, libraryId: String, items: [MediaItem]) {
        mediaItems[type]?[libraryId] = items
    }
    
    private func getLibraries(of type: LibraryType) -> [LibraryItem] {
        libraries.filter { LibraryType(from: $0.collectionType) == type }
    }
    
    private func getItems(type: LibraryType, libraryId: String) -> [MediaItem] {
        mediaItems[type]?[libraryId] ?? []
    }
    
    // Public interface remains the same for backward compatibility
    var movieLibraries: [LibraryItem] { getLibraries(of: .movies) }
    var tvShowLibraries: [LibraryItem] { getLibraries(of: .tvshows) }
    var musicLibraries: [LibraryItem] { getLibraries(of: .music) }
    
    func getMovieItems(for libraryId: String) -> [MediaItem] { getItems(type: .movies, libraryId: libraryId) }
    func getTVShowItems(for libraryId: String) -> [MediaItem] { getItems(type: .tvshows, libraryId: libraryId) }
    func getMusicItems(for libraryId: String) -> [MediaItem] { getItems(type: .music, libraryId: libraryId) }
} 