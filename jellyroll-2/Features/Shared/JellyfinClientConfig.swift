import Foundation

struct JellyfinClientConfig {
    static let shared = JellyfinClientConfig()
    
    let deviceId: String
    let clientName: String
    let clientVersion: String
    
    private init() {
        // Use stored device ID or create new one
        if let storedDeviceId = UserDefaults.standard.string(forKey: "jellyfin_device_id") {
            deviceId = storedDeviceId
        } else {
            deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "jellyfin_device_id")
        }
        
        clientName = "Jellyroll iOS"
        clientVersion = "1.0.0"
    }
    
    var authorizationHeader: String {
        return [
            "MediaBrowser Client=\(clientName)",
            "Device=iOS",
            "DeviceId=\(deviceId)",
            "Version=\(clientVersion)",
            "Token="
        ].joined(separator: ", ")
    }
    
    func addCommonHeaders(to request: inout URLRequest) {
        request.setValue(authorizationHeader, forHTTPHeaderField: "X-Emby-Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("*", forHTTPHeaderField: "X-Emby-Accept-Encoding")
    }
    
    func getAuthorizationHeader(with token: String?) -> String {
        var components = [
            "MediaBrowser Client=\(clientName)",
            "Device=iOS",
            "DeviceId=\(deviceId)",
            "Version=\(clientVersion)"
        ]
        
        if let token = token {
            components.append("Token=\(token)")
        }
        
        return components.joined(separator: ", ")
    }
} 