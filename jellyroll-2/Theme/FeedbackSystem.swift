import SwiftUI

/// System for providing sophisticated visual feedback
struct FeedbackSystem {
    // MARK: - Loading States
    
    struct LoadingState {
        enum Style {
            case spinner
            case progress
            case shimmer
            case pulse
        }
        
        struct Configuration {
            let style: Style
            let tint: Color
            let size: CGFloat
            let message: String?
            
            static let `default` = Configuration(
                style: .spinner,
                tint: .accentColor,
                size: 24,
                message: nil
            )
        }
    }
    
    // MARK: - State Transitions
    
    struct StateTransition {
        enum State {
            case idle
            case loading
            case success
            case error
            
            var animation: Animation {
                switch self {
                case .idle: return .linear
                case .loading: return .linear.repeatForever()
                case .success: return .spring(response: 0.3, dampingFraction: 0.7)
                case .error: return .spring(response: 0.3, dampingFraction: 0.7)
                }
            }
            
            var scale: CGFloat {
                switch self {
                case .idle: return 1.0
                case .loading: return 0.95
                case .success: return 1.1
                case .error: return 1.0
                }
            }
        }
    }
    
    // MARK: - Micro-interactions
    
    struct MicroInteraction {
        enum Style {
            case bounce
            case shake
            case pulse
            case wave
        }
        
        static func animation(for style: Style) -> Animation {
            switch style {
            case .bounce:
                return .spring(response: 0.3, dampingFraction: 0.6)
            case .shake:
                return .spring(response: 0.2, dampingFraction: 0.2)
            case .pulse:
                return .easeInOut(duration: 0.3)
            case .wave:
                return .easeInOut(duration: 0.5)
            }
        }
    }
    
    // MARK: - Progress Indicators
    
    struct ProgressIndicator {
        enum Style {
            case linear
            case circular
            case segmented
        }
        
        struct Configuration {
            let style: Style
            let tint: Color
            let showValue: Bool
            let animated: Bool
            
            static let `default` = Configuration(
                style: .linear,
                tint: .accentColor,
                showValue: true,
                animated: true
            )
        }
    }
    
    // MARK: - State Transitions
    
    struct TransitionAnimation {
        static let duration: Double = 0.3
        static let springDamping: Double = 0.7
        static let springResponse: Double = 0.3
        
        static var spring: Animation {
            .spring(response: springResponse, dampingFraction: springDamping)
        }
        
        static var easeInOut: Animation {
            .easeInOut(duration: duration)
        }
    }
    
    // MARK: - Success/Error Animations
    
    struct ResultAnimation {
        enum Style {
            case checkmark
            case cross
            case custom(String)
        }
        
        struct Configuration {
            let style: Style
            let color: Color
            let duration: Double
            let scale: CGFloat
            
            static let success = Configuration(
                style: .checkmark,
                color: .green,
                duration: 0.5,
                scale: 1.2
            )
            
            static let error = Configuration(
                style: .cross,
                color: .red,
                duration: 0.5,
                scale: 1.2
            )
        }
    }
}

// MARK: - View Modifiers

struct LoadingStateModifier: ViewModifier {
    let configuration: FeedbackSystem.LoadingState.Configuration
    @Binding var isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0.3 : 1.0)
            
            if isLoading {
                loadingIndicator
            }
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        switch configuration.style {
        case .spinner:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(configuration.tint)
                .scaleEffect(configuration.size / 24)
        case .progress:
            ProgressView(value: 0.5)
                .progressViewStyle(.linear)
                .tint(configuration.tint)
                .frame(width: configuration.size * 4)
        case .shimmer:
            ShimmerView()
                .frame(width: configuration.size * 4, height: configuration.size)
        case .pulse:
            Circle()
                .fill(configuration.tint)
                .frame(width: configuration.size, height: configuration.size)
                .modifier(PulseModifier())
        }
        
        if let message = configuration.message {
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

struct StateTransitionModifier: ViewModifier {
    let state: FeedbackSystem.StateTransition.State
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(state.scale)
            .animation(state.animation, value: state)
    }
}

struct MicroInteractionModifier: ViewModifier {
    let style: FeedbackSystem.MicroInteraction.Style
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        switch style {
        case .bounce:
            content.modifier(BounceModifier(isActive: $isActive))
        case .shake:
            content.modifier(ShakeModifier(isActive: $isActive))
        case .pulse:
            content.modifier(PulseModifier())
        case .wave:
            content.modifier(WaveModifier(isActive: $isActive))
        }
    }
}

