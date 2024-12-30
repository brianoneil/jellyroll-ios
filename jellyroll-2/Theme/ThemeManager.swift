import SwiftUI

enum ThemeType: String {
    case light
    case dark
}

class ThemeManager: ObservableObject {    
    @Published private(set) var currentTheme: Theme
    @Published private(set) var currentThemeType: ThemeType {
        didSet {
            updateTheme()
        }
    }
    
    init(initialTheme: Theme? = nil) {
        if let theme = initialTheme {
            self.currentTheme = theme
            self.currentThemeType = theme is DarkTheme ? .dark : .light
        } else {
            // Load saved theme preference
            let themeType = ThemeType(rawValue: UserDefaults.standard.string(forKey: "themeType") ?? "light") ?? .light
            self.currentThemeType = themeType
            self.currentTheme = themeType == .dark ? DarkTheme() : LightTheme()
        }
    }
    
    func setTheme(_ type: ThemeType) {
        currentThemeType = type
        UserDefaults.standard.set(type.rawValue, forKey: "themeType")
    }
    
    private func updateTheme() {
        currentTheme = currentThemeType == .dark ? DarkTheme() : LightTheme()
    }
}

// Environment key for the theme manager
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] ?? ThemeManager() }
        set { self[ThemeManagerKey.self] = newValue }
    }
} 