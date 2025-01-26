import SwiftUI
import OSLog

/// A view that displays images from Jellyfin with caching and fallback support
struct JellyfinImage: View {
    let itemId: String
    let imageType: ImageType
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let fallbackIcon: String
    let blurHash: String?
    
    @State private var cachedImage: Image?
    @State private var blurHashImage: Image?
    @State private var loadingState: ImageLoadingState = .loading
    
    @EnvironmentObject private var themeManager: ThemeManager
    private let imageService = ImageService.shared
    private let imageCache = ImageCacheService.shared
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "JellyfinImage")
    
    init(
        itemId: String,
        imageType: ImageType = .primary,
        aspectRatio: CGFloat = 1.5,
        cornerRadius: CGFloat = 8,
        fallbackIcon: String = "photo",
        blurHash: String? = nil
    ) {
        self.itemId = itemId
        self.imageType = imageType
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.fallbackIcon = fallbackIcon
        self.blurHash = blurHash
        
        // Generate BlurHash image at init time for better performance
        if let hash = blurHash {
            if let image = Image(blurHash: hash, size: CGSize(width: 32, height: 32)) {
                self._blurHashImage = State(initialValue: image)
            }
        }
    }
    
    var body: some View {
        Group {
            if themeManager.debugImageLoading {
                // In debug mode, only show blur hash or fallback
                baseView {
                    placeholderContent
                }
            } else if let image = cachedImage {
                // Show cached image if available
                baseView {
                    configureImage(image)
                }
            } else {
                // Handle different loading states
                switch loadingState {
                case .loading:
                    baseView {
                        placeholderContent
                    }
                case .loaded(let imageURL):
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            baseView {
                                placeholderContent
                            }
                        case .success(let image):
                            baseView {
                                configureImage(image)
                                    .onAppear {
                                        Task {
                                            try? await cacheImage(image)
                                        }
                                    }
                            }
                        case .failure:
                            baseView {
                                fallbackContent
                            }
                        @unknown default:
                            baseView {
                                fallbackContent
                            }
                        }
                    }
                case .failed(let error):
                    baseView {
                        fallbackContent
                            .overlay(
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(.black.opacity(0.6))
                                    .cornerRadius(4)
                            )
                    }
                case .notFound:
                    baseView {
                        fallbackContent
                    }
                }
            }
        }
        .task {
            if !themeManager.debugImageLoading {
                await loadImage()
            }
        }
    }
    
    /// Base view that provides consistent layout and styling
    private func baseView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .aspectRatio(aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Configures an image with consistent modifiers
    private func configureImage(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(aspectRatio, contentMode: .fill)
            .clipped()
    }
    
    /// Content shown while loading
    private var placeholderContent: some View {
        Group {
            if let blurImage = blurHashImage {
                configureImage(blurImage)
            } else {
                fallbackContent
            }
        }
    }
    
    /// Content shown when image loading fails
    private var fallbackContent: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: fallbackIcon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
    
    /// Generates a unique cache key for the image
    private func cacheKey() -> String {
        "\(itemId)_\(imageType.queryValue)"
    }
    
    /// Attempts to load the image, first from cache then from network
    private func loadImage() async {
        // First try to load from cache
        if let cached = await imageCache.image(for: cacheKey()) {
            cachedImage = cached
            return
        }
        
        // If not in cache, load from network
        loadingState = await imageService.loadImage(itemId: itemId, imageType: imageType)
    }
    
    /// Caches the successfully loaded image
    private func cacheImage(_ image: Image) async throws {
        try await imageCache.cache(image: image, for: cacheKey())
    }
} 