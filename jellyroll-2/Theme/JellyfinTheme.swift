import SwiftUI

enum JellyfinTheme {
    static let backgroundColor = Color(red: 0.05, green: 0.07, blue: 0.15) // Dark navy
    static let surfaceColor = Color(red: 0.07, green: 0.09, blue: 0.18) // Slightly lighter navy
    static let elevatedSurfaceColor = Color(red: 0.1, green: 0.12, blue: 0.22) // Even lighter navy for elevated surfaces
    
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.4, blue: 0.8), // Purple
            Color(red: 0.4, green: 0.5, blue: 0.9)  // Blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let textGradient = LinearGradient(
        colors: [.white, Color(white: 0.9)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let overlayGradient = LinearGradient(
        colors: [
            .clear,
            .clear,
            .clear,
            .black.opacity(0.5),
            .black.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    enum Text {
        static let primary = Color.white
        static let secondary = Color.gray
        static let tertiary = Color(white: 0.6)
    }
} 