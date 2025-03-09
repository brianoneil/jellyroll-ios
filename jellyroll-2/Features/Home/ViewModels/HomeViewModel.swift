import SwiftUI

class HomeViewModel: ObservableObject {
    private let analytics = AnalyticsManager.shared
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Track when the home screen appears
    func onAppear() {
        analytics.trackEvent("home_screen_viewed")
    }
    
    // Track when a section is viewed
    func trackSectionViewed(_ section: String) {
        analytics.trackEvent("section_viewed", properties: [
            "section_name": section
        ])
    }
    
    // Track when media content is selected
    func trackMediaSelected(_ mediaType: String, itemId: String, title: String) {
        analytics.trackEvent("media_selected", properties: [
            "media_type": mediaType,
            "item_id": itemId,
            "title": title
        ])
    }
    
    // Track search actions
    func trackSearch(query: String) {
        analytics.trackEvent("search_performed", properties: [
            "query": query
        ])
    }
    
    // Add more properties and methods as needed
} 