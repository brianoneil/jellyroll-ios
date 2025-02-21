import SwiftUI
import UIKit

/// Manages layout configuration and standardized spacing
class LayoutManager: ObservableObject {
    // MARK: - Device Properties
    
    @Published private(set) var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @Published private(set) var horizontalSizeClass: UIUserInterfaceSizeClass = .compact
    @Published private(set) var verticalSizeClass: UIUserInterfaceSizeClass = .regular
    
    init() {
        // Start monitoring orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func orientationChanged() {
        orientation = UIDevice.current.orientation
    }
    
    func updateSizeClasses(horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) {
        horizontalSizeClass = horizontal
        verticalSizeClass = vertical
    }
    
    var isLandscape: Bool {
        orientation.isLandscape
    }
    
    var isPortrait: Bool {
        orientation.isPortrait
    }
    
    var isPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Spacing Scale
    
    /// 8-point grid system spacing scale
    struct Spacing {
        static let xxs: CGFloat = 4  // Half base unit
        static let xs: CGFloat = 8   // Base unit
        static let sm: CGFloat = 16  // 2x base
        static let md: CGFloat = 24  // 3x base
        static let lg: CGFloat = 32  // 4x base
        static let xl: CGFloat = 40  // 5x base
        static let xxl: CGFloat = 48 // 6x base
        
        /// Returns custom spacing based on grid multiplier
        static func custom(_ multiplier: CGFloat) -> CGFloat {
            return 8 * multiplier
        }
    }
    
    // MARK: - Touch Targets
    
    struct TouchTarget {
        /// Minimum touch target size (44x44 points)
        static let minimum: CGFloat = 44
        
        /// Recommended touch target sizes for different elements
        struct Size {
            static let small: CGFloat = 44    // Minimum size
            static let medium: CGFloat = 52   // Comfortable size
            static let large: CGFloat = 60    // Large, easily tappable
            
            /// Returns a CGSize with equal width and height
            static func square(_ size: CGFloat) -> CGSize {
                CGSize(width: size, height: size)
            }
        }
        
        /// Padding to ensure minimum touch target size
        static func padding(for size: CGFloat) -> CGFloat {
            max(0, (minimum - size) / 2)
        }
    }
    
    // MARK: - Adaptive Layout Grid
    
    struct Grid {
        /// Number of columns for different screen sizes
        static func columns(for width: CGFloat) -> Int {
            switch width {
            case ..<375: return 4  // iPhone SE, mini
            case ..<428: return 6  // iPhone regular, plus, max
            case ..<768: return 8  // Small tablets
            case ..<1024: return 12 // Regular tablets
            default: return 14      // Large tablets
            }
        }
        
        /// Returns the appropriate item width for a grid
        static func itemWidth(totalWidth: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
            let totalSpacing = spacing * CGFloat(columns - 1)
            let availableWidth = totalWidth - totalSpacing
            return floor(availableWidth / CGFloat(columns))
        }
    }
    
    // MARK: - Safe Area & Orientation
    
    struct SafeArea {
        /// Default edge insets for different contexts
        static let defaultInsets = EdgeInsets(
            top: Spacing.md,
            leading: Spacing.md,
            bottom: Spacing.md,
            trailing: Spacing.md
        )
        
        /// Adjusts insets based on device orientation
        static func insets(for orientation: UIDeviceOrientation) -> EdgeInsets {
            switch orientation {
            case .portrait, .portraitUpsideDown:
                return defaultInsets
            case .landscapeLeft, .landscapeRight:
                return EdgeInsets(
                    top: Spacing.sm,
                    leading: Spacing.lg,
                    bottom: Spacing.sm,
                    trailing: Spacing.lg
                )
            default:
                return defaultInsets
            }
        }
    }
    
    // MARK: - Dynamic Spacing
    
    struct DynamicSpacing {
        /// Calculates appropriate spacing based on container size
        static func adaptiveSpacing(for size: CGSize) -> CGFloat {
            let smallestDimension = min(size.width, size.height)
            switch smallestDimension {
            case ..<375: return Spacing.xs
            case ..<768: return Spacing.sm
            default: return Spacing.md
            }
        }
    }
}

// MARK: - View Modifier

/// View modifier to inject the LayoutManager into the environment
struct LayoutManagerModifier: ViewModifier {
    @StateObject private var layoutManager = LayoutManager()
    
    func body(content: Content) -> some View {
        content
            .environmentObject(layoutManager)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    layoutManager.updateSizeClasses(
                        horizontal: windowScene.traitCollection.horizontalSizeClass,
                        vertical: windowScene.traitCollection.verticalSizeClass
                    )
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Injects the LayoutManager into the environment
    func withLayoutManager() -> some View {
        modifier(LayoutManagerModifier())
    }
    
    /// Applies minimum touch target size to a view
    func minimumTouchTarget() -> some View {
        self.frame(
            minWidth: LayoutManager.TouchTarget.minimum,
            minHeight: LayoutManager.TouchTarget.minimum
        )
    }
    
    /// Applies safe area insets based on orientation
    func adaptiveSafeArea(_ orientation: UIDeviceOrientation) -> some View {
        self.padding(LayoutManager.SafeArea.insets(for: orientation))
    }
    
    /// Applies dynamic spacing based on container size
    func dynamicSpacing(_ size: CGSize) -> some View {
        self.padding(LayoutManager.DynamicSpacing.adaptiveSpacing(for: size))
    }
} 