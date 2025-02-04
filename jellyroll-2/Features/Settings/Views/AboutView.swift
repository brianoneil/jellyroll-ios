import SwiftUI

/// A tvOS-optimized view displaying app information and credits
struct AboutView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                // App Logo
                Image("jamm-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                
                // App Info
                VStack(spacing: 16) {
                    Text("JAMM Player")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("Version \(version)")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                // Credits
                VStack(spacing: 32) {
                    Text("Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 32)
                        ],
                        spacing: 32
                    ) {
                        CreditCard(
                            title: "Jellyfin",
                            description: "Open source media server",
                            url: "https://jellyfin.org"
                        )
                        
                        CreditCard(
                            title: "SwiftUI",
                            description: "User interface framework",
                            url: "https://developer.apple.com/xcode/swiftui"
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 48)
        }
        .navigationTitle("About")
    }
}

/// A card displaying credit information
struct CreditCard: View {
    let title: String
    let description: String
    let url: String
    
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                HStack {
                    Text(url)
                        .font(.callout)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.callout)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .opacity(0.8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.elevatedSurfaceColor)
                    .brightness(isFocused ? 0.1 : 0)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isFocused)
        }
    }
}

#Preview {
    AboutView()
        .environmentObject(ThemeManager())
} 