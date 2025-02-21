import SwiftUI

/// System for managing gestures and their animations
struct GestureSystem {
    // MARK: - Pull to Refresh
    
    struct PullToRefresh {
        struct Configuration {
            let threshold: CGFloat
            let tint: Color
            let message: String?
            let animation: Animation
            
            static let `default` = Configuration(
                threshold: 50,
                tint: .accentColor,
                message: "Pull to refresh",
                animation: .spring(response: 0.3, dampingFraction: 0.7)
            )
        }
        
        struct State {
            var offset: CGFloat = 0
            var isRefreshing = false
            
            var progress: CGFloat {
                min(1, abs(offset) / Configuration.default.threshold)
            }
        }
    }
    
    // MARK: - Swipe to Dismiss
    
    struct SwipeToDismiss {
        struct Configuration {
            let edge: Edge
            let threshold: CGFloat
            let background: Color
            let animation: Animation
            
            static let `default` = Configuration(
                edge: .trailing,
                threshold: 0.3,
                background: .red,
                animation: .spring(response: 0.3, dampingFraction: 0.7)
            )
        }
        
        struct State {
            var offset: CGSize = .zero
            var isDismissed = false
            
            var progress: CGFloat {
                switch Configuration.default.edge {
                case .leading, .trailing:
                    return abs(offset.width) / UIScreen.main.bounds.width
                case .top, .bottom:
                    return abs(offset.height) / UIScreen.main.bounds.height
                }
            }
        }
    }
    
    // MARK: - Pinch to Zoom
    
    struct PinchToZoom {
        struct Configuration {
            let minScale: CGFloat
            let maxScale: CGFloat
            let animation: Animation
            
            static let `default` = Configuration(
                minScale: 1.0,
                maxScale: 3.0,
                animation: .spring(response: 0.3, dampingFraction: 0.7)
            )
        }
        
        struct State {
            var scale: CGFloat = 1.0
            var offset: CGSize = .zero
            var anchor: UnitPoint = .center
        }
    }
    
    // MARK: - Swipe Actions
    
    struct SwipeAction {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void
        
        static func delete(action: @escaping () -> Void) -> SwipeAction {
            SwipeAction(
                title: "Delete",
                icon: "trash",
                color: .red,
                action: action
            )
        }
        
        static func archive(action: @escaping () -> Void) -> SwipeAction {
            SwipeAction(
                title: "Archive",
                icon: "archivebox",
                color: .blue,
                action: action
            )
        }
    }
    
    // MARK: - Scroll to Top
    
    struct ScrollToTop {
        struct Configuration {
            let threshold: CGFloat
            let animation: Animation
            
            static let `default` = Configuration(
                threshold: 50,
                animation: .spring(response: 0.3, dampingFraction: 0.7)
            )
        }
        
        struct State {
            var offset: CGFloat = 0
            var isVisible = false
        }
    }
}

// MARK: - View Modifiers

struct MovingContent<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

struct PullToRefreshModifier: ViewModifier {
    let configuration: GestureSystem.PullToRefresh.Configuration
    let onRefresh: () -> Void
    @State private var state = GestureSystem.PullToRefresh.State()
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .top) {
                    MovingContent {
                        content
                    }
                    
                    if state.offset < 0 {
                        RefreshIndicator(
                            configuration: configuration,
                            progress: state.progress,
                            isRefreshing: state.isRefreshing
                        )
                    }
                }
                .offset(y: state.isRefreshing ? configuration.threshold : 0)
                .animation(configuration.animation, value: state.isRefreshing)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        state.offset = value.translation.height
                        
                        if !state.isRefreshing && state.progress >= 1.0 {
                            state.isRefreshing = true
                            onRefresh()
                        }
                    }
                    .onEnded { _ in
                        state.offset = 0
                    }
            )
        }
    }
}

struct SwipeToDismissModifier: ViewModifier {
    let configuration: GestureSystem.SwipeToDismiss.Configuration
    let onDismiss: () -> Void
    @State private var state = GestureSystem.SwipeToDismiss.State()
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: configuration.edge == .leading || configuration.edge == .trailing ? state.offset.width : 0,
                y: configuration.edge == .top || configuration.edge == .bottom ? state.offset.height : 0
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        state.offset = value.translation
                    }
                    .onEnded { value in
                        if state.progress > configuration.threshold {
                            withAnimation(configuration.animation) {
                                switch configuration.edge {
                                case .leading:
                                    state.offset.width = -UIScreen.main.bounds.width
                                case .trailing:
                                    state.offset.width = UIScreen.main.bounds.width
                                case .top:
                                    state.offset.height = -UIScreen.main.bounds.height
                                case .bottom:
                                    state.offset.height = UIScreen.main.bounds.height
                                }
                                state.isDismissed = true
                            }
                            onDismiss()
                        } else {
                            withAnimation(configuration.animation) {
                                state.offset = .zero
                            }
                        }
                    }
            )
    }
}

