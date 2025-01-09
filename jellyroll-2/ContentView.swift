//
//  ContentView.swift
//  jellyroll-2
//
//  Created by boneil on 28/12/2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var loginViewModel: LoginViewModel
    
    var body: some View {
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
            .preferredColorScheme(themeManager.currentThemeType == .dark ? .dark : .light)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(LoginViewModel())
}
