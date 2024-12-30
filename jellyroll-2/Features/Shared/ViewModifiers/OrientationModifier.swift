import SwiftUI

// Device orientation and type tracking
enum DeviceOrientation {
    case portrait
    case landscape
}

private struct OrientationEnvironmentKey: EnvironmentKey {
    static let defaultValue: DeviceOrientation = .portrait
}

extension EnvironmentValues {
    var deviceOrientation: DeviceOrientation {
        get { self[OrientationEnvironmentKey.self] }
        set { self[OrientationEnvironmentKey.self] = newValue }
    }
}

// View modifier to track orientation changes
struct OrientationTrackingModifier: ViewModifier {
    @State private var orientation = UIDevice.current.orientation
    
    func body(content: Content) -> some View {
        content
            .environment(\.deviceOrientation, orientation.isLandscape ? .landscape : .portrait)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientation = UIDevice.current.orientation
            }
    }
}

extension View {
    func trackOrientation() -> some View {
        modifier(OrientationTrackingModifier())
    }
} 