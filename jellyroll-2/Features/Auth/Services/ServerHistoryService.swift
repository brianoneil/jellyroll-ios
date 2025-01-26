import Foundation
import OSLog

class ServerHistoryService {
    static let shared = ServerHistoryService()
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "ServerHistory")
    private let serverHistoryKey = "server_history"
    private let maxServerHistory = 5
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    func getServerHistory() -> [ServerHistory] {
        do {
            if let data = UserDefaults.standard.data(forKey: serverHistoryKey),
               let history = try? jsonDecoder.decode([ServerHistory].self, from: data) {
                return history.sorted { $0.lastUsed > $1.lastUsed }
            }
        }
        return []
    }
    
    func addToHistory(_ urlString: String) {
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
    
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: serverHistoryKey)
    }
} 