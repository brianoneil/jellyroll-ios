import Foundation

struct ServerHistory: Codable, Identifiable {
    let id: UUID
    let url: String
    let lastUsed: Date
    
    init(url: String) {
        self.id = UUID()
        self.url = url
        self.lastUsed = Date()
    }
} 