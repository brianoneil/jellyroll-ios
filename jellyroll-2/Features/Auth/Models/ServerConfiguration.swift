import Foundation

struct ServerConfiguration: Codable {
    let serverURL: URL
    let isSecure: Bool
    
    var baseURLString: String {
        serverURL.absoluteString
    }
    
    init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.serverURL = url
        self.isSecure = url.scheme?.lowercased() == "https"
    }
    
    // Validation
    func validate() -> Bool {
        return isSecure || serverURL.host == "localhost" || serverURL.host?.contains("192.168.") == true
    }
} 