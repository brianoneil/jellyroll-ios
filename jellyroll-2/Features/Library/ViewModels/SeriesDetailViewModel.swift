import Foundation
import SwiftUI

class SeriesDetailViewModel: ObservableObject {
    let item: MediaItem
    @Published var seasons: [MediaItem] = []
    @Published var episodes: [String: [MediaItem]] = [:] // Season ID -> Episodes
    @Published var isLoadingSeasons = false
    @Published var isLoadingEpisodes = false
    @Published var error: String?
    
    init(item: MediaItem) {
        self.item = item
    }
    
    @MainActor
    func loadSeasons() async {
        isLoadingSeasons = true
        error = nil
        
        // TODO: Implement API call to load seasons
        // This would fetch seasons from your Jellyfin API
        // For now, using mock data
        await mockLoadSeasons()
        
        isLoadingSeasons = false
    }
    
    @MainActor
    func loadEpisodes(for seasonId: String) async {
        if episodes[seasonId] != nil { return }
        
        isLoadingEpisodes = true
        error = nil
        
        // TODO: Implement API call to load episodes
        // This would fetch episodes for the given season from your Jellyfin API
        // For now, using mock data
        await mockLoadEpisodes(for: seasonId)
        
        isLoadingEpisodes = false
    }
    
    // Mock data loading - Replace with actual API calls
    private func mockLoadSeasons() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create mock seasons
        let mockSeasons = (1...3).map { seasonNumber in
            MediaItem(from: [
                "Id": "season_\(seasonNumber)",
                "Name": "Season \(seasonNumber)",
                "Type": "Season",
                "ParentIndexNumber": seasonNumber,
                "Overview": "Season \(seasonNumber) of \(item.name)",
                "ImageTags": ["Primary": "tag"],
                "ImageBlurHashes": [:],
                "BackdropImageTags": [],
                "Genres": [],
                "Tags": []
            ])
        }
        
        await MainActor.run {
            self.seasons = mockSeasons
        }
    }
    
    private func mockLoadEpisodes(for seasonId: String) async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Extract season number from ID
        let seasonNumber = Int(seasonId.split(separator: "_")[1]) ?? 1
        
        // Create mock episodes
        let mockEpisodes = (1...10).map { episodeNumber in
            MediaItem(from: [
                "Id": "episode_s\(seasonNumber)e\(episodeNumber)",
                "Name": "Episode \(episodeNumber)",
                "Type": "Episode",
                "ParentIndexNumber": seasonNumber,
                "IndexNumber": episodeNumber,
                "Overview": "Episode \(episodeNumber) of Season \(seasonNumber)",
                "ImageTags": ["Primary": "tag"],
                "ImageBlurHashes": [:],
                "BackdropImageTags": [],
                "Genres": [],
                "Tags": [],
                "RunTimeTicks": Int64(2_400_000_000) // 40 minutes in ticks
            ])
        }
        
        await MainActor.run {
            self.episodes[seasonId] = mockEpisodes
        }
    }
} 