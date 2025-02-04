import SwiftUI

/// A view that conditionally renders the appropriate home view based on the platform
struct PlatformHomeView: View {
    var body: some View {
        #if os(tvOS)
        TVHomeView()
        #else
        HomeView()
        #endif
    }
} 