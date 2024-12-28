import Foundation
import SwiftUI
import OSLog

@MainActor
class LoginViewModel: ObservableObject {
    private let authService = AuthenticationService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "LoginViewModel")
    
    @Published var serverURL = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var isInitializing = true
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var showServerConfig = false
    @Published var user: JellyfinUser?
    @Published var serverHistory: [ServerHistory] = []
    
    init() {
        loadServerHistory()
        Task {
            await checkExistingAuth()
        }
    }
    
    private func loadServerHistory() {
        serverHistory = authService.getServerHistory()
    }
    
    func selectServer(_ history: ServerHistory) {
        serverURL = history.url
    }
    
    private func checkExistingAuth() async {
        logger.debug("Checking existing authentication")
        do {
            if let token = try authService.getCurrentToken() {
                if !token.isExpired {
                    logger.debug("Found valid authentication token")
                    isAuthenticated = true
                    user = token.user
                } else {
                    logger.debug("Token is expired")
                }
            } else {
                logger.debug("No valid authentication token found")
            }
            
            if let config = try authService.getServerConfiguration() {
                logger.debug("Found server configuration: \(config.baseURLString)")
                serverURL = config.baseURLString
                showServerConfig = false
            } else {
                logger.debug("No server configuration found")
                showServerConfig = true
            }
        } catch {
            logger.error("Error checking existing auth: \(error.localizedDescription)")
            showServerConfig = true
        }
        isInitializing = false
    }
    
    func validateAndSaveServer() async {
        isLoading = true
        errorMessage = nil
        logger.debug("Validating server URL: \(self.serverURL)")
        
        do {
            _ = try await authService.setServerConfiguration(serverURL)
            logger.debug("Server configuration saved successfully")
            showServerConfig = false
        } catch AuthenticationError.invalidServerURL {
            logger.error("Invalid server URL: \(self.serverURL)")
            errorMessage = "Invalid server URL"
        } catch AuthenticationError.serverError(let message) {
            logger.error("Server error: \(message)")
            errorMessage = message
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            errorMessage = "Failed to connect to server: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        logger.debug("Attempting login for user: \(self.username)")
        
        do {
            let token = try await authService.login(username: username, password: password)
            logger.debug("Login successful")
            user = token.user
            isAuthenticated = true
        } catch AuthenticationError.invalidCredentials {
            logger.error("Invalid credentials for user: \(self.username)")
            errorMessage = "Invalid username or password"
        } catch AuthenticationError.networkError(let error) {
            logger.error("Network error during login: \(error.localizedDescription)")
            errorMessage = "Network error: \(error.localizedDescription)"
        } catch AuthenticationError.serverError(let message) {
            logger.error("Server error during login: \(message)")
            errorMessage = message
        } catch {
            logger.error("Unexpected error during login: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func logout() {
        logger.debug("Logging out")
        do {
            try authService.logout()
            isAuthenticated = false
            username = ""
            password = ""
            user = nil
            showServerConfig = true
            logger.debug("Logout successful")
        } catch {
            logger.error("Logout failed: \(error.localizedDescription)")
            errorMessage = "Failed to logout: \(error.localizedDescription)"
        }
    }
    
    func showServerConfiguration() {
        showServerConfig = true
    }
} 