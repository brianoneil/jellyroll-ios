import SwiftUI

/// Components for tab-based navigation that adapt to different layouts
struct TabComponents {
    /// A tab bar that adapts its layout based on device orientation and size
    struct AdaptiveTabBar: View {
        let tabs: [TabItem]
        @Binding var selectedTab: Int
        @EnvironmentObject private var themeManager: ThemeManager
        @EnvironmentObject private var layoutManager: LayoutManager
        
        var body: some View {
            Group {
                if layoutManager.isPad && layoutManager.isLandscape {
                    // Vertical tab bar for iPad in landscape
                    VStack(spacing: 24) {
                        ForEach(tabs.indices, id: \.self) { index in
                            TabButton(
                                title: tabs[index].title,
                                icon: tabs[index].icon,
                                isSelected: selectedTab == index,
                                showLabel: true
                            ) {
                                withAnimation {
                                    selectedTab = index
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .frame(width: 100)
                    .background(themeManager.currentTheme.elevatedSurfaceColor)
                } else {
                    // Horizontal scrolling tab bar for other layouts
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(tabs.indices, id: \.self) { index in
                                TabButton(
                                    title: tabs[index].title,
                                    icon: tabs[index].icon,
                                    isSelected: selectedTab == index,
                                    showLabel: true
                                ) {
                                    withAnimation {
                                        selectedTab = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    /// A single tab button with optional icon
    struct TabButton: View {
        let title: String
        let icon: String?
        let isSelected: Bool
        let showLabel: Bool
        let action: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    if let icon = icon {
                        if icon == "jamm-logo" {
                            // Custom image
                            Image(icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 24)
                        } else {
                            // System icon
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.tertiaryTextColor)
                        }
                    }
                    
                    if showLabel {
                        Text(title)
                            .font(.system(size: 16))
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundColor(isSelected ? themeManager.currentTheme.primaryTextColor : themeManager.currentTheme.tertiaryTextColor)
                    }
                    
                    if isSelected {
                        Rectangle()
                            .fill(themeManager.currentTheme.accentGradient)
                            .frame(height: 2)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                }
            }
        }
    }
    
    /// Model for tab items
    struct TabItem {
        let title: String
        let icon: String?
        
        init(title: String, icon: String? = nil) {
            self.title = title
            self.icon = icon
        }
    }
} 