import Foundation

struct OfflineMediaItem: Codable, Identifiable {
    let id: String
    let name: String
    let overview: String?
    let type: String
    let genres: [String]
    let taglines: [String]
    let imageBlurHashes: [String: [String: String]]
    let backdropImageTags: [String]
    let imageTags: [String: String]
    let userData: UserData
    let localURL: URL
    let downloadDate: Date
    
    struct UserData: Codable {
        let playbackPositionTicks: Int64?
        let playCount: Int
        let isFavorite: Bool
        let played: Bool
    }
    
    init(from mediaItem: MediaItem, localURL: URL) {
        self.id = mediaItem.id
        self.name = mediaItem.name
        self.overview = mediaItem.overview
        self.type = mediaItem.type
        self.genres = mediaItem.genres
        self.taglines = mediaItem.taglines
        self.imageBlurHashes = mediaItem.imageBlurHashes
        self.backdropImageTags = mediaItem.backdropImageTags
        self.imageTags = mediaItem.imageTags
        self.userData = UserData(
            playbackPositionTicks: mediaItem.userData.playbackPositionTicks,
            playCount: mediaItem.userData.playCount,
            isFavorite: mediaItem.userData.isFavorite,
            played: mediaItem.userData.played
        )
        self.localURL = localURL
        self.downloadDate = Date()
    }
} 