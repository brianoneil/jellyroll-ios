import Foundation
import OSLog

@MainActor
class LibraryViewModel: ObservableObject {
    private let libraryService = LibraryService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "LibraryViewModel")
    
    @Published var libraries: [LibraryItem] = []
    @Published var continueWatching: [MediaItem] = []
    @Published var latestMedia: [MediaItem] = []
    @Published var movieItems: [String: [MediaItem]] = [:]
    @Published var tvShowItems: [String: [MediaItem]] = [:]
    @Published var musicItems: [String: [MediaItem]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
                        switch LibraryType(from: library.collectionType) {
                        case .movies:
                            await self.updateMovieItems(library.id, items)
                        case .tvshows:
                            await self.updateTVShowItems(library.id, items)
                        case .music:
                            await self.updateMusicItems(library.id, items)
                        default:
                            break
                        }
                    } catch {
                        self.logger.error("Error loading items for library \(library.name): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateMovieItems(_ libraryId: String, _ items: [MediaItem]) {
        movieItems[libraryId] = items
    }
    
    @MainActor
    private func updateTVShowItems(_ libraryId: String, _ items: [MediaItem]) {
        tvShowItems[libraryId] = items
    }
    
    @MainActor
    private func updateMusicItems(_ libraryId: String, _ items: [MediaItem]) {
        musicItems[libraryId] = items
    }
    
    var movieLibraries: [LibraryItem] {
        libraries.filter { LibraryType(from: $0.collectionType) == .movies }
    }
    
    var tvShowLibraries: [LibraryItem] {
        libraries.filter { LibraryType(from: $0.collectionType) == .tvshows }
    }
    
    var musicLibraries: [LibraryItem] {
        libraries.filter { LibraryType(from: $0.collectionType) == .music }
    }
    
    func getMovieItems(for libraryId: String) -> [MediaItem] {
        movieItems[libraryId] ?? []
    }
    
    func getTVShowItems(for libraryId: String) -> [MediaItem] {
        tvShowItems[libraryId] ?? []
    }
    
    func getMusicItems(for libraryId: String) -> [MediaItem] {
        musicItems[libraryId] ?? []
    }
} 