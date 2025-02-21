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
    
    // Typography
    var h1Style: Font { get }
    var h2Style: Font { get }
    var h3Style: Font { get }
    var h4Style: Font { get }
    var bodyLargeStyle: Font { get }
    var bodyMediumStyle: Font { get }
    var bodySmallStyle: Font { get }
    var captionStyle: Font { get }
    
    // Typography Utility Functions
    func scaledFont(_ font: Font, for sizeClass: UIUserInterfaceSizeClass) -> Font
    
    // Semantic Colors
    var activeColor: Color { get }
    var inactiveColor: Color { get }
    var errorColor: Color { get }
    var successColor: Color { get }
    var warningColor: Color { get }
    var selectedColor: Color { get }
    var focusedColor: Color { get }
    var disabledColor: Color { get }
    
    // Color Adaptation Methods
    func adaptColor(_ color: Color, for condition: ColorSystem.LightingCondition) -> Color
    func ensureContrast(textColor: Color, on backgroundColor: Color) -> Color
    func adjustForTimeOfDay(_ color: Color, hour: Int) -> Color
}

extension Theme {
    // Default implementation of typography styles
    var h1Style: Font { TypographyStyles.Headings.h1 }
    var h2Style: Font { TypographyStyles.Headings.h2 }
    var h3Style: Font { TypographyStyles.Headings.h3 }
    var h4Style: Font { TypographyStyles.Headings.h4 }
    var bodyLargeStyle: Font { TypographyStyles.Body.large }
    var bodyMediumStyle: Font { TypographyStyles.Body.medium }
    var bodySmallStyle: Font { TypographyStyles.Body.small }
    var captionStyle: Font { TypographyStyles.Body.caption }
    
    func scaledFont(_ font: Font, for sizeClass: UIUserInterfaceSizeClass) -> Font {
        TypographyStyles.scaleFont(font, for: sizeClass)
    }
    
    // Default implementations for semantic colors
    var activeColor: Color { ColorSystem.SemanticColors.active }
    var inactiveColor: Color { ColorSystem.SemanticColors.inactive }
    var errorColor: Color { ColorSystem.SemanticColors.error }
    var successColor: Color { ColorSystem.SemanticColors.success }
    var warningColor: Color { ColorSystem.SemanticColors.warning }
    var selectedColor: Color { ColorSystem.SemanticColors.selected }
    var focusedColor: Color { ColorSystem.SemanticColors.focused }
    var disabledColor: Color { ColorSystem.SemanticColors.disabled }
    
    // Default implementations for color adaptation methods
    func adaptColor(_ color: Color, for condition: ColorSystem.LightingCondition) -> Color {
        ColorSystem.LightingAdaptation.adapt(color, for: condition)
    }
    
    func ensureContrast(textColor: Color, on backgroundColor: Color) -> Color {
        ColorSystem.ContrastUtilities.ensureTextContrast(textColor: textColor, on: backgroundColor)
    }
    
    func adjustForTimeOfDay(_ color: Color, hour: Int) -> Color {
        ColorSystem.TimeBasedAdaptation.adjustForTimeOfDay(color, hour: hour)
    }
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