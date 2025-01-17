import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif

enum LibraryError: Error {
    case invalidToken
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)
}

class LibraryService {
    static let shared = LibraryService()
    private let authService = AuthenticationService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "LibraryService")
    
    private let clientName = "Jellyroll"
    private let clientVersion = "1.0.0"
    private let deviceId: String = {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        return UUID().uuidString
        #endif
    }()
    private let deviceName: String = {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Mac"
        #endif
    }()
    
    private init() {}
    
    private func addAuthHeaders(to request: inout URLRequest, token: String) {
        // Use X-MediaBrowser-Token for authentication
        request.setValue(token, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        // Jellyfin specific auth header
        let embyAuth = [
            "MediaBrowser",
            "Client=\"\(clientName)\"",
            "Device=\"\(deviceName)\"",
            "DeviceId=\"\(deviceId)\"",
            "Version=\"\(clientVersion)\"",
            "Token=\"\(token)\""
        ].joined(separator: " ")
        
        request.setValue(embyAuth, forHTTPHeaderField: "X-Emby-Authorization")
        
        // Content headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // User-Agent header
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        logger.debug("Auth headers: \(embyAuth)")
    }
    
    func getLibraries() async throws -> [LibraryItem] {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            logger.error("No valid token or server configuration found")
            throw LibraryError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: urlString)?.appendingPathComponent("/Users/\(token.user.id)/Views") else {
            logger.error("Failed to create URL from: \(urlString)")
            throw LibraryError.serverError("Invalid server URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request, token: token.accessToken)
        
        logger.debug("Fetching libraries from: \(url)")
        logger.debug("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw LibraryError.serverError("Invalid response")
            }
            
            logger.debug("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    logger.error("Server error response: \(errorText)")
                }
                throw LibraryError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Raw JSON response: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            
            let libraryResponse = try decoder.decode(LibraryResponse.self, from: data)
            logger.debug("Successfully decoded \(libraryResponse.items.count) libraries")
            return libraryResponse.items
        } catch let error as DecodingError {
            logger.error("Decoding error: \(error)")
            throw LibraryError.decodingError(error)
        } catch {
            logger.error("Network error details: \(error.localizedDescription)")
            throw LibraryError.networkError(error)
        }
    }
    
    func getLatestMedia(limit: Int = 20) async throws -> [MediaItem] {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw LibraryError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: urlString)?.appendingPathComponent("/Users/\(token.user.id)/Items/Latest") else {
            throw LibraryError.serverError("Invalid server URL")
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "Limit", value: String(limit)),
            URLQueryItem(name: "Fields", value: "Overview,Genres,Tags,ProductionYear,PremiereDate,People")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request, token: token.accessToken)
        
        return try await fetchItems(with: request)
    }
    
    func getContinueWatching() async throws -> [MediaItem] {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw LibraryError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: urlString)?.appendingPathComponent("/Users/\(token.user.id)/Items/Resume") else {
            throw LibraryError.serverError("Invalid server URL")
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "Limit", value: "10"),
            URLQueryItem(name: "Fields", value: "Overview,Genres,Tags,ProductionYear,PremiereDate,RunTimeTicks,PlaybackPositionTicks,UserData,People")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request, token: token.accessToken)
        
        logger.debug("Fetching continue watching items from: \(components.url?.absoluteString ?? "")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("Continue watching response status: \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Continue watching raw response: \(responseString)")
            }
            
            return try await fetchItems(with: request)
        } catch {
            logger.error("Error fetching continue watching items: \(error)")
            throw error
        }
    }
    
    func getLibraryItems(libraryId: String, limit: Int = 50) async throws -> [MediaItem] {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw LibraryError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: urlString)?.appendingPathComponent("/Users/\(token.user.id)/Items") else {
            throw LibraryError.serverError("Invalid server URL")
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "ParentId", value: libraryId),
            URLQueryItem(name: "Limit", value: String(limit)),
            URLQueryItem(name: "Fields", value: "Overview,Genres,Tags,ProductionYear,PremiereDate,RunTimeTicks,PlaybackPositionTicks,People"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request, token: token.accessToken)
        
        return try await fetchItems(with: request)
    }
    
    private func fetchItems(with request: URLRequest) async throws -> [MediaItem] {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw LibraryError.serverError("Invalid response")
            }
            
            logger.debug("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    logger.error("Server error response: \(errorText)")
                }
                throw LibraryError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Response data: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let itemsResponse = try MediaItemResponse.decode(from: data, using: decoder)
            logger.debug("Successfully decoded \(itemsResponse.items.count) items")
            return itemsResponse.items
        } catch let error as DecodingError {
            logger.error("Decoding error: \(error)")
            throw LibraryError.decodingError(error)
        } catch {
            logger.error("Network error details: \(error.localizedDescription)")
            throw LibraryError.networkError(error)
        }
    }
}

private struct LibraryResponse: Codable {
    let items: [LibraryItem]
    
    private enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
} 