struct ProgressIndicatorModifier: ViewModifier {
    let configuration: FeedbackSystem.ProgressIndicator.Configuration
    let progress: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            progressView
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        switch configuration.style {
        case .linear:
            LinearProgressView(
                progress: progress,
                configuration: configuration
            )
        case .circular:
            CircularProgressView(
                progress: progress,
                configuration: configuration
            )
        case .segmented:
            SegmentedProgressView(
                progress: progress,
                configuration: configuration
            )
        }
    }
}

struct ResultAnimationModifier: ViewModifier {
    let configuration: FeedbackSystem.ResultAnimation.Configuration
    @Binding var isShowing: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                resultView
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
            }
        }
    }
    
    @ViewBuilder
    private var resultView: some View {
        switch configuration.style {
        case .checkmark:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(configuration.color)
                .font(.system(size: 44))
                .scaleEffect(configuration.scale)
        case .cross:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(configuration.color)
                .font(.system(size: 44))
                .scaleEffect(configuration.scale)
        case .custom(let systemName):
            Image(systemName: systemName)
                .foregroundColor(configuration.color)
                .font(.system(size: 44))
                .scaleEffect(configuration.scale)
        }
    }
}

// MARK: - Supporting Views

struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .gray.opacity(0.3),
                        .gray.opacity(0.5),
                        .gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(Rectangle())
            .offset(x: isAnimating ? 200 : -200)
            .animation(
                Animation
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct LinearProgressView: View {
    let progress: Double
    let configuration: FeedbackSystem.ProgressIndicator.Configuration
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(configuration.tint.opacity(0.3))
                
                Rectangle()
                    .fill(configuration.tint)
                    .frame(width: geometry.size.width * progress)
                    .animation(.linear, value: progress)
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }
}

struct CircularProgressView: View {
    let progress: Double
    let configuration: FeedbackSystem.ProgressIndicator.Configuration
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(configuration.tint.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(configuration.tint, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            if configuration.showValue {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .bold()
            }
        }
    }
}

struct SegmentedProgressView: View {
    let progress: Double
    let configuration: FeedbackSystem.ProgressIndicator.Configuration
    private let segments = 5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<segments, id: \.self) { index in
                Rectangle()
                    .fill(index < Int(progress * Double(segments)) ? configuration.tint : configuration.tint.opacity(0.3))
                    .animation(.spring(), value: progress)
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }
}

// MARK: - Animation Modifiers

struct BounceModifier: ViewModifier {
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

struct ShakeModifier: ViewModifier {
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isActive ? 10 : 0)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.2)
                .repeatCount(3),
                value: isActive
            )
    }
}

struct PulseModifier: ViewModifier {
    @State private var isActive = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 0.5 : 1.0)
            .scaleEffect(isActive ? 1.2 : 1.0)
            .animation(
                .easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true),
                value: isActive
            )
            .onAppear {
                isActive = true
            }
    }
}

struct WaveModifier: ViewModifier {
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive ? 5 : -5))
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true),
                value: isActive
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies loading state with configuration
    func loadingState(isLoading: Binding<Bool>, configuration: FeedbackSystem.LoadingState.Configuration = .default) -> some View {
        modifier(LoadingStateModifier(configuration: configuration, isLoading: isLoading))
    }
    
    /// Applies state transition animation
    func stateTransition(_ state: FeedbackSystem.StateTransition.State) -> some View {
        modifier(StateTransitionModifier(state: state))
    }
    
    /// Applies micro-interaction animation
    func microInteraction(_ style: FeedbackSystem.MicroInteraction.Style, isActive: Binding<Bool>) -> some View {
        modifier(MicroInteractionModifier(style: style, isActive: isActive))
    }
    
    /// Applies progress indicator
    func progressIndicator(progress: Double, configuration: FeedbackSystem.ProgressIndicator.Configuration = .default) -> some View {
        modifier(ProgressIndicatorModifier(configuration: configuration, progress: progress))
    }
    
    /// Applies result animation
    func resultAnimation(configuration: FeedbackSystem.ResultAnimation.Configuration, isShowing: Binding<Bool>) -> some View {
        modifier(ResultAnimationModifier(configuration: configuration, isShowing: isShowing))
    }
} 