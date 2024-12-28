import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Logo placeholder
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.accentColor)
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
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
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
            
            VStack(spacing: 16) {
                TextField("Server URL", text: $viewModel.serverURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                
                Button {
                    Task {
                        await viewModel.validateAndSaveServer()
                    }
                } label: {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
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
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Divider()
                    
                    ForEach(viewModel.serverHistory, id: \.url) { history in
                        Button(action: {
                            viewModel.selectServer(history)
                        }) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text(history.url)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(history.lastUsed.formatted(.relative(presentation: .named)))
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if history.url != viewModel.serverHistory.last?.url {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private var loginFormView: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
} 