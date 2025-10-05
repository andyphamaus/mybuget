//
//  ContentView.swift
//  MyBudget
//
//  Created by Anh Pham on 12/9/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        Group {
            switch authService.authenticationState {
            case .unauthenticated:
                AuthenticationView()
            case .authenticating:
                LoadingView()
            case .authenticated:
                MainBudgetView()
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            ProgressView("Signing in...")
                .tint(.green)
        }
    }
}

struct MainBudgetView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // User greeting
                if let user = authService.currentUser {
                    VStack(spacing: 8) {
                        Text("Welcome back,")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text(user.fullName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                }
                
                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("MyBudget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your budget management app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    Text("Ready for your budget features!")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Sample budget stats
                    if let user = authService.currentUser {
                        VStack(spacing: 12) {
                            HStack(spacing: 30) {
                                StatView(title: "Budgets", value: "\(user.budgetsCreated)")
                                StatView(title: "Categories", value: "\(user.categoriesCreated)")
                                StatView(title: "Level", value: user.currentLevel)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button("Sign Out") {
                        authService.signOut()
                    }
                    .foregroundColor(.red)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // AdMob Banner at bottom
                AdBannerContainer(placement: .bottom)
                    .padding(.bottom, 10)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
}
