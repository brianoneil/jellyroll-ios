import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    JellyfinTheme.backgroundColor(for: themeManager.currentMode)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Logo placeholder
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(themeManager.accentGradient)
                            .padding(.bottom, 20)
                        
                        if viewModel.showServerConfig {
                            serverConfigurationView
                        } else {
                            loginFormView
                        }
                    }
                    .padding()
                }
            }
            .disabled(viewModel.isLoading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.showServerConfig {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Server") {
                            viewModel.showServerConfiguration()
                        }
                        .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .preferredColorScheme(themeManager.currentMode == .dark ? .dark : .light)
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private var serverConfigurationView: some View {
        VStack(spacing: 20) {
            Text("Connect to Server")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
            
            VStack(spacing: 16) {
                TextField("Server URL", text: $viewModel.serverURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .background(JellyfinTheme.surfaceColor(for: themeManager.currentMode))
                
                Button {
                    Task {
                        await viewModel.validateAndSaveServer()
                    }
                } label: {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if !viewModel.serverHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Servers")
                        .font(.headline)
                        .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                        .padding(.top, 8)
                    
                    Divider()
                        .background(JellyfinTheme.Text.tertiary(for: themeManager.currentMode))
                    
                    ForEach(viewModel.serverHistory, id: \.url) { history in
                        Button(action: {
                            viewModel.selectServer(history)
                        }) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(themeManager.accentGradient)
                                VStack(alignment: .leading) {
                                    Text(history.url)
                                        .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                                        .lineLimit(1)
                                    Text(history.lastUsed.formatted(.relative(presentation: .named)))
                                        .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                                        .font(.caption)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if history.url != viewModel.serverHistory.last?.url {
                            Divider()
                                .background(JellyfinTheme.Text.tertiary(for: themeManager.currentMode))
                        }
                    }
                }
                .padding()
                .background(JellyfinTheme.elevatedSurfaceColor(for: themeManager.currentMode))
                .cornerRadius(10)
            }
        }
    }
    
    private var loginFormView: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
            
            VStack(spacing: 15) {
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .background(JellyfinTheme.surfaceColor(for: themeManager.currentMode))
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .background(JellyfinTheme.surfaceColor(for: themeManager.currentMode))
                
                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
} 