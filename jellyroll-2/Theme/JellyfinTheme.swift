import SwiftUI

enum JellyfinTheme {
    static let lightAccentGradient = LinearGradient(
        colors: [
            Color(red: 0.60, green: 0.95, blue: 0.75), // More saturated mint
            Color(red: 0.45, green: 0.75, blue: 0.98)  // More saturated blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkAccentGradient = LinearGradient(
        colors: [
            Color(red: 0.53, green: 0.35, blue: 0.83), // Jellyfin purple
            Color(red: 0.35, green: 0.53, blue: 0.93)  // Jellyfin blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func backgroundColor(for mode: ThemeMode) -> Color {
        switch mode {
        case .dark:
            return Color(red: 0.05, green: 0.07, blue: 0.15) // Dark navy
        case .light:
            return Color(red: 0.92, green: 0.97, blue: 0.95) // Soft mint/seafoam
        }
    }
    
    static func surfaceColor(for mode: ThemeMode) -> Color {
        switch mode {
        case .dark:
            return Color(red: 0.07, green: 0.09, blue: 0.18) // Slightly lighter navy
        case .light:
            return Color(red: 0.96, green: 0.98, blue: 0.99) // Very light blue-white
        }
    }
    
    static func elevatedSurfaceColor(for mode: ThemeMode) -> Color {
        switch mode {
        case .dark:
            return Color(red: 0.1, green: 0.12, blue: 0.22) // Even lighter navy
        case .light:
            return Color.white.opacity(0.9) // Translucent white
        }
    }
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.97, blue: 0.95), // Soft mint/seafoam
            Color(red: 0.90, green: 0.95, blue: 0.99)  // Soft light blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func textGradient(for mode: ThemeMode) -> LinearGradient {
        switch mode {
        case .dark:
            return LinearGradient(
                colors: [.white, Color(white: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .light:
            return LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.2, blue: 0.3),
                    Color(red: 0.3, green: 0.3, blue: 0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    static let overlayGradient = LinearGradient(
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
    
    enum Text {
        static func primary(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white
            case .light:
                return Color(red: 0.2, green: 0.2, blue: 0.3) // Dark blue-gray
            }
        }
        
        static func secondary(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white.opacity(0.9)
            case .light:
                return Color(red: 0.3, green: 0.3, blue: 0.4).opacity(0.8) // Lighter blue-gray
            }
        }
        
        static func tertiary(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white.opacity(0.6)
            case .light:
                return Color(red: 0.4, green: 0.4, blue: 0.5).opacity(0.6) // Even lighter blue-gray
            }
        }
        
        static func separator(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white.opacity(0.6)
            case .light:
                return Color(red: 0.4, green: 0.4, blue: 0.5).opacity(0.2) // Very light blue-gray
            }
        }
    }
    
    static func cardGradient(for mode: ThemeMode) -> LinearGradient {
        switch mode {
        case .light:
            return backgroundGradient
        case .dark:
            return LinearGradient(
                colors: [
                    elevatedSurfaceColor(for: mode),
                    elevatedSurfaceColor(for: mode).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
} 