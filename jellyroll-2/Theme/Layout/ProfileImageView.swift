import SwiftUI

/// A reusable view component for displaying profile images
struct ProfileImageView: View {
    let itemId: String
    let imageTag: String?
    let size: CGFloat
    let borderWidth: CGFloat
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(
        itemId: String,
        imageTag: String?,
        size: CGFloat = 90,
        borderWidth: CGFloat = 1
    ) {
        self.itemId = itemId
        self.imageTag = imageTag
        self.size = size
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        if imageTag != nil {
            // Profile image with preserved aspect ratio
            JellyfinImage(
                itemId: itemId,
                imageType: .primary,
                aspectRatio: 1,
                cornerRadius: 0,
                fallbackIcon: "person.circle.fill"
            )
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(themeManager.currentTheme.surfaceColor.opacity(0.2), lineWidth: borderWidth)
            )
        } else {
            // Fallback icon when no image is available
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(themeManager.currentTheme.accentGradient)
                .overlay(
                    Circle()
                        .stroke(themeManager.currentTheme.surfaceColor.opacity(0.2), lineWidth: borderWidth)
                )
        }
    }
}

/// A specialized view for displaying the user profile in the navigation bar
struct UserProfileView: View {
    let userId: String
    let userName: String
    let size: CGFloat
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(userId: String, userName: String, size: CGFloat = 28) {
        self.userId = userId
        self.userName = userName
        self.size = size
    }
    
    private var initial: String {
        userName.prefix(1).uppercased()
    }
    
    var body: some View {
        Circle()
            .fill(themeManager.currentTheme.accentGradient)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
            )
    }
} 