import SwiftUI

enum ThemeType: String {
    case light
    case dark
    case blackberry
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
            self.currentThemeType = theme is DarkTheme ? .dark : (theme is BlackberryTheme ? .blackberry : .light)
        } else {
            // Load saved theme preference
            let themeType = ThemeType(rawValue: UserDefaults.standard.string(forKey: "themeType") ?? "light") ?? .light
            self.currentThemeType = themeType
            self.currentTheme = {
                switch themeType {
                case .dark: return DarkTheme()
                case .blackberry: return BlackberryTheme()
                case .light: return LightTheme()
                }
            }()
        }
    }
    
    func setTheme(_ type: ThemeType) {
        currentThemeType = type
        UserDefaults.standard.set(type.rawValue, forKey: "themeType")
    }
    
    private func updateTheme() {
        switch currentThemeType {
        case .dark:
            currentTheme = DarkTheme()
        case .blackberry:
            currentTheme = BlackberryTheme()
        case .light:
            currentTheme = LightTheme()
        }
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