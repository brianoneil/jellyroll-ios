import SwiftUI

/// A tvOS-optimized settings view
struct TVSettingsView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingLogoutAlert = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 48) {
                // User Profile Section
                VStack(spacing: 24) {
                    Circle()
                        .fill(themeManager.currentTheme.accentGradient)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(String(loginViewModel.user?.name.prefix(1).uppercased() ?? "?"))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    if let user = loginViewModel.user {
                        Text(user.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        if let server = loginViewModel.currentServer {
                            Text(server.name)
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                }
                .padding(.top, 48)
                
                // Settings Grid
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 32)
                    ],
                    spacing: 32
                ) {
                    // Appearance Settings
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        SettingsCard(
                            title: "Appearance",
                            icon: "paintbrush",
                            description: "Customize the look and feel"
                        )
                    }
                    
                    // Downloads
                    NavigationLink {
                        DownloadsManagementView()
                    } label: {
                        SettingsCard(
                            title: "Downloads",
                            icon: "arrow.down.circle",
                            description: "Manage downloaded content"
                        )
                    }
                    
                    // About
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsCard(
                            title: "About",
                            icon: "info.circle",
                            description: "App information and credits"
                        )
                    }
                    
                    // Logout Button
                    Button {
                        showingLogoutAlert = true
                    } label: {
                        SettingsCard(
                            title: "Log Out",
                            icon: "rectangle.portrait.and.arrow.right",
                            description: "Sign out of your account",
                            isDestructive: true
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                Task {
                    await loginViewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

/// A card-style button for settings options
struct SettingsCard: View {
    let title: String
    let icon: String
    let description: String
    var isDestructive: Bool = false
    
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .opacity(0.8)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.5)
        }
        .foregroundColor(isDestructive ? .red : themeManager.currentTheme.primaryTextColor)
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

#Preview {
    TVSettingsView()
        .environmentObject(LoginViewModel())
        .environmentObject(ThemeManager())
} 