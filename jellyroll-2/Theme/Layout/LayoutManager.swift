import SwiftUI
import UIKit

/// Manages layout configuration based on device orientation and size classes
class LayoutManager: ObservableObject {
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
    
    var gridColumns: Int {
        if isPad {
            return isLandscape ? 6 : 4  // iPad: 6 columns landscape, 4 portrait
        } else {
            return isLandscape ? 4 : 2  // Phone: 4 columns landscape, 2 portrait
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

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

extension View {
    func withLayoutManager() -> some View {
        modifier(LayoutManagerModifier())
    }
} 