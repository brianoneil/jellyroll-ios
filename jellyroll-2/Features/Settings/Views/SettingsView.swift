import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                JellyfinTheme.backgroundColor(for: themeManager.currentMode).ignoresSafeArea()
                
                List {
                    // User Profile Section
                    Section {
                        HStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(themeManager.accentGradient)
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
                                    .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                                if let user = loginViewModel.user {
                                    Text(user.policy.isAdministrator ? "Administrator" : "User")
                                        .font(.subheadline)
                                        .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                    } header: {
                        Text("Profile")
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                    }
                    
                    // Appearance Section
                    Section {
                        Picker("Theme", selection: $themeManager.currentMode) {
                            Text("Light")
                                .tag(ThemeMode.light)
                            Text("Dark")
                                .tag(ThemeMode.dark)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                    } header: {
                        Text("Appearance")
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                    }
                    
                    // Server Information
                    Section {
                        HStack {
                            Label("Server", systemImage: "server.rack")
                                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                            Spacer()
                            Text(loginViewModel.serverURL)
                                .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                        }
                        .listRowBackground(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                        
                        if let user = loginViewModel.user {
                            HStack {
                                Label("Last Login", systemImage: "clock")
                                    .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                                Spacer()
                                Text(user.lastLoginDate.formatted(.relative(presentation: .named)))
                                    .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                            }
                            .listRowBackground(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                        }
                    } header: {
                        Text("Connection")
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                    }
                    
                    // App Information
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                        }
                        .listRowBackground(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                    } header: {
                        Text("About")
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                    }
                    
                    // Logout Button
                    Section {
                        Button(role: .destructive) {
                            loginViewModel.logout()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                Spacer()
                            }
                        }
                        .listRowBackground(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
            }
        }
        .preferredColorScheme(themeManager.currentMode == .dark ? .dark : .light)
    }
} 