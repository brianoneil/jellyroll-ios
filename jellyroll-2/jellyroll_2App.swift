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
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if loginViewModel.isInitializing {
                        ProgressView("Loading...")
                            .scaleEffect(1.5)
                    } else if loginViewModel.isAuthenticated {
                        HomeView()
                    } else {
                        LoginView()
                    }
                }
                .environmentObject(loginViewModel)
                .preferredColorScheme(themeManager.currentMode == .dark ? .dark : .light)
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
