import Foundation
import SwiftUI

@MainActor
class SeriesDetailViewModel: ObservableObject {
    let item: MediaItem
    @Published var seasons: [MediaItem] = []
    @Published var selectedSeason: MediaItem?
    @Published var episodes: [MediaItem] = []
    @Published var nextUpEpisode: MediaItem?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let playbackService: PlaybackService
    private let libraryService: LibraryService
    
    init(item: MediaItem) {
        self.item = item
        self.playbackService = PlaybackService.shared
        self.libraryService = LibraryService.shared
    }
    
    func loadSeasons(for seriesId: String) {
        isLoading = true
        
        Task {
            do {
                async let seasonsTask = playbackService.getChildren(
                    parentId: seriesId,
                    filter: ["Season"]
                )
                async let nextUpTask = libraryService.getNextUpEpisode(for: seriesId)
                
                let (seasons, nextUp) = try await (seasonsTask, nextUpTask)
                
                self.seasons = seasons.sorted(by: { (a: MediaItem, b: MediaItem) in
                    return (a.seasonNumber ?? 0) < (b.seasonNumber ?? 0)
                })
                self.selectedSeason = seasons.first
                self.nextUpEpisode = nextUp
                self.isLoading = false
                
                if let firstSeason = seasons.first {
                    await loadEpisodes(for: firstSeason.id)
                }
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func loadEpisodes(for seasonId: String) async {
        self.isLoading = true
        
        do {
            let episodes = try await playbackService.getChildren(
                parentId: seasonId,
                filter: ["Episode"]
            )
            self.episodes = episodes.sorted(by: { (a: MediaItem, b: MediaItem) in
                return (a.episodeNumber ?? 0) < (b.episodeNumber ?? 0)
            })
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
    
    func selectSeason(_ season: MediaItem) {
        selectedSeason = season
        Task {
            await loadEpisodes(for: season.id)
        }
    }
} 