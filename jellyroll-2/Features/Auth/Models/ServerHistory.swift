import Foundation

struct ServerHistory: Codable {
    let url: String
    let lastUsed: Date
    
    init(url: String) {
        self.url = url
        self.lastUsed = Date()
    }
} 