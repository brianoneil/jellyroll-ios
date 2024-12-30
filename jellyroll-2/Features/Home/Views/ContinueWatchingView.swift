import SwiftUI

struct ContinueWatchingView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Text("Continue Watching")
                .font(.title)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
} 