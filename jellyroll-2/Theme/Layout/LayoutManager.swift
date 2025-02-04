import SwiftUI
import UIKit

/// Manages layout configuration based on device orientation and size classes
class LayoutManager: ObservableObject {
    @Published var isPad: Bool
    @Published var isLandscape: Bool
    @Published private(set) var horizontalSizeClass: UIUserInterfaceSizeClass = .compact
    @Published private(set) var verticalSizeClass: UIUserInterfaceSizeClass = .regular
    
    init() {
        #if os(tvOS)
        self.isPad = true  // tvOS is always considered in "pad" mode
        self.isLandscape = true  // tvOS is always in landscape
        #else
        self.isPad = UIDevice.current.userInterfaceIdiom == .pad
        self.isLandscape = UIDevice.current.orientation.isLandscape
        
        // Only add orientation observer on non-tvOS platforms
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        #endif
    }
    
    #if !os(tvOS)
    @objc private func orientationChanged() {
        isLandscape = UIDevice.current.orientation.isLandscape
    }
    #endif
    
    func updateSizeClasses(horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) {
        horizontalSizeClass = horizontal
        verticalSizeClass = vertical
    }
    
    deinit {
        #if !os(tvOS)
        NotificationCenter.default.removeObserver(self)
        #endif
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