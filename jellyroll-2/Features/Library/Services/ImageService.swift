import Foundation
import OSLog

/// Represents the current state of an image loading operation
enum ImageLoadingState {
    case loading
    case loaded(URL)
    case failed(Error)
    case notFound
}

/// Custom error types for image loading operations
enum ImageError: LocalizedError {
    case invalidConfiguration
    case invalidURL
    case unauthorized
    case noServerConfig
    case noAuthToken
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid server configuration"
        case .invalidURL:
            return "Invalid image URL"
        case .unauthorized:
            return "Unauthorized access"
        case .noServerConfig:
            return "Server configuration not found"
        case .noAuthToken:
            return "Authentication token not found"
        }
    }
}

enum ImageType {
    case primary
    case backdrop
    case thumb
    case logo
    
    var queryValue: String {
        switch self {
        case .primary: return "Primary"
        case .backdrop: return "Backdrop"
        case .thumb: return "Thumb"
        case .logo: return "Logo"
        }
    }
}

class ImageService {
    static let shared = ImageService()
    private let authService = AuthenticationService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "ImageService")
    
    private init() {}
    
    /// Loads an image with proper error handling and state management
    func loadImage(itemId: String, imageType: ImageType = .primary) async -> ImageLoadingState {
        do {
            guard let config = try authService.getServerConfiguration() else {
                logger.error("No server configuration found")
                return .failed(ImageError.noServerConfig)
            }
            
            guard let token = try authService.getCurrentToken() else {
                logger.error("No authentication token found")
                return .failed(ImageError.noAuthToken)
            }
            
            let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
            guard var components = URLComponents(string: urlString) else {
                logger.error("Invalid server URL")
                return .failed(ImageError.invalidURL)
            }
            
            components.path = "/Items/\(itemId)/Images/\(imageType.queryValue)"
            
            // Add auth token as query parameter
            components.queryItems = [
                URLQueryItem(name: "fillWidth", value: "480"),
                URLQueryItem(name: "quality", value: "90"),
                URLQueryItem(name: "tag", value: token.accessToken)
            ]
            
            guard let url = components.url else {
                return .failed(ImageError.invalidURL)
            }
            
            return .loaded(url)
        } catch {
            logger.error("Failed to load image: \(error.localizedDescription)")
            return .failed(error)
        }
    }
    
    // Keep the existing getImageURL method for backward compatibility
    func getImageURL(itemId: String, imageType: ImageType = .primary) throws -> URL? {
        guard let config = try authService.getServerConfiguration() else {
            logger.error("No server configuration found")
            return nil
        }
        
        guard let token = try authService.getCurrentToken() else {
            logger.error("No authentication token found")
            return nil
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard var components = URLComponents(string: urlString) else {
            logger.error("Invalid server URL")
            return nil
        }
        
        components.path = "/Items/\(itemId)/Images/\(imageType.queryValue)"
        
        // Add auth token as query parameter
        components.queryItems = [
            URLQueryItem(name: "fillWidth", value: "480"),
            URLQueryItem(name: "quality", value: "90"),
            URLQueryItem(name: "tag", value: token.accessToken)
        ]
        
        return components.url
    }
} 