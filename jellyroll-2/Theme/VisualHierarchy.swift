import SwiftUI

/// Visual hierarchy system for optimizing content presentation
struct VisualHierarchy {
    // MARK: - Progressive Disclosure
    
    struct ProgressiveDisclosure {
        /// Levels of content detail
        enum DetailLevel {
            case preview
            case summary
            case full
        }
        
        /// Returns the appropriate content configuration for a detail level
        static func contentConfig(for level: DetailLevel) -> ContentConfiguration {
            switch level {
            case .preview:
                return ContentConfiguration(
                    maxLines: 2,
                    showMetadata: false,
                    emphasis: .low
                )
            case .summary:
                return ContentConfiguration(
                    maxLines: 4,
                    showMetadata: true,
                    emphasis: .medium
                )
            case .full:
                return ContentConfiguration(
                    maxLines: nil,
                    showMetadata: true,
                    emphasis: .high
                )
            }
        }
    }
    
    // MARK: - Emphasis Scale
    
    struct Emphasis {
        enum Level: CGFloat {
            case low = 0.8
            case medium = 1.0
            case high = 1.2
            
            var scale: CGFloat { rawValue }
        }
        
        /// Applies emphasis scaling to a view
        static func scale(_ level: Level) -> CGFloat {
            level.scale
        }
    }
    
    // MARK: - Focus States
    
    struct FocusState {
        /// Visual properties for different focus states
        static func properties(isFocused: Bool) -> FocusProperties {
            isFocused ? .focused : .unfocused
        }
        
        struct FocusProperties {
            let scale: CGFloat
            let opacity: Double
            let shadow: Shadow
            
            static let focused = FocusProperties(
                scale: 1.05,
                opacity: 1.0,
                shadow: Shadow(color: .black.opacity(0.2), radius: 8, offset: .zero)
            )
            
            static let unfocused = FocusProperties(
                scale: 1.0,
                opacity: 0.9,
                shadow: Shadow(color: .clear, radius: 0, offset: .zero)
            )
        }
    }
    
    // MARK: - Visual Grouping
    
    struct VisualGroup {
        /// Properties for visual grouping of content
        static let properties = GroupProperties(
            backgroundColor: Color.secondary.opacity(0.1),
            cornerRadius: 12,
            padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
            spacing: 8
        )
    }
    
    // MARK: - Depth System
    
    struct Depth {
        enum Level: Int, CaseIterable {
            case base = 0
            case raised
            case floating
            case modal
            
            var elevation: Double {
                Double(rawValue) * 4
            }
            
            var shadow: Shadow {
                Shadow(
                    color: .black.opacity(0.1 + (0.05 * Double(rawValue))),
                    radius: elevation,
                    offset: CGSize(width: 0, height: elevation / 2)
                )
            }
        }
    }
    
    // MARK: - Content Prominence
    
    struct Prominence {
        enum Level {
            case primary
            case secondary
            case tertiary
            
            var scale: CGFloat {
                switch self {
                case .primary: return 1.1
                case .secondary: return 1.0
                case .tertiary: return 0.9
                }
            }
            
            var opacity: Double {
                switch self {
                case .primary: return 1.0
                case .secondary: return 0.8
                case .tertiary: return 0.6
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct ContentConfiguration {
    let maxLines: Int?
    let showMetadata: Bool
    let emphasis: VisualHierarchy.Emphasis.Level
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let offset: CGSize
}

struct GroupProperties {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let spacing: CGFloat
}

// MARK: - View Extensions

extension View {
    /// Applies progressive disclosure configuration
    func progressiveDisclosure(_ level: VisualHierarchy.ProgressiveDisclosure.DetailLevel) -> some View {
        let config = VisualHierarchy.ProgressiveDisclosure.contentConfig(for: level)
        return self
            .lineLimit(config.maxLines)
            .scaleEffect(config.emphasis.scale)
    }
    
    /// Applies focus state properties
    func focusState(isFocused: Bool) -> some View {
        let props = VisualHierarchy.FocusState.properties(isFocused: isFocused)
        return self
            .scaleEffect(props.scale)
            .opacity(props.opacity)
            .shadow(
                color: props.shadow.color,
                radius: props.shadow.radius,
                x: props.shadow.offset.width,
                y: props.shadow.offset.height
            )
    }
    
    /// Applies visual grouping
    func visualGroup() -> some View {
        let props = VisualHierarchy.VisualGroup.properties
        return self
            .padding(props.padding)
            .background(props.backgroundColor)
            .cornerRadius(props.cornerRadius)
    }
    
    /// Applies depth level
    func depth(_ level: VisualHierarchy.Depth.Level) -> some View {
        let shadow = level.shadow
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.offset.width,
            y: shadow.offset.height
        )
    }
    
    /// Applies content prominence
    func prominence(_ level: VisualHierarchy.Prominence.Level) -> some View {
        self
            .scaleEffect(level.scale)
            .opacity(level.opacity)
    }
} 