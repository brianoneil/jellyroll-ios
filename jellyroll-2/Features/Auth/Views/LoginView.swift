import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: LoginViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo placeholder
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(themeManager.currentTheme.accentGradient)
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
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
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
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            TextField("Server URL", text: $viewModel.serverURL)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button(action: {
                Task {
                    await viewModel.validateAndSaveServer()
                }
            }) {
                Text("Connect")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.serverURL.isEmpty || viewModel.isLoading)
            
            if !viewModel.authenticatedServers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connected Servers")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding(.top, 8)
                    
                    Divider()
                        .background(themeManager.currentTheme.tertiaryTextColor)
                    
                    ForEach(viewModel.authenticatedServers, id: \.serverURL) { server in
                        Button(action: {
                            Task {
                                await viewModel.switchToServer(server.serverURL)
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                                VStack(alignment: .leading) {
                                    Text(server.serverURL)
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .lineLimit(1)
                                    Text(server.user.name)
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if server.serverURL != viewModel.authenticatedServers.last?.serverURL {
                            Divider()
                                .background(themeManager.currentTheme.tertiaryTextColor)
                        }
                    }
                }
                .padding()
                .background(themeManager.currentTheme.surfaceColor)
                .cornerRadius(10)
                
                Button(action: {
                    viewModel.logout(fromAllServers: true)
                }) {
                    Text("Disconnect All")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            
            if !viewModel.serverHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Servers")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding(.top, 8)
                    
                    Divider()
                        .background(themeManager.currentTheme.tertiaryTextColor)
                    
                    ForEach(viewModel.serverHistory, id: \.url) { history in
                        Button(action: {
                            viewModel.selectServer(history)
                        }) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(themeManager.currentTheme.accentGradient)
                                VStack(alignment: .leading) {
                                    Text(history.url)
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if history.url != viewModel.serverHistory.last?.url {
                            Divider()
                                .background(themeManager.currentTheme.tertiaryTextColor)
                        }
                    }
                }
                .padding()
                .background(themeManager.currentTheme.surfaceColor)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var loginFormView: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            VStack(spacing: 15) {
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .background(themeManager.currentTheme.surfaceColor)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .background(themeManager.currentTheme.surfaceColor)
                
                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.currentTheme.accentGradient)
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