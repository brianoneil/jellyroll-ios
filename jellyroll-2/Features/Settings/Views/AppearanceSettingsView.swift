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
                Button {
                    themeManager.setTheme(.light)
                } label: {
                    ThemeCard(
                        themeType: .light,
                        isSelected: themeManager.currentThemeType == .light
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    themeManager.setTheme(.dark)
                } label: {
                    ThemeCard(
                        themeType: .dark,
                        isSelected: themeManager.currentThemeType == .dark
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(48)
        }
        .navigationTitle("Appearance")
    }
}

/// A card displaying a theme preview
struct ThemeCard: View {
    let themeType: ThemeType
    let isSelected: Bool
    
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    
    private var theme: Theme {
        themeType == .dark ? DarkTheme() : LightTheme()
    }
    
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
                    Text(themeType == .dark ? "Dark Theme" : "Light Theme")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryTextColor)
                    
                    Text(themeType == .dark ? "Perfect for low-light environments" : "Classic bright appearance")
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
        .background(theme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? theme.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(ThemeManager())
} 