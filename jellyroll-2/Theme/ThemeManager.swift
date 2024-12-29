import SwiftUI

enum ThemeMode {
    case light
    case dark
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentMode: ThemeMode = .dark {
        didSet {
            UserDefaults.standard.set(currentMode == .dark, forKey: "isDarkMode")
        }
    }
    
    private init() {
        // Load saved theme preference
        currentMode = UserDefaults.standard.bool(forKey: "isDarkMode") ? .dark : .light
    }
} 