//
//  jellyroll_2App.swift
//  jellyroll-2
//
//  Created by boneil on 28/12/2024.
//

import SwiftUI

@main
struct JammPlayerApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var loginViewModel = LoginViewModel()
    
    init() {
        // Initialize analytics when the app starts
        _ = AnalyticsManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(loginViewModel)
                .withLayoutManager()
                .preferredColorScheme(themeManager.currentThemeType == .dark ? .dark : .light)
        }
    }
}

private struct LoginViewModelKey: EnvironmentKey {
    static let defaultValue: LoginViewModel? = nil
}

extension EnvironmentValues {
    var loginViewModel: LoginViewModel? {
        get { self[LoginViewModelKey.self] }
        set { self[LoginViewModelKey.self] = newValue }
    }
}
