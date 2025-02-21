import SwiftUI

/// Typography system that maintains hierarchy across all contexts and device sizes
struct TypographyStyles {
    // MARK: - Font Sizes with Dynamic Type Support
    
    /// Heading styles with Dynamic Type support
    struct Headings {
        static let h1 = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let h2 = Font.system(.title, design: .rounded).weight(.bold)
        static let h3 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let h4 = Font.system(.title3, design: .rounded).weight(.semibold)
    }
    
    /// Body text styles with optimal line height and spacing
    struct Body {
        static let large = Font.system(.body, design: .rounded).weight(.regular)
        static let medium = Font.system(.callout, design: .rounded).weight(.regular)
        static let small = Font.system(.subheadline, design: .rounded).weight(.regular)
        static let caption = Font.system(.caption, design: .rounded).weight(.regular)
    }
    
    /// Custom font scaling factors for different device sizes
    private struct ScaleFactors {
        static let compact: CGFloat = 0.9
        static let regular: CGFloat = 1.0
        static let large: CGFloat = 1.1
    }
    
    // MARK: - Utility Functions
    
    /// Scales typography based on device size
    /// - Parameters:
    ///   - font: The base font to scale
    ///   - size: The target device size category
    /// - Returns: A scaled font appropriate for the device size
    static func scaleFont(_ font: Font, for size: UIUserInterfaceSizeClass) -> Font {
        switch size {
        case .compact:
            return font.scale(by: ScaleFactors.compact)
        case .regular:
            return font.scale(by: ScaleFactors.regular)
        default:
            return font.scale(by: ScaleFactors.regular)
        }
    }
    
    /// Text style modifier that applies optimal line height and letter spacing
    struct OptimizedTextStyle: ViewModifier {
        let lineHeight: CGFloat
        let letterSpacing: CGFloat
        
        func body(content: Content) -> some View {
            content
                .lineSpacing(lineHeight)
                .kerning(letterSpacing)
        }
    }
}

// MARK: - Font Extensions

extension Font {
    func scale(by factor: CGFloat) -> Font {
        // Create a scaled font by modifying the base font size
        switch self {
        case .largeTitle:
            return .system(size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize * factor)
        case .title:
            return .system(size: UIFont.preferredFont(forTextStyle: .title1).pointSize * factor)
        case .title2:
            return .system(size: UIFont.preferredFont(forTextStyle: .title2).pointSize * factor)
        case .title3:
            return .system(size: UIFont.preferredFont(forTextStyle: .title3).pointSize * factor)
        case .headline:
            return .system(size: UIFont.preferredFont(forTextStyle: .headline).pointSize * factor)
        case .body:
            return .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize * factor)
        case .callout:
            return .system(size: UIFont.preferredFont(forTextStyle: .callout).pointSize * factor)
        case .subheadline:
            return .system(size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * factor)
        case .footnote:
            return .system(size: UIFont.preferredFont(forTextStyle: .footnote).pointSize * factor)
        case .caption:
            return .system(size: UIFont.preferredFont(forTextStyle: .caption1).pointSize * factor)
        case .caption2:
            return .system(size: UIFont.preferredFont(forTextStyle: .caption2).pointSize * factor)
        default:
            // For custom fonts or unknown cases, use body as base
            return .system(size: UIFont.preferredFont(forTextStyle: .body).pointSize * factor)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies optimized text styling with custom line height and letter spacing
    /// - Parameters:
    ///   - lineHeight: The desired line height
    ///   - letterSpacing: The desired letter spacing
    /// - Returns: A view with the applied text styling
    func optimizedTextStyle(lineHeight: CGFloat = 1.2, letterSpacing: CGFloat = 0.5) -> some View {
        modifier(TypographyStyles.OptimizedTextStyle(lineHeight: lineHeight, letterSpacing: letterSpacing))
    }
} 