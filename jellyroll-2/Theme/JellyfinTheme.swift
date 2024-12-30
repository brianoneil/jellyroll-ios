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
            .clear,
            .clear,
            .clear,
            .black.opacity(0.3),
            .black.opacity(0.6)
        ],
        startPoint: .top,
        endPoint: .bottom
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
}

struct LightTheme: Theme {
    let backgroundColor = Color(red: 0.92, green: 0.97, blue: 0.95)
    let surfaceColor = Color(red: 0.96, green: 0.98, blue: 0.99)
    let elevatedSurfaceColor = Color.white.opacity(0.9)
    
    let accentColor = Color(red: 0.60, green: 0.95, blue: 0.75)
    let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.60, green: 0.95, blue: 0.75),
            Color(red: 0.45, green: 0.75, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let primaryTextColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let secondaryTextColor = Color(red: 0.3, green: 0.3, blue: 0.4).opacity(0.8)
    let tertiaryTextColor = Color(red: 0.4, green: 0.4, blue: 0.5).opacity(0.6)
    let separatorColor = Color(red: 0.4, green: 0.4, blue: 0.5).opacity(0.2)
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.97, blue: 0.95),
            Color(red: 0.90, green: 0.95, blue: 0.99)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let textGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.2, blue: 0.3),
            Color(red: 0.3, green: 0.3, blue: 0.4)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    let overlayGradient = LinearGradient(
        colors: [
            .clear,
            .clear,
            .clear,
            .black.opacity(0.3),
            .black.opacity(0.6)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var cardGradient: LinearGradient {
        backgroundGradient
    }
} 