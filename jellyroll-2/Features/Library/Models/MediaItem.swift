import Foundation
import os

private let logger = Logger(subsystem: "com.jellyroll", category: "MediaItem")

struct MediaItemResponse: Codable {
    let items: [MediaItem]
    let totalRecordCount: Int
    let startIndex: Int
    
    init(from decoder: Decoder) throws {
        var decodedItems: [MediaItem]
        var decodedTotalRecordCount: Int
        var decodedStartIndex: Int
        
        do {
            // Try decoding as dictionary first
            let container = try decoder.container(keyedBy: CodingKeys.self)
            decodedItems = try container.decode([MediaItem].self, forKey: .items)
            decodedTotalRecordCount = try container.decode(Int.self, forKey: .totalRecordCount)
            decodedStartIndex = try container.decode(Int.self, forKey: .startIndex)
            logger.debug("Successfully decoded dictionary response")
        } catch {
            // If dictionary decoding fails, try array
            logger.debug("Dictionary decoding failed, trying array: \(error.localizedDescription)")
            do {
                let container = try decoder.singleValueContainer()
                decodedItems = try container.decode([MediaItem].self)
                decodedTotalRecordCount = decodedItems.count
                decodedStartIndex = 0
                logger.debug("Successfully decoded array response")
            } catch let arrayError {
                logger.error("Array decoding also failed: \(arrayError.localizedDescription)")
                throw arrayError
            }
        }
        
        self.items = decodedItems
        self.totalRecordCount = decodedTotalRecordCount
        self.startIndex = decodedStartIndex
    }
    
    private enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
        case startIndex = "StartIndex"
    }
    
    // Helper method to decode either response format
    static func decode(from data: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> MediaItemResponse {
        do {
            // Try decoding as MediaItemResponse first
            return try decoder.decode(MediaItemResponse.self, from: data)
        } catch {
            logger.debug("MediaItemResponse decoding failed, trying array: \(error.localizedDescription)")
            // If that fails, try decoding as array and wrap it
            let items = try decoder.decode([MediaItem].self, from: data)
            return MediaItemResponse(items: items, totalRecordCount: items.count, startIndex: 0)
        }
    }
    
    // Convenience initializer for array responses
    init(items: [MediaItem], totalRecordCount: Int, startIndex: Int) {
        self.items = items
        self.totalRecordCount = totalRecordCount
        self.startIndex = startIndex
    }
}

