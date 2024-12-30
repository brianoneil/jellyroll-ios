//
//  jellyroll_2App.swift
//  jellyroll-2
//
//  Created by boneil on 28/12/2024.
//

import SwiftUI

@main
struct jellyroll_2App: App {
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if loginViewModel.isInitializing {
                        ProgressView("Loading...")
                            .scaleEffect(1.5)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            .tint(themeManager.currentTheme.accentColor)
                    } else if loginViewModel.isAuthenticated {
                        HomeView()
                    } else {
                        LoginView()
                    }
                }
                .background(themeManager.currentTheme.backgroundGradient)
                .environmentObject(loginViewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentThemeType == .dark ? .dark : .light)
            }
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
