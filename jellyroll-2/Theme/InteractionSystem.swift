import SwiftUI
import CoreHaptics

/// System for managing touch interactions and feedback
class InteractionSystem: ObservableObject {
    // MARK: - Haptic Engine
    
    private var engine: CHHapticEngine?
    
    init() {
        setupHapticEngine()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine creation failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Haptic Patterns
    
    enum HapticPattern {
        case selection
        case success
        case warning
        case error
        case impact
        
        var pattern: CHHapticPattern? {
            do {
                switch self {
                case .selection:
                    return try CHHapticPattern(events: [
                        CHHapticEvent(eventType: .hapticTransient, parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                        ], relativeTime: 0)
                    ], parameters: [])
                    
                case .success:
                    return try CHHapticPattern(events: [
                        CHHapticEvent(eventType: .hapticTransient, parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                        ], relativeTime: 0)
                    ], parameters: [])
                    
                case .warning:
                    return try CHHapticPattern(events: [
                        CHHapticEvent(eventType: .hapticContinuous, parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                        ], relativeTime: 0, duration: 0.1)
                    ], parameters: [])
                    
                case .error:
                    return try CHHapticPattern(events: [
                        CHHapticEvent(eventType: .hapticTransient, parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                        ], relativeTime: 0),
                        CHHapticEvent(eventType: .hapticTransient, parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                        ], relativeTime: 0.1)
                    ], parameters: [])
                    
                case .impact:
                    return try CHHapticPattern(events: [
                        CHHapticEvent(eventType: .hapticTransient, parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                        ], relativeTime: 0)
                    ], parameters: [])
                }
            } catch {
                print("Failed to create haptic pattern: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    // MARK: - Gesture Recognition
    
    struct GestureZone {
        let size: CGSize
        let feedback: HapticPattern
        let action: () -> Void
        
        var hitTestPath: Path {
            Path(CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Press States
    
    struct PressState {
        var isPressed: Bool = false
        var scale: CGFloat { isPressed ? 0.95 : 1.0 }
        var opacity: Double { isPressed ? 0.8 : 1.0 }
    }
    
    // MARK: - Interaction Feedback
    
    func playHaptic(_ pattern: HapticPattern) {
        guard let pattern = pattern.pattern,
              let player = try? engine?.makePlayer(with: pattern) else { return }
        
        try? player.start(atTime: CHHapticTimeImmediate)
    }
    
    // MARK: - Edge Swipe Detection
    
    struct EdgeSwipe {
        let edge: Edge
        let threshold: CGFloat
        var progress: CGFloat = 0
        
        var isActive: Bool {
            progress >= threshold
        }
    }
}

// MARK: - View Modifiers

struct InteractiveButtonStyle: ButtonStyle {
    @StateObject private var interaction = InteractionSystem()
    @State private var pressState = InteractionSystem.PressState()
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(pressState.scale)
            .opacity(pressState.opacity)
            #if compiler(>=5.9)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressState.isPressed = newValue
                }
                if newValue {
                    interaction.playHaptic(.selection)
                }
            }
            #else
            .onChange(of: configuration.isPressed) { newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressState.isPressed = newValue
                }
                if newValue {
                    interaction.playHaptic(.selection)
                }
            }
            #endif
    }
}

struct GestureZoneModifier: ViewModifier {
    let zone: InteractionSystem.GestureZone
    @StateObject private var interaction = InteractionSystem()
    
    func body(content: Content) -> some View {
        content
            .frame(width: zone.size.width, height: zone.size.height)
            .contentShape(zone.hitTestPath)
            .onTapGesture {
                interaction.playHaptic(zone.feedback)
                zone.action()
            }
    }
}

struct EdgeSwipeModifier: ViewModifier {
    let edge: Edge
    let threshold: CGFloat
    let onSwipe: () -> Void
    @State private var swipe: InteractionSystem.EdgeSwipe
    @StateObject private var interaction = InteractionSystem()
    
    init(edge: Edge, threshold: CGFloat = 0.5, onSwipe: @escaping () -> Void) {
        self.edge = edge
        self.threshold = threshold
        self.onSwipe = onSwipe
        _swipe = State(initialValue: InteractionSystem.EdgeSwipe(edge: edge, threshold: threshold))
    }
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let progress = calculateProgress(from: value)
                        swipe.progress = progress
                        
                        if progress >= threshold {
                            interaction.playHaptic(.impact)
                        }
                    }
                    .onEnded { value in
                        let progress = calculateProgress(from: value)
                        if progress >= threshold {
                            onSwipe()
                        }
                        swipe.progress = 0
                    }
            )
    }
    
    private func calculateProgress(from value: DragGesture.Value) -> CGFloat {
        switch edge {
        case .leading:
            return value.translation.width / UIScreen.main.bounds.width
        case .trailing:
            return -value.translation.width / UIScreen.main.bounds.width
        case .top:
            return value.translation.height / UIScreen.main.bounds.height
        case .bottom:
            return -value.translation.height / UIScreen.main.bounds.height
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies interactive button style with haptic feedback
    func interactiveButton() -> some View {
        self.buttonStyle(InteractiveButtonStyle())
    }
    
    /// Creates a gesture recognition zone
    func gestureZone(size: CGSize, feedback: InteractionSystem.HapticPattern, action: @escaping () -> Void) -> some View {
        let zone = InteractionSystem.GestureZone(size: size, feedback: feedback, action: action)
        return self.modifier(GestureZoneModifier(zone: zone))
    }
    
    /// Adds edge swipe detection
    func edgeSwipe(edge: Edge, threshold: CGFloat = 0.5, onSwipe: @escaping () -> Void) -> some View {
        self.modifier(EdgeSwipeModifier(edge: edge, threshold: threshold, onSwipe: onSwipe))
    }
} 