import SwiftUI

enum JellyfinTheme {
    static func backgroundColor(for mode: ThemeMode) -> Color {
        switch mode {
        case .dark:
            return Color(red: 0.05, green: 0.07, blue: 0.15) // Dark navy
        case .light:
            return Color(red: 0.95, green: 0.95, blue: 0.97) // Light gray
        }
    }
    
    static func surfaceColor(for mode: ThemeMode) -> Color {
        switch mode {
        case .dark:
            return Color(red: 0.07, green: 0.09, blue: 0.18) // Slightly lighter navy
        case .light:
            return Color.white
        }
    }
    
    static func elevatedSurfaceColor(for mode: ThemeMode) -> Color {
        switch mode {
        case .dark:
            return Color(red: 0.1, green: 0.12, blue: 0.22) // Even lighter navy
        case .light:
            return Color(red: 0.98, green: 0.98, blue: 0.98) // Very light gray
        }
    }
    
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.4, blue: 0.8), // Purple
            Color(red: 0.4, green: 0.5, blue: 0.9)  // Blue
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
                colors: [.black, Color(white: 0.2)],
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
            .black.opacity(0.5),
            .black.opacity(0.8)
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
                return .black
            }
        }
        
        static func secondary(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white.opacity(0.9)
            case .light:
                return .black.opacity(0.7)
            }
        }
        
        static func tertiary(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white.opacity(0.6)
            case .light:
                return .black.opacity(0.5)
            }
        }
        
        static func separator(for mode: ThemeMode) -> Color {
            switch mode {
            case .dark:
                return .white.opacity(0.6)
            case .light:
                return .black.opacity(0.2)
            }
        }
    }
} 