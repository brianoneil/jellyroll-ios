import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Custom theme colors
    private let backgroundColor = Color(red: 0.07, green: 0.09, blue: 0.18) // Slightly lighter navy
    private let sectionBackgroundColor = Color(red: 0.1, green: 0.12, blue: 0.22) // Even lighter navy for sections
    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.4, blue: 0.8), // Purple
            Color(red: 0.4, green: 0.5, blue: 0.9)  // Blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                List {
                    // User Profile Section
                    Section {
                        HStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(accentGradient)
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
                                    .foregroundColor(.white)
                                if let user = loginViewModel.user {
                                    Text(user.policy.isAdministrator ? "Administrator" : "User")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(sectionBackgroundColor)
                    } header: {
                        Text("Profile")
                            .foregroundColor(.gray)
                    }
                    
                    // Server Information
                    Section {
                        HStack {
                            Label("Server", systemImage: "server.rack")
                                .foregroundColor(.white)
                            Spacer()
                            Text(loginViewModel.serverURL)
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(sectionBackgroundColor)
                        
                        if let user = loginViewModel.user {
                            HStack {
                                Label("Last Login", systemImage: "clock")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(user.lastLoginDate.formatted(.relative(presentation: .named)))
                                    .foregroundColor(.gray)
                            }
                            .listRowBackground(sectionBackgroundColor)
                        }
                    } header: {
                        Text("Connection")
                            .foregroundColor(.gray)
                    }
                    
                    // App Information
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(sectionBackgroundColor)
                    } header: {
                        Text("About")
                            .foregroundColor(.gray)
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
                        .listRowBackground(sectionBackgroundColor)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
            }
        }
        .preferredColorScheme(.dark)
    }
} 