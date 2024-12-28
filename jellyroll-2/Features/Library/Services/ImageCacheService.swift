import Foundation
import SwiftUI
import OSLog

actor ImageCacheService {
    static let shared = ImageCacheService()
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "ImageCache")
    
    private let cache: NSCache<NSString, CachedImage> = {
        let cache = NSCache<NSString, CachedImage>()
        cache.countLimit = 100 // Maximum number of images to keep in memory
        return cache
    }()
    
    private init() {}
    
    func image(for key: String) -> Image? {
        guard let cachedImage = cache.object(forKey: key as NSString) else {
            return nil
        }
        return cachedImage.image
    }
    
    func cache(image: Image, for key: String) {
        let cachedImage = CachedImage(image: image)
        cache.setObject(cachedImage, forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        logger.debug("Cleared image cache")
    }
}

private final class CachedImage {
    let image: Image
    
    init(image: Image) {
        self.image = image
    }
} 