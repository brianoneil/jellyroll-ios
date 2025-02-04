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
                                Button {
                                    print("Light theme button tapped")
                                    withAnimation {
                                        themeManager.setTheme(.light)
                                        print("Theme set to light, current theme: \(themeManager.currentThemeType)")
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
                                            .font(.system(size: 20))
                                            .foregroundColor(.orange)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    print("Dark theme button tapped")
                                    withAnimation {
                                        themeManager.setTheme(.dark)
                                        print("Theme set to dark, current theme: \(themeManager.currentThemeType)")
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
                                            .font(.system(size: 20))
                                            .foregroundColor(.indigo)
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
                        // Current Server
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label("Current Server", systemImage: "server.rack")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                                VStack(alignment: .leading) {
                                    Text(loginViewModel.serverURL)
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    if let user = loginViewModel.user {
                                        Text(user.name)
                                            .font(.caption)
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.leading)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                        
                        // Other Connected Servers
                        if !loginViewModel.authenticatedServers.isEmpty {
                            if loginViewModel.authenticatedServers.count > 1 {
                                Text("Other Connected Servers")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                            }
                            
                            ForEach(loginViewModel.authenticatedServers.filter { $0.serverURL != loginViewModel.serverURL }, id: \.serverURL) { server in
                                Button(action: {
                                    Task {
                                        await loginViewModel.switchToServer(server.serverURL)
                                    }
                                }) {
                                    HStack {
                                        Label {
                                            VStack(alignment: .leading) {
                                                Text(server.serverURL)
                                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                                Text(server.user.name)
                                                    .font(.caption)
                                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                            }
                                        } icon: {
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundStyle(themeManager.currentTheme.accentGradient)
                                        }
                                        Spacer()
                                    }
                                }
                                .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                            }
                        }
                        
                        Button(action: {
                            loginViewModel.showServerConfiguration()
                        }) {
                            Label("Connect to Server", systemImage: "plus.circle")
                                .foregroundColor(themeManager.currentTheme.accentColor)
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
                    } footer: {
                        if loginViewModel.authenticatedServers.count > 1 {
                            Text("Tap a server to switch to it")
                                .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                        }
                    }

                    // Downloads Management Section
                    Section {
                        NavigationLink {
                            DownloadsManagementView()
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Label("Downloads", systemImage: "arrow.down.circle")
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        .listRowBackground(themeManager.currentTheme.elevatedSurfaceColor)
                    } header: {
                        Text("Storage")
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

                    #if DEBUG
                    // Debug Settings Section
                    Section("Debug Settings") {
                        Toggle("Use BlurHash Only", isOn: Binding(
                            get: { themeManager.debugImageLoading },
                            set: { _ in themeManager.toggleDebugImageLoading() }
                        ))
                        .tint(themeManager.currentTheme.accentColor)
                        
                        Toggle("Simulate Empty Continue Watching", isOn: Binding(
                            get: { themeManager.debugEmptyContinueWatching },
                            set: { _ in themeManager.toggleDebugEmptyContinueWatching() }
                        ))
                        .tint(themeManager.currentTheme.accentColor)
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
                .navigationBarTitleTextColor(themeManager.currentTheme.primaryTextColor)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image("jamm-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 72)
                            .offset(y: 48)
                    }
                }
            }
        }
        .sheet(isPresented: $loginViewModel.showServerConfigSheet) {
            LoginView()
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