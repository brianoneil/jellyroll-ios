import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                .onAppear {
                    print("SettingsView appeared, current theme: \(themeManager.currentThemeType)")
                }
                
                List {
                    // User Profile Section
                    Section {
                        HStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(themeManager.currentTheme.accentGradient)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(String(loginViewModel.user?.name.prefix(1).uppercased() ?? "?"))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            // User Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loginViewModel.user?.name ?? "User")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                if let user = loginViewModel.user {
                                    Text(user.policy.isAdministrator ? "Administrator" : "User")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                    } header: {
                        Text("Profile")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    // Appearance Section
                    Section {
                        HStack {
                            Label("Theme", systemImage: "paintbrush")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Spacer()
                            HStack(spacing: 12) {
                                // Light theme button
                                Button {
                                    withAnimation {
                                        themeManager.setTheme(.light)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(themeManager.currentThemeType == .light ? 
                                                themeManager.currentTheme.accentColor.opacity(0.2) : 
                                                themeManager.currentTheme.surfaceColor)
                                            .overlay(
                                                Circle()
                                                    .stroke(themeManager.currentThemeType == .light ? 
                                                        themeManager.currentTheme.accentColor : .clear, 
                                                        lineWidth: 2)
                                            )
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Dark theme button
                                Button {
                                    withAnimation {
                                        themeManager.setTheme(.dark)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(themeManager.currentThemeType == .dark ? 
                                                themeManager.currentTheme.accentColor.opacity(0.2) : 
                                                themeManager.currentTheme.surfaceColor)
                                            .overlay(
                                                Circle()
                                                    .stroke(themeManager.currentThemeType == .dark ? 
                                                        themeManager.currentTheme.accentColor : .clear, 
                                                        lineWidth: 2)
                                            )
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Blackberry theme button
                                Button {
                                    withAnimation {
                                        themeManager.setTheme(.blackberry)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(themeManager.currentThemeType == .blackberry ? 
                                                themeManager.currentTheme.accentColor.opacity(0.2) : 
                                                themeManager.currentTheme.surfaceColor)
                                            .overlay(
                                                Circle()
                                                    .stroke(themeManager.currentThemeType == .blackberry ? 
                                                        themeManager.currentTheme.accentColor : .clear, 
                                                        lineWidth: 2)
                                            )
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "circle.hexagongrid.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    } header: {
                        Text("Appearance")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    // Server Information
                    Section {
                        HStack {
                            Label("Server", systemImage: "server.rack")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Spacer()
                            Text(loginViewModel.serverURL)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                        
                        if let user = loginViewModel.user {
                            HStack {
                                Label("Last Login", systemImage: "clock")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Text(user.lastLoginDate.formatted(.relative(presentation: .named)))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                        }
                    } header: {
                        Text("Connection")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    // App Information
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                    } header: {
                        Text("About")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    // Logout Button
                    Section {
                        Button {
                            loginViewModel.logout()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
                .navigationBarTitleTextColor(themeManager.currentTheme.primaryTextColor)
            }
        }
    }
}

// Extension to support navigation bar title color
extension View {
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(color)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(color)]
        return self
    }
} 