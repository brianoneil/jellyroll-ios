import Foundation
import OSLog

enum PlaybackError: Error {
    case invalidToken
    case networkError(Error)
    case serverError(String)
    case invalidURL
}

class PlaybackService {
    static let shared = PlaybackService()
    private let authService = AuthenticationService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "PlaybackService")
    
    private init() {}
    
    func getPlaybackURL(for item: MediaItem) async throws -> URL {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            throw PlaybackError.invalidURL
        }
        
        // Construct the video stream URL
        let playbackURL = baseURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(item.id)
            .appendingPathComponent("stream")
        
        var components = URLComponents(url: playbackURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "static", value: "true"),
            URLQueryItem(name: "api_key", value: token.accessToken)
        ]
        
        guard let finalURL = components.url else {
            throw PlaybackError.invalidURL
        }
        
        return finalURL
    }
    
    func updatePlaybackProgress(for item: MediaItem, positionTicks: Int64) async throws {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            throw PlaybackError.invalidURL
        }
        
        // Construct the playback progress URL
        let progressURL = baseURL
            .appendingPathComponent("Users")
            .appendingPathComponent(token.user.id)
            .appendingPathComponent("PlayingItems")
            .appendingPathComponent(item.id)
            .appendingPathComponent("Progress")
        
        var request = URLRequest(url: progressURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        let progressData = [
            "PositionTicks": positionTicks
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: progressData)
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaybackError.serverError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                throw PlaybackError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
        } catch {
            logger.error("Error updating playback progress: \(error.localizedDescription)")
            throw PlaybackError.networkError(error)
        }
    }
} 