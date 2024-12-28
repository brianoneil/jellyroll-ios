import SwiftUI
import OSLog

struct JellyfinImage: View {
    let itemId: String
    let imageType: ImageType
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let fallbackIcon: String
    
    @State private var cachedImage: Image?
    
    private let imageService = ImageService.shared
    private let imageCache = ImageCacheService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "JellyfinImage")
    
    init(
        itemId: String,
        imageType: ImageType = .primary,
        aspectRatio: CGFloat = 1.5,
        cornerRadius: CGFloat = 8,
        fallbackIcon: String = "photo"
    ) {
        self.itemId = itemId
        self.imageType = imageType
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.fallbackIcon = fallbackIcon
    }
    
    var body: some View {
        Group {
            if let image = cachedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let imageURL = try? imageService.getImageURL(itemId: itemId, imageType: imageType) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onAppear {
                                // Cache the loaded image
                                Task {
                                    await cacheImage(image)
                                }
                            }
                    case .failure:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task {
            await loadCachedImage()
        }
    }
    
    private var fallbackView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: fallbackIcon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
    
    private func cacheKey() -> String {
        "\(itemId)_\(imageType.queryValue)"
    }
    
    private func loadCachedImage() async {
        if let cached = await imageCache.image(for: cacheKey()) {
            cachedImage = cached
        }
    }
    
    private func cacheImage(_ uiImage: Image) async {
        await imageCache.cache(image: uiImage, for: cacheKey())
    }
} 