import Foundation

struct AuthenticationToken: Codable {
    let accessToken: String
    let serverId: String
    let user: JellyfinUser
    
    var isExpired: Bool {
        // Token doesn't expire unless explicitly invalidated
        return false
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case serverId = "ServerId"
        case user = "User"
    }
}

struct JellyfinUser: Codable {
    let id: String
    let name: String
    let serverId: String
    let hasPassword: Bool
    let lastLoginDate: Date
    let lastActivityDate: Date
    let policy: UserPolicy
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case serverId = "ServerId"
        case hasPassword = "HasPassword"
        case lastLoginDate = "LastLoginDate"
        case lastActivityDate = "LastActivityDate"
        case policy = "Policy"
    }
}

struct UserPolicy: Codable {
    let isAdministrator: Bool
    let isDisabled: Bool
    let enableMediaPlayback: Bool
    let enableContentDownloading: Bool
    
    enum CodingKeys: String, CodingKey {
        case isAdministrator = "IsAdministrator"
        case isDisabled = "IsDisabled"
        case enableMediaPlayback = "EnableMediaPlayback"
        case enableContentDownloading = "EnableContentDownloading"
    }
} 