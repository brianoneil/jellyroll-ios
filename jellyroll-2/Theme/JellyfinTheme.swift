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
}

struct BlackberryTheme: Theme {
    let backgroundColor = Color(hex: "11002D")      // Deep purple
    let surfaceColor = Color(hex: "581B49")        // Rich purple
    let elevatedSurfaceColor = Color(hex: "9F3B55") // Rose
    
    let accentColor = Color(hex: "D76E54")         // Coral
    let accentGradient = LinearGradient(
        colors: [
            Color(hex: "F7AF54"),                  // Warm orange
            Color(hex: "D76E54")                   // Coral
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let primaryTextColor: Color = .white
    let secondaryTextColor = Color.white.opacity(0.9)
    let tertiaryTextColor = Color.white.opacity(0.7)
    let separatorColor = Color.white.opacity(0.3)
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "11002D"),                  // Deep purple
            Color(hex: "581B49")                   // Rich purple
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
                Color(hex: "D76E54").opacity(0.95)  // Coral for depth
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Helper extension for hex color initialization
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 