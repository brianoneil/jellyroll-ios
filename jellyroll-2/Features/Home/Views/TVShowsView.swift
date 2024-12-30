import SwiftUI

struct TVShowsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Text("TV Shows")
                .font(.title)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
} 