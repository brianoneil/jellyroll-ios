import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Avatar
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(loginViewModel.user?.name.prefix(1).uppercased() ?? "?"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .padding(.top, 20)
                
                // User Info
                Text("Welcome, \(loginViewModel.user?.name ?? "User")")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let user = loginViewModel.user {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Administrator: \(user.policy.isAdministrator ? "Yes" : "No")", systemImage: "person.badge.key")
                        Label("Server ID: \(user.serverId)", systemImage: "server.rack")
                        Label("Last Login: \(user.lastLoginDate.formatted())", systemImage: "clock")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
} 