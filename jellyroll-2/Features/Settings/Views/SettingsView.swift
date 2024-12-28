import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 60, height: 60)
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
                            if let user = loginViewModel.user {
                                Text(user.policy.isAdministrator ? "Administrator" : "User")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Profile")
                }
                
                // Server Information
                Section {
                    HStack {
                        Label("Server", systemImage: "server.rack")
                        Spacer()
                        Text(loginViewModel.serverURL)
                            .foregroundColor(.secondary)
                    }
                    
                    if let user = loginViewModel.user {
                        HStack {
                            Label("Last Login", systemImage: "clock")
                            Spacer()
                            Text(user.lastLoginDate.formatted(.relative(presentation: .named)))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Connection")
                }
                
                // App Information
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
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
                }
            }
            .navigationTitle("Settings")
        }
    }
} 