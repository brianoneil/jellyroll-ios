import Foundation
import SwiftUI
import OSLog

extension Notification.Name {
    static let serverDidChange = Notification.Name("serverDidChange")
}

@MainActor
class LoginViewModel: ObservableObject {
    private let authService = AuthenticationService.shared
    private let serverHistoryService = ServerHistoryService.shared
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "LoginViewModel")
    
    @Published var serverURL = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var isInitializing = true
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var showServerConfig = false
    @Published var showServerConfigSheet = false
    @Published var user: JellyfinUser?
    @Published var serverHistory: [ServerHistory] = []
    @Published var authenticatedServers: [(serverURL: String, user: JellyfinUser)] = []
    
    init() {
        loadServerHistory()
        Task {
            await checkExistingAuth()
        }
    }
    
    private func loadServerHistory() {
        serverHistory = serverHistoryService.getServerHistory()
    }
    
    private func loadAuthenticatedServers() {
        do {
            let servers = try authService.getStoredServers()
            authenticatedServers = servers.map { (serverURL: $0.serverURL, user: $0.token.user) }
        } catch {
            logger.error("Failed to load authenticated servers: \(error.localizedDescription)")
        }
    }
    
    func selectServer(_ history: ServerHistory) {
        serverURL = history.url
    }
    
    func switchToServer(_ serverURL: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try authService.switchServer(serverURL)
            if let token = try authService.getCurrentToken() {
                self.serverURL = serverURL
                user = token.user
                isAuthenticated = true
                showServerConfig = false
                
                // Post notification that server has changed
                NotificationCenter.default.post(name: .serverDidChange, object: nil)
            }
        } catch {
            logger.error("Failed to switch server: \(error.localizedDescription)")
            errorMessage = "Failed to switch server: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func checkExistingAuth() async {
        logger.debug("Checking existing authentication")
        do {
            loadAuthenticatedServers()
            
            if let token = try authService.getCurrentToken() {
                if !token.isExpired {
                    logger.debug("Found valid authentication token")
                    isAuthenticated = true
                    user = token.user
                }
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
        
        do {
            _ = try await authService.setServerConfiguration(serverURL)
            serverHistoryService.addToHistory(serverURL)
            loadServerHistory()
            showServerConfig = false
        } catch AuthenticationError.invalidServerURL {
            errorMessage = "Invalid server URL"
        } catch AuthenticationError.serverError(let message) {
            errorMessage = message
        } catch {
            errorMessage = "Failed to connect to server: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let token = try await authService.login(username: username, password: password)
            user = token.user
            isAuthenticated = true
            loadAuthenticatedServers()
            
            // Post notification that server has changed (for initial login)
            NotificationCenter.default.post(name: .serverDidChange, object: nil)
        } catch AuthenticationError.invalidCredentials {
            errorMessage = "Invalid username or password"
        } catch AuthenticationError.networkError(let error) {
            errorMessage = "Network error: \(error.localizedDescription)"
        } catch AuthenticationError.serverError(let message) {
            errorMessage = message
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func logout(fromAllServers: Bool = false) {
        do {
            try authService.logout(fromAllServers: fromAllServers)
            isAuthenticated = false
            username = ""
            password = ""
            user = nil
            showServerConfig = true
            loadAuthenticatedServers()
        } catch {
            errorMessage = "Failed to logout: \(error.localizedDescription)"
        }
    }
    
    func showServerConfiguration() {
        serverURL = ""  // Reset the server URL when showing the configuration
        showServerConfig = true
        showServerConfigSheet = true
    }
} 