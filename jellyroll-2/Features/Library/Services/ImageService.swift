import Foundation
import OSLog

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
    
    func getImageURL(itemId: String, imageType: ImageType = .primary) throws -> URL? {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            logger.error("No valid token or server configuration found")
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