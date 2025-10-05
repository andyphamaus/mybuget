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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
