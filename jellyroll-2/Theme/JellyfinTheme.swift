import SwiftUI

protocol Theme {
    // Colors
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var elevatedSurfaceColor: Color { get }
    var accentColor: Color { get }
    var accentGradient: LinearGradient { get }
    
    // Text Colors
    var primaryTextColor: Color { get }
    var secondaryTextColor: Color { get }
    var tertiaryTextColor: Color { get }
    var separatorColor: Color { get }
    
    // Icon Colors
    var iconColor: Color { get }
    
    // Gradients
    var backgroundGradient: LinearGradient { get }
    var textGradient: LinearGradient { get }
    var overlayGradient: LinearGradient { get }
    var cardGradient: LinearGradient { get }
}

struct DarkTheme: Theme {
    let backgroundColor = Color(red: 0.05, green: 0.07, blue: 0.15)
    let surfaceColor = Color(red: 0.07, green: 0.09, blue: 0.18)
    let elevatedSurfaceColor = Color(red: 0.1, green: 0.12, blue: 0.22)
    
    let accentColor = Color(red: 0.53, green: 0.35, blue: 0.83) // Jellyfin purple
    let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.53, green: 0.35, blue: 0.83), // Jellyfin purple
            Color(red: 0.35, green: 0.53, blue: 0.93)  // Jellyfin blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let primaryTextColor: Color = .white
    let secondaryTextColor = Color.white.opacity(0.9)
    let tertiaryTextColor = Color.white.opacity(0.6)
    let separatorColor = Color.white.opacity(0.6)
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.07, blue: 0.15),
            Color(red: 0.07, green: 0.09, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let textGradient = LinearGradient(
        colors: [.white, Color(white: 0.9)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let overlayGradient = LinearGradient(
        colors: [
            .black.opacity(0.7),
            .black.opacity(0.5),
            .black.opacity(0.3),
            .black.opacity(0.1),
            .clear
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                elevatedSurfaceColor,
                elevatedSurfaceColor.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    let iconColor = Color.white.opacity(0.9)
}

struct LightTheme: Theme {
    let backgroundColor = Color(red: 0.45, green: 0.48, blue: 0.58)    // Very light navy base
    let surfaceColor = Color(red: 0.48, green: 0.51, blue: 0.62)      // Lighter surface
    let elevatedSurfaceColor = Color(red: 0.51, green: 0.54, blue: 0.66)
    
    let accentColor = Color(red: 1.00, green: 0.80, blue: 0.40)       // Bright sunny orange
    let accentGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.80, blue: 0.40),                // Bright sunny orange
            Color(red: 1.00, green: 0.60, blue: 0.50)                 // Light coral
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let primaryTextColor: Color = .white
    let secondaryTextColor = Color.white
    let tertiaryTextColor = Color.white.opacity(0.9)
    let separatorColor = Color.white.opacity(0.3)
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.45, green: 0.48, blue: 0.58),                // Very light navy
            Color(red: 0.48, green: 0.51, blue: 0.62)                 // Lighter navy
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let textGradient = LinearGradient(
        colors: [.white, .white],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let overlayGradient = LinearGradient(
        colors: [
            .black.opacity(0.7),
            .black.opacity(0.5),
            .black.opacity(0.3),
            .black.opacity(0.1),
            .clear
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                elevatedSurfaceColor,
                elevatedSurfaceColor.opacity(0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    let iconColor = Color.white.opacity(0.9)
} 