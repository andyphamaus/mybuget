//
//  MyBudgetApp.swift
//  MyBudget
//
//  Created by Anh Pham on 12/9/2025.
//

import SwiftUI

@main
struct MyBudgetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthenticationService()
    @StateObject private var localAuthService = LocalAuthenticationService()

    var body: some Scene {
        WindowGroup {
            EnhancedSplashScreenView()
                .environmentObject(authService)
                .environmentObject(localAuthService)
        }
    }
}
