import SwiftUI

struct MoviesView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Text("Movies")
                .font(.title)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
} 