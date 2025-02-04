import SwiftUI

/// A tvOS-optimized view for customizing app appearance
struct AppearanceSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 32)
                ],
                spacing: 32
            ) {
                // Theme Selection
                ForEach(ThemeManager.Theme.allCases) { theme in
                    Button {
                        themeManager.currentTheme = theme
                    } label: {
                        ThemeCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(48)
        }
        .navigationTitle("Appearance")
    }
}

/// A card displaying a theme preview
struct ThemeCard: View {
    let theme: ThemeManager.Theme
    let isSelected: Bool
    
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Theme Preview
            ZStack {
                theme.backgroundColor
                
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.elevatedSurfaceColor)
                        .frame(height: 40)
                    
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.accentGradient)
                            .frame(width: 60, height: 60)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.elevatedSurfaceColor)
                            .frame(height: 60)
                    }
                }
                .padding()
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Theme Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryTextColor)
                    
                    Text(theme.description)
                        .font(.body)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accentGradient)
                        .font(.title2)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.elevatedSurfaceColor)
                .brightness(isFocused ? 0.1 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(ThemeManager())
} 