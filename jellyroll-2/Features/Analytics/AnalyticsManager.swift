import Foundation
import PostHog
import SwiftUI

/// Manages analytics tracking throughout the application
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @AppStorage("analytics_enabled") private var isEnabled: Bool = true
    
    private init() {
        // Initialize PostHog with configuration
        let config = PostHogConfig(
            apiKey: "phc_8o4H7lQ2NobBEMyBSh9Ri6eG2uOSpiOvTK4lqCo0WQ9",
            host: "https://us.i.posthog.com"
        )
        
        // Configure additional options
        config.captureApplicationLifecycleEvents = true // Automatically capture app lifecycle events
        
        // Initialize PostHog SDK
        PostHogSDK.shared.setup(config)
    }
    
    // MARK: - Analytics Control
    
    /// Toggle analytics on/off
    func setAnalyticsEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            reset() // Clear user data when disabling
        }
    }
    
    /// Check if analytics is enabled
    var analyticsEnabled: Bool {
        isEnabled
    }
    
    // MARK: - Analytics Events
    
    /// Track a user action or event
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - properties: Additional properties to track with the event
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        PostHogSDK.shared.capture(eventName, properties: properties)
    }
    
    /// Track screen view
    /// - Parameters:
    ///   - screenName: Name of the screen
    ///   - properties: Additional properties to track with the screen view
    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        PostHogSDK.shared.screen(screenName, properties: properties)
    }
    
    /// Identify a user with their properties
    /// - Parameters:
    ///   - userId: Unique identifier for the user
    ///   - properties: User properties to set
    func identifyUser(userId: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        PostHogSDK.shared.identify(
            userId,
            userProperties: properties,
            userPropertiesSetOnce: nil
        )
    }
    
    /// Reset user identification (e.g., on logout)
    func reset() {
        PostHogSDK.shared.reset()
    }
    
    /// Manually flush events to PostHog
    func flush() {
        guard isEnabled else { return }
        PostHogSDK.shared.flush()
    }
}

// MARK: - SwiftUI View Extensions
extension View {
    /// Tracks when this view appears as a screen
    /// - Parameters:
    ///   - screenName: Name of the screen to track
    ///   - properties: Additional properties to track with the screen view
    func trackScreenView(_ screenName: String, properties: [String: Any]? = nil) -> some View {
        self.onAppear {
            AnalyticsManager.shared.trackScreen(screenName, properties: properties)
        }
    }
} 