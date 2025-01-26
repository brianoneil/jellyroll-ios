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
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "Authentication")
    private let config = JellyfinClientConfig.shared
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try parsing with microseconds
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try without microseconds
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        return decoder
    }()
    
    private init() {}
    
    private func addAuthHeaders(to request: inout URLRequest, token: String? = nil) {
        config.addCommonHeaders(to: &request)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(config.getAuthorizationHeader(with: token), forHTTPHeaderField: "X-Emby-Authorization")
        } else {
            request.setValue(config.getAuthorizationHeader(with: nil), forHTTPHeaderField: "X-Emby-Authorization")
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
        addAuthHeaders(to: &request)
        
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
        addAuthHeaders(to: &request)
        
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