struct PinchToZoomModifier: ViewModifier {
    let configuration: GestureSystem.PinchToZoom.Configuration
    @State private var state = GestureSystem.PinchToZoom.State()
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(state.scale, anchor: state.anchor)
            .offset(state.offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            state.scale = min(
                                max(value, configuration.minScale),
                                configuration.maxScale
                            )
                        }
                        .onEnded { _ in
                            withAnimation(configuration.animation) {
                                if state.scale < configuration.minScale {
                                    state.scale = configuration.minScale
                                } else if state.scale > configuration.maxScale {
                                    state.scale = configuration.maxScale
                                }
                            }
                        },
                    DragGesture()
                        .onChanged { value in
                            state.offset = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(configuration.animation) {
                                state.offset = .zero
                            }
                        }
                )
            )
    }
}

struct SwipeActionsModifier: ViewModifier {
    let leading: [GestureSystem.SwipeAction]
    let trailing: [GestureSystem.SwipeAction]
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(leading.indices, id: \.self) { index in
                    SwipeActionButton(action: leading[index])
                        .frame(width: 80)
                        .offset(x: offset < 0 ? 0 : offset)
                }
                
                Spacer()
                
                ForEach(trailing.indices, id: \.self) { index in
                    SwipeActionButton(action: trailing[index])
                        .frame(width: 80)
                        .offset(x: offset > 0 ? 0 : offset)
                }
            }
            
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation.width
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if abs(offset) > 80 {
                                    if offset > 0 && !leading.isEmpty {
                                        leading[0].action()
                                    } else if offset < 0 && !trailing.isEmpty {
                                        trailing[0].action()
                                    }
                                }
                                offset = 0
                            }
                        }
                )
        }
    }
}

struct ScrollToTopModifier: ViewModifier {
    let configuration: GestureSystem.ScrollToTop.Configuration
    @State private var state = GestureSystem.ScrollToTop.State()
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ScrollToTopButton(configuration: configuration, state: $state)
                    .opacity(state.isVisible ? 1 : 0)
                    .animation(.easeInOut, value: state.isVisible),
                alignment: .bottom
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        state.offset = value.translation.height
                        state.isVisible = state.offset < -configuration.threshold
                    }
            )
    }
}

// MARK: - Supporting Views

struct RefreshIndicator: View {
    let configuration: GestureSystem.PullToRefresh.Configuration
    let progress: CGFloat
    let isRefreshing: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(configuration.tint)
            } else {
                Image(systemName: "arrow.down")
                    .foregroundColor(configuration.tint)
                    .rotationEffect(.degrees(progress * 180))
            }
            
            if let message = configuration.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: configuration.threshold)
    }
}

struct SwipeActionButton: View {
    let action: GestureSystem.SwipeAction
    
    var body: some View {
        Button(action: action.action) {
            VStack {
                Image(systemName: action.icon)
                Text(action.title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(action.color)
        }
    }
}

struct ScrollToTopButton: View {
    let configuration: GestureSystem.ScrollToTop.Configuration
    @Binding var state: GestureSystem.ScrollToTop.State
    
    var body: some View {
        Button(action: {
            withAnimation(configuration.animation) {
                // Scroll to top logic would be implemented here
                state.isVisible = false
            }
        }) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title)
                .foregroundColor(.secondary)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding()
    }
}

// MARK: - View Extensions

extension View {
    /// Adds pull to refresh functionality
    func pullToRefresh(
        configuration: GestureSystem.PullToRefresh.Configuration = .default,
        onRefresh: @escaping () -> Void
    ) -> some View {
        modifier(PullToRefreshModifier(configuration: configuration, onRefresh: onRefresh))
    }
    
    /// Adds swipe to dismiss functionality
    func swipeToDismiss(
        configuration: GestureSystem.SwipeToDismiss.Configuration = .default,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(SwipeToDismissModifier(configuration: configuration, onDismiss: onDismiss))
    }
    
    /// Adds pinch to zoom functionality
    func pinchToZoom(
        configuration: GestureSystem.PinchToZoom.Configuration = .default
    ) -> some View {
        modifier(PinchToZoomModifier(configuration: configuration))
    }
    
    /// Adds swipe actions
    func swipeActions(
        leading: [GestureSystem.SwipeAction] = [],
        trailing: [GestureSystem.SwipeAction] = []
    ) -> some View {
        modifier(SwipeActionsModifier(leading: leading, trailing: trailing))
    }
    
    /// Adds scroll to top functionality
    func scrollToTop(
        configuration: GestureSystem.ScrollToTop.Configuration = .default
    ) -> some View {
        modifier(ScrollToTopModifier(configuration: configuration))
    }
} 