struct MediaItem: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let overview: String?
    let premiereDate: Date?
    let productionYear: Int?
    let communityRating: Double?
    let officialRating: String?
    let genres: [String]
    let taglines: [String]
    let imageBlurHashes: [String: [String: String]]
    let backdropImageTags: [String]
    let imageTags: [String: String]
    let userData: UserData
    
    // Cast and Crew
    let people: [Person]?
    
    // Series specific
    let seriesName: String?
    let seasonName: String?
    let episodeTitle: String?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let runTimeTicks: Int64?
    
    // Music specific
    let albumArtist: String?
    let artists: [String]?
    let album: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case type = "Type"
        case overview = "Overview"
        case premiereDate = "PremiereDate"
        case productionYear = "ProductionYear"
        case communityRating = "CommunityRating"
        case officialRating = "OfficialRating"
        case genres = "Genres"
        case taglines = "Tags"
        case imageBlurHashes = "ImageBlurHashes"
        case backdropImageTags = "BackdropImageTags"
        case imageTags = "ImageTags"
        case userData = "UserData"
        case people = "People"
        case seriesName = "SeriesName"
        case seasonName = "SeasonName"
        case episodeTitle = "EpisodeTitle"
        case seasonNumber = "ParentIndexNumber"
        case episodeNumber = "IndexNumber"
        case runTimeTicks = "RunTimeTicks"
        case albumArtist = "AlbumArtist"
        case artists = "Artists"
        case album = "Album"
    }
    
    // Helper computed properties for cast and crew
    var cast: [Person] {
        people?.filter { $0.type == "Actor" } ?? []
    }
    
    var directors: [Person] {
        people?.filter { $0.type == "Director" } ?? []
    }
    
    var writers: [Person] {
        people?.filter { $0.type == "Writer" } ?? []
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Custom date decoding for Jellyfin's date format
        if let premiereDateString = try container.decodeIfPresent(String.self, forKey: .premiereDate) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            premiereDate = formatter.date(from: premiereDateString)
            if premiereDate == nil {
                logger.warning("Failed to parse date: \(premiereDateString)")
            }
        } else {
            premiereDate = nil
        }
        
        // Decode all other properties
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        productionYear = try container.decodeIfPresent(Int.self, forKey: .productionYear)
        communityRating = try container.decodeIfPresent(Double.self, forKey: .communityRating)
        officialRating = try container.decodeIfPresent(String.self, forKey: .officialRating)
        genres = try container.decode([String].self, forKey: .genres)
        taglines = try container.decode([String].self, forKey: .taglines)
        imageBlurHashes = try container.decode([String: [String: String]].self, forKey: .imageBlurHashes)
        backdropImageTags = try container.decode([String].self, forKey: .backdropImageTags)
        imageTags = try container.decode([String: String].self, forKey: .imageTags)
        
        seriesName = try container.decodeIfPresent(String.self, forKey: .seriesName)
        seasonName = try container.decodeIfPresent(String.self, forKey: .seasonName)
        episodeTitle = try container.decodeIfPresent(String.self, forKey: .episodeTitle)
        seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber)
        episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber)
        runTimeTicks = try container.decodeIfPresent(Int64.self, forKey: .runTimeTicks)
        
        albumArtist = try container.decodeIfPresent(String.self, forKey: .albumArtist)
        artists = try container.decodeIfPresent([String].self, forKey: .artists)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        
        userData = try container.decode(UserData.self, forKey: .userData)
        
        // Make people optional
        people = try container.decodeIfPresent([Person].self, forKey: .people)
    }
    
    var formattedRuntime: String? {
        guard let ticks = runTimeTicks else { return nil }
        let seconds = Double(ticks) / 10_000_000
        let minutes = Int(seconds / 60)
        return "\(minutes)min"
    }
    
    var playbackProgress: Double? {
        guard let position = playbackPositionTicks,
              let total = runTimeTicks,
              total > 0 else { return nil }
        return Double(position) / Double(total)
    }
    
    var remainingTime: String? {
        guard let position = playbackPositionTicks,
              let total = runTimeTicks,
              total > 0 else { return nil }
        let remainingTicks = total - position
        let remainingSeconds = Double(remainingTicks) / 10_000_000
        let remainingMinutes = Int(remainingSeconds / 60)
        return "\(remainingMinutes)min remaining"
    }
    
    var episodeInfo: String? {
        guard let seasonNumber = seasonNumber,
              let episodeNumber = episodeNumber else { return nil }
        return "S\(seasonNumber):E\(episodeNumber)"
    }
    
    var yearText: String? {
        guard let year = productionYear else { return nil }
        return String(year)
    }
    
    var genreText: String? {
        guard !genres.isEmpty else { return nil }
        return genres.first
    }
    
    var artistText: String? {
        if let albumArtist = albumArtist {
            return albumArtist
        } else if let artists = artists, !artists.isEmpty {
            return artists.joined(separator: ", ")
        }
        return nil
    }
    
    var playbackPositionTicks: Int64? {
        return userData.playbackPositionTicks
    }
    
    var formattedRating: String? {
        guard let rating = officialRating else { return nil }
        
        // List of valid US movie ratings to look for with word boundaries
        let ratingPatterns = [
            "\\bG\\b",
            "\\bPG\\b",
            "\\bPG-13\\b",
            "\\bR\\b",
            "\\bNC-17\\b"
        ]
        
        let upperRating = rating.uppercased()
        
        // Try to find any valid rating within the text
        for pattern in ratingPatterns {
            if let range = upperRating.range(of: pattern, options: .regularExpression) {
                return String(upperRating[range])
            }
        }
        
        return nil
    }
}

struct UserData: Codable {
    let playbackPositionTicks: Int64?
    let playCount: Int
    let isFavorite: Bool
    let played: Bool
    let key: String
    
    private enum CodingKeys: String, CodingKey {
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
        case played = "Played"
        case key = "Key"
    }
}

struct ProviderIds: Codable {
    // Add provider ID fields as needed
}

struct Person: Codable, Identifiable {
    let id: String
    let name: String
    let role: String?
    let type: String
    let primaryImageTag: String?
    let imageBlurHashes: [String: [String: String]]?
    let providerIds: ProviderIds?
    
    private enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case role = "Role"
        case type = "Type"
        case primaryImageTag = "PrimaryImageTag"
        case imageBlurHashes = "ImageBlurHashes"
        case providerIds = "ProviderIds"
    }
} 