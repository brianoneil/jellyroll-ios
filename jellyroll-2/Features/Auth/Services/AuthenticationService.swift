import Foundation
import OSLog

struct LoginRequest: Codable {
    let username: String
    let pw: String
    
    enum CodingKeys: String, CodingKey {
        case username = "Username"
        case pw = "Pw"
    }
}

enum AuthenticationError: Error {
    case invalidServerURL
    case invalidCredentials
    case networkError(Error)
    case serverError(String)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidServerURL:
            return "Invalid server URL"
        case .invalidCredentials:
            return "Invalid credentials"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

class AuthenticationService {
    static let shared = AuthenticationService()
    private let keychainService = KeychainService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "Authentication")
    private let deviceId = UUID().uuidString
    private let clientName = "Jellyroll iOS"
    private let clientVersion = "1.0.0"
    private let serverHistoryKey = "server_history"
    private let maxServerHistory = 5
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Handle Jellyfin's date format with microseconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try the primary format (with microseconds)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to format without microseconds
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        return decoder
    }()
    
    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private var authorizationHeader: String {
        return [
            "MediaBrowser Client=\(clientName)",
            "Device=iOS",
            "DeviceId=\(deviceId)",
            "Version=\(clientVersion)"
        ].joined(separator: ", ")
    }
    
    private init() {}
    
    private func addCommonHeaders(to request: inout URLRequest) {
        request.setValue(authorizationHeader, forHTTPHeaderField: "X-Emby-Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }
    
    // MARK: - Server History
    
    func getServerHistory() -> [ServerHistory] {
        do {
            if let data = UserDefaults.standard.data(forKey: serverHistoryKey),
               let history = try? jsonDecoder.decode([ServerHistory].self, from: data) {
                return history.sorted { $0.lastUsed > $1.lastUsed }
            }
        }
        return []
    }
    
    private func addToServerHistory(_ urlString: String) {
        var history = getServerHistory()
        
        // Remove existing entry if present
        history.removeAll { $0.url == urlString }
        
        // Add new entry at the beginning
        history.insert(ServerHistory(url: urlString), at: 0)
        
        // Keep only the most recent entries
        if history.count > maxServerHistory {
            history = Array(history.prefix(maxServerHistory))
        }
        
        // Save updated history
        do {
            let data = try jsonEncoder.encode(history)
            UserDefaults.standard.set(data, forKey: serverHistoryKey)
        } catch {
            logger.error("Failed to save server history: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Server Configuration
    
    func setServerConfiguration(_ urlString: String) async throws -> ServerConfiguration {
        logger.debug("Attempting to set server configuration with URL: \(urlString)")
        
        guard let config = ServerConfiguration(urlString: urlString) else {
            logger.error("Invalid server URL format: \(urlString)")
            throw AuthenticationError.invalidServerURL
        }
        
        // Validate server is reachable
        guard await validateServer(config) else {
            logger.error("Server validation failed for URL: \(urlString)")
            throw AuthenticationError.serverError("Unable to connect to server")
        }
        
        logger.debug("Server configuration validated successfully")
        try keychainService.saveServerConfiguration(config)
        addToServerHistory(urlString)
        return config
    }
    
    func getServerConfiguration() throws -> ServerConfiguration? {
        try keychainService.loadServerConfiguration()
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async throws -> AuthenticationToken {
        logger.debug("Attempting login for user: \(username)")
        
        guard let config = try keychainService.loadServerConfiguration() else {
            logger.error("No server configuration found")
            throw AuthenticationError.invalidServerURL
        }
        
        let loginURL = config.serverURL.appendingPathComponent("Users/AuthenticateByName")
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        addCommonHeaders(to: &request)
        
        let loginRequest = LoginRequest(username: username, pw: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        do {
            logger.debug("Sending login request to: \(loginURL)")
            logger.debug("Request headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                logger.debug("Request body: \(bodyString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type received")
                throw AuthenticationError.unknown
            }
            
            logger.debug("Received response with status code: \(httpResponse.statusCode)")
            logger.debug("Response headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    logger.error("Server returned error: \(errorResponse)")
                    throw AuthenticationError.serverError(errorResponse)
                }
                throw AuthenticationError.invalidCredentials
            }
            
            // Log the response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Server response: \(responseString)")
            }
            
            let token = try jsonDecoder.decode(AuthenticationToken.self, from: data)
            try keychainService.saveAuthToken(token)
            logger.debug("Login successful for user: \(username)")
            return token
            
        } catch let error as DecodingError {
            logger.error("Decoding error: \(error)")
            throw AuthenticationError.serverError("Invalid response format from server: \(error.localizedDescription)")
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw AuthenticationError.networkError(error)
        }
    }
    
    func getCurrentToken() throws -> AuthenticationToken? {
        try keychainService.loadAuthToken()
    }
    
    func logout() throws {
        logger.debug("Logging out user")
        try keychainService.clearAll()
    }
    
    // MARK: - Private Helpers
    
    private func validateServer(_ config: ServerConfiguration) async -> Bool {
        let systemURL = config.serverURL.appendingPathComponent("System/Info/Public")
        var request = URLRequest(url: systemURL)
        request.httpMethod = "GET"
        addCommonHeaders(to: &request)
        
        do {
            logger.debug("Validating server at: \(systemURL)")
            logger.debug("Request headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type during server validation")
                return false
            }
            
            logger.debug("Response headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = String(data: data, encoding: .utf8) {
                    logger.error("Server validation failed with response: \(errorResponse)")
                }
                return false
            }
            
            logger.debug("Server validation successful")
            return true
        } catch {
            logger.error("Server validation error: \(error.localizedDescription)")
            return false
        }
    }
} 