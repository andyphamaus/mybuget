//
//  ContentView.swift
//  MyBudget
//
//  Created by Anh Pham on 12/9/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var localAuthService: LocalAuthenticationService

    var body: some View {
        Group {
            switch authService.authenticationState {
            case .unauthenticated:
                AuthenticationView()
            case .authenticating:
                LoadingView()
            case .authenticated:
                BudgetView()
            }
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.8, blue: 0.6),
                    Color(red: 0.2, green: 0.9, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)

                // Loading text
                VStack(spacing: 16) {
                    Text("Signing In")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Preparing your financial dashboard...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    // Loading dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .opacity(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
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
