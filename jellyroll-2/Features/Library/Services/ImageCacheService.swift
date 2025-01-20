import Foundation
import SwiftUI
import OSLog

/// Represents errors that can occur during image caching operations
enum ImageCacheError: LocalizedError {
    case invalidImage
    case cacheFull
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .cacheFull:
            return "Image cache is full"
        }
    }
}

actor ImageCacheService {
    static let shared = ImageCacheService()
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "ImageCache")
    
    /// Maximum number of images to keep in memory
    private let maxCacheSize = 100
    
    /// Maximum time to keep images in cache (24 hours)
    private let maxCacheAge: TimeInterval = 24 * 60 * 60
    
    private let cache: NSCache<NSString, CachedImage> = {
        let cache = NSCache<NSString, CachedImage>()
        cache.countLimit = 100 // Maximum number of images to keep in memory
        return cache
    }()
    
    private var cacheTimestamps: [String: Date] = [:]
    
    private init() {
        // Set up periodic cache cleanup
        Task {
            while true {
                await cleanupExpiredCache()
                try? await Task.sleep(nanoseconds: UInt64(3600 * 1_000_000_000)) // Clean every hour
            }
        }
    }
    
    /// Retrieves an image from the cache if available
    func image(for key: String) -> Image? {
        guard let cachedImage = cache.object(forKey: key as NSString),
              let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < maxCacheAge else {
            // Remove expired image if found
            if cacheTimestamps[key] != nil {
                cache.removeObject(forKey: key as NSString)
                cacheTimestamps.removeValue(forKey: key)
            }
            return nil
        }
        
        // Update timestamp on access
        cacheTimestamps[key] = Date()
        return cachedImage.image
    }
    
    /// Caches an image with error handling
    func cache(image: Image, for key: String) throws {
        guard cache.countLimit < maxCacheSize else {
            throw ImageCacheError.cacheFull
        }
        
        let cachedImage = CachedImage(image: image)
        cache.setObject(cachedImage, forKey: key as NSString)
        cacheTimestamps[key] = Date()
        
        logger.debug("Cached image for key: \(key)")
    }
    
    /// Removes expired items from the cache
    private func cleanupExpiredCache() {
        let now = Date()
        let expiredKeys = cacheTimestamps.filter { now.timeIntervalSince($0.value) >= maxCacheAge }.map { $0.key }
        
        for key in expiredKeys {
            cache.removeObject(forKey: key as NSString)
            cacheTimestamps.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            logger.debug("Cleaned up \(expiredKeys.count) expired items from cache")
        }
    }
    
    /// Clears the entire cache
    func clearCache() {
        cache.removeAllObjects()
        cacheTimestamps.removeAll()
        logger.debug("Cleared image cache")
    }
}

private final class CachedImage {
    let image: Image
    
    init(image: Image) {
        self.image = image
    }
} 