import SwiftUI

/// System for optimizing content density and presentation
struct ContentDensitySystem {
    // MARK: - Adaptive Grid
    
    struct AdaptiveGrid {
        struct Configuration {
            let minItemWidth: CGFloat
            let maxItemWidth: CGFloat
            let spacing: CGFloat
            let padding: EdgeInsets
            
            static let `default` = Configuration(
                minItemWidth: 150,
                maxItemWidth: 300,
                spacing: 16,
                padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            )
        }
        
        struct Layout {
            let columns: Int
            let itemWidth: CGFloat
            let spacing: CGFloat
            
            static func calculate(
                for size: CGSize,
                configuration: Configuration
            ) -> Layout {
                let availableWidth = size.width - configuration.padding.leading - configuration.padding.trailing
                let spacing = configuration.spacing
                
                let maxColumns = max(1, Int(availableWidth / configuration.minItemWidth))
                
                let optimalColumns = maxColumns
                let totalSpacing = spacing * CGFloat(optimalColumns - 1)
                let itemWidth = (availableWidth - totalSpacing) / CGFloat(optimalColumns)
                
                return Layout(
                    columns: optimalColumns,
                    itemWidth: itemWidth,
                    spacing: spacing
                )
            }
        }
    }
    
    // MARK: - Collapsible Sections
    
    struct CollapsibleSection {
        struct Configuration {
            let animation: Animation
            let headerHeight: CGFloat
            let spacing: CGFloat
            
            static let `default` = Configuration(
                animation: .spring(response: 0.3, dampingFraction: 0.7),
                headerHeight: 44,
                spacing: 8
            )
        }
        
        struct State {
            var isExpanded: Bool
            var contentHeight: CGFloat?
        }
    }
    
    // MARK: - Progressive Loading
    
    struct ProgressiveLoading {
        struct Configuration {
            let batchSize: Int
            let loadThreshold: CGFloat
            let placeholderCount: Int
            
            static let `default` = Configuration(
                batchSize: 20,
                loadThreshold: 0.8,
                placeholderCount: 5
            )
        }
        
        struct State {
            var loadedCount: Int
            var isLoading: Bool
            var hasMoreContent: Bool
        }
    }
    
    // MARK: - Content Prioritization
    
    struct ContentPriority {
        enum Level: Int, Comparable {
            case critical = 0
            case high = 1
            case medium = 2
            case low = 3
            
            static func < (lhs: Level, rhs: Level) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }
        
        struct Configuration {
            let minPriorityLevel: Level
            let maxVisibleItems: Int
            
            static let `default` = Configuration(
                minPriorityLevel: .medium,
                maxVisibleItems: 10
            )
        }
    }
    
    // MARK: - Adaptive Item Sizing
    
    struct AdaptiveItem {
        struct Configuration {
            let aspectRatio: CGFloat?
            let minHeight: CGFloat
            let maxHeight: CGFloat
            
            static let `default` = Configuration(
                aspectRatio: nil,
                minHeight: 44,
                maxHeight: 200
            )
        }
        
        static func calculateHeight(
            for width: CGFloat,
            configuration: Configuration
        ) -> CGFloat {
            if let aspectRatio = configuration.aspectRatio {
                let height = width / aspectRatio
                return min(max(height, configuration.minHeight), configuration.maxHeight)
            }
            return configuration.minHeight
        }
    }
    
    // MARK: - Content Preview
    
    struct ContentPreview {
        enum Style {
            case thumbnail
            case card
            case list
            case grid
        }
        
        struct Configuration {
            let style: Style
            let showMetadata: Bool
            let maxLines: Int
            
            static let `default` = Configuration(
                style: .card,
                showMetadata: true,
                maxLines: 2
            )
        }
    }
}

// MARK: - View Modifiers

struct AdaptiveGridModifier<T: View>: ViewModifier {
    let configuration: ContentDensitySystem.AdaptiveGrid.Configuration
    let content: (CGFloat) -> T
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let layout = ContentDensitySystem.AdaptiveGrid.Layout.calculate(
                for: geometry.size,
                configuration: configuration
            )
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(layout.itemWidth), spacing: layout.spacing),
                    count: layout.columns
                ),
                spacing: layout.spacing
            ) {
                self.content(layout.itemWidth)
            }
            .padding(configuration.padding)
        }
    }
}

struct CollapsibleSectionModifier: ViewModifier {
    let configuration: ContentDensitySystem.CollapsibleSection.Configuration
    @Binding var state: ContentDensitySystem.CollapsibleSection.State
    let header: () -> any View
    
    func body(content: Content) -> some View {
        VStack(spacing: configuration.spacing) {
            Button(action: {
                withAnimation(configuration.animation) {
                    state.isExpanded.toggle()
                }
            }) {
                AnyView(header())
                    .frame(height: configuration.headerHeight)
            }
            
            if state.isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct ProgressiveLoadingModifier: ViewModifier {
    let configuration: ContentDensitySystem.ProgressiveLoading.Configuration
    @Binding var state: ContentDensitySystem.ProgressiveLoading.State
    let onLoadMore: () -> Void
    
    func body(content: Content) -> some View {
        VStack {
            content
            
            if state.hasMoreContent {
                ProgressView()
                    .onAppear {
                        if !state.isLoading {
                            state.isLoading = true
                            onLoadMore()
                        }
                    }
            }
        }
    }
}

struct ContentPriorityModifier: ViewModifier {
    let configuration: ContentDensitySystem.ContentPriority.Configuration
    let priority: ContentDensitySystem.ContentPriority.Level
    
    func body(content: Content) -> some View {
        content
            .opacity(priority >= configuration.minPriorityLevel ? 1 : 0)
            .accessibility(hidden: priority < configuration.minPriorityLevel)
    }
}

struct AdaptiveItemModifier: ViewModifier {
    let configuration: ContentDensitySystem.AdaptiveItem.Configuration
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(
                    height: ContentDensitySystem.AdaptiveItem.calculateHeight(
                        for: geometry.size.width,
                        configuration: configuration
                    )
                )
        }
    }
}

struct ContentPreviewModifier: ViewModifier {
    let configuration: ContentDensitySystem.ContentPreview.Configuration
    
    func body(content: Content) -> some View {
        Group {
            switch configuration.style {
            case .thumbnail:
                content
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .card:
                content
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
            case .list:
                content
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            case .grid:
                content
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(8)
            }
        }
        .lineLimit(configuration.maxLines)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies adaptive grid layout
    func adaptiveGrid<T: View>(
        configuration: ContentDensitySystem.AdaptiveGrid.Configuration = .default,
        @ViewBuilder content: @escaping (CGFloat) -> T
    ) -> some View {
        modifier(AdaptiveGridModifier(configuration: configuration, content: content))
    }
    
    /// Makes a section collapsible
    func collapsibleSection<Header: View>(
        configuration: ContentDensitySystem.CollapsibleSection.Configuration = .default,
        state: Binding<ContentDensitySystem.CollapsibleSection.State>,
        @ViewBuilder header: @escaping () -> Header
    ) -> some View {
        modifier(CollapsibleSectionModifier(configuration: configuration, state: state, header: header))
    }
    
    /// Adds progressive loading
    func progressiveLoading(
        configuration: ContentDensitySystem.ProgressiveLoading.Configuration = .default,
        state: Binding<ContentDensitySystem.ProgressiveLoading.State>,
        onLoadMore: @escaping () -> Void
    ) -> some View {
        modifier(ProgressiveLoadingModifier(configuration: configuration, state: state, onLoadMore: onLoadMore))
    }
    
    /// Applies content priority
    func contentPriority(
        _ priority: ContentDensitySystem.ContentPriority.Level,
        configuration: ContentDensitySystem.ContentPriority.Configuration = .default
    ) -> some View {
        modifier(ContentPriorityModifier(configuration: configuration, priority: priority))
    }
    
    /// Makes item size adaptive
    func adaptiveItem(
        configuration: ContentDensitySystem.AdaptiveItem.Configuration = .default
    ) -> some View {
        modifier(AdaptiveItemModifier(configuration: configuration))
    }
    
    /// Applies content preview style
    func contentPreview(
        configuration: ContentDensitySystem.ContentPreview.Configuration = .default
    ) -> some View {
        modifier(ContentPreviewModifier(configuration: configuration))
    }
} 