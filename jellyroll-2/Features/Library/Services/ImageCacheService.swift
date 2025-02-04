import Foundation
import SwiftUI
import OSLog

/// Represents errors that can occur during image caching operations
enum ImageCacheError: LocalizedError {
    case invalidImage
    case cacheFull
    case noServerConfig
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .cacheFull:
            return "Image cache is full"
        case .noServerConfig:
            return "No server configuration found"
        }
    }
}

actor ImageCacheService {
    static let shared = ImageCacheService()
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "ImageCache")
    private let authService = AuthenticationService.shared
    
    /// Maximum number of images to keep in memory per server
    private let maxCacheSize = 100
    
    /// Maximum time to keep images in cache (24 hours)
    private let maxCacheAge: TimeInterval = 24 * 60 * 60
    
    /// Cache instances for each server
    private var serverCaches: [String: NSCache<NSString, CachedImage>] = [:]
    private var serverCacheTimestamps: [String: [String: Date]] = [:]
    
    private init() {
        // Set up periodic cache cleanup
        Task {
            while true {
                await cleanupExpiredCache()
                try? await Task.sleep(nanoseconds: UInt64(3600 * 1_000_000_000)) // Clean every hour
            }
        }
        
        // Listen for server changes
        NotificationCenter.default.addObserver(
            forName: .serverDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleServerChange()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Handles server changes by ensuring the new server has a cache
    private func handleServerChange() async {
        do {
            guard let config = try authService.getServerConfiguration() else {
                return
            }
            let serverURL = config.baseURLString
            
            // Initialize cache for new server if needed
            if serverCaches[serverURL] == nil {
                let cache = NSCache<NSString, CachedImage>()
                cache.countLimit = maxCacheSize
                serverCaches[serverURL] = cache
                serverCacheTimestamps[serverURL] = [:]
            }
        } catch {
            logger.error("Failed to handle server change: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves an image from the cache if available
    func image(for key: String) async -> Image? {
        do {
            guard let config = try authService.getServerConfiguration() else {
                return nil
            }
            let serverURL = config.baseURLString
            
            guard let cache = serverCaches[serverURL],
                  let timestamps = serverCacheTimestamps[serverURL],
                  let cachedImage = cache.object(forKey: key as NSString),
                  let timestamp = timestamps[key],
                  Date().timeIntervalSince(timestamp) < maxCacheAge else {
                // Remove expired image if found
                if let timestamps = serverCacheTimestamps[serverURL], timestamps[key] != nil {
                    serverCaches[serverURL]?.removeObject(forKey: key as NSString)
                    serverCacheTimestamps[serverURL]?.removeValue(forKey: key)
                }
                return nil
            }
            
            // Update timestamp on access
            serverCacheTimestamps[serverURL]?[key] = Date()
            return cachedImage.image
        } catch {
            logger.error("Failed to retrieve image from cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Caches an image with error handling
    func cache(image: Image, for key: String) async throws {
        guard let config = try authService.getServerConfiguration() else {
            throw ImageCacheError.noServerConfig
        }
        let serverURL = config.baseURLString
        
        // Initialize cache for server if needed
        if serverCaches[serverURL] == nil {
            let cache = NSCache<NSString, CachedImage>()
            cache.countLimit = maxCacheSize
            serverCaches[serverURL] = cache
            serverCacheTimestamps[serverURL] = [:]
        }
        
        guard let cache = serverCaches[serverURL],
              cache.countLimit < maxCacheSize else {
            throw ImageCacheError.cacheFull
        }
        
        let cachedImage = CachedImage(image: image)
        cache.setObject(cachedImage, forKey: key as NSString)
        serverCacheTimestamps[serverURL]?[key] = Date()
        
        logger.debug("Cached image for key: \(key) on server: \(serverURL)")
    }
    
    /// Removes expired items from all server caches
    private func cleanupExpiredCache() {
        let now = Date()
        
        for (serverURL, timestamps) in serverCacheTimestamps {
            let expiredKeys = timestamps.filter { now.timeIntervalSince($0.value) >= maxCacheAge }.map { $0.key }
            
            for key in expiredKeys {
                serverCaches[serverURL]?.removeObject(forKey: key as NSString)
                serverCacheTimestamps[serverURL]?.removeValue(forKey: key)
            }
            
            if !expiredKeys.isEmpty {
                logger.debug("Cleaned up \(expiredKeys.count) expired items from cache for server: \(serverURL)")
            }
        }
    }
    
    /// Clears the cache for a specific server
    func clearCache(for serverURL: String? = nil) {
        if let serverURL = serverURL {
            serverCaches[serverURL]?.removeAllObjects()
            serverCacheTimestamps[serverURL]?.removeAll()
            logger.debug("Cleared image cache for server: \(serverURL)")
        } else {
            serverCaches.removeAll()
            serverCacheTimestamps.removeAll()
            logger.debug("Cleared all image caches")
        }
    }
}

private final class CachedImage {
    let image: Image
    
    init(image: Image) {
        self.image = image
    }
} 