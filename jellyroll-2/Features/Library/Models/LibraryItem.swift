import Foundation

struct LibraryItem: Codable, Identifiable {
    let id: String
    let name: String
    let serverId: String
    let etag: String
    let dateCreated: String
    let canDelete: Bool
    let canDownload: Bool
    let sortName: String
    let forcedSortName: String?
    let collectionType: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case serverId = "ServerId"
        case etag = "Etag"
        case dateCreated = "DateCreated"
        case canDelete = "CanDelete"
        case canDownload = "CanDownload"
        case sortName = "SortName"
        case forcedSortName = "ForcedSortName"
        case collectionType = "CollectionType"
    }
}

enum LibraryType: String {
    case movies = "movies"
    case tvshows = "tvshows"
    case music = "music"
    case photos = "photos"
    case unknown
    
    init(from collectionType: String?) {
        switch collectionType?.lowercased() {
        case "movies": self = .movies
        case "tvshows": self = .tvshows
        case "music": self = .music
        case "photos": self = .photos
        default: self = .unknown
        }
    }
    
    var icon: String {
        switch self {
        case .movies: return "film"
        case .tvshows: return "tv"
        case .music: return "music.note"
        case .photos: return "photo"
        case .unknown: return "questionmark"
        }
    }
    
    var displayName: String {
        switch self {
        case .movies: return "Movies"
        case .tvshows: return "TV Shows"
        case .music: return "Music"
        case .photos: return "Photos"
        case .unknown: return "Unknown"
        }
    }
} 