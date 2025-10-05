import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.green.opacity(0.1), .mint.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Welcome Section
                        VStack(spacing: 16) {
                            // Logo/Icon
                            VStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                
                                Text("Welcome to")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                
                                Text("MyBudget")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Text("Your personal garden management app")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Description
                        VStack(spacing: 12) {
                            Text("Get started with your gardening journey")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Track your plants, manage your garden, and grow your green thumb skills - all in one place.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        // Social Sign In Buttons
                        VStack(spacing: 16) {
                            SocialSignInButton(
                                provider: .apple,
                                isLoading: authService.authenticationState == .authenticating
                            ) {
                                Task {
                                    await authService.signInWithApple()
                                }
                            }
                            
                            SocialSignInButton(
                                provider: .google,
                                isLoading: authService.authenticationState == .authenticating
                            ) {
                                Task {
                                    await authService.signInWithGoogle()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Terms and Privacy
                        VStack(spacing: 8) {
                            Text("By continuing, you agree to our")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    // TODO: Open terms
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                                
                                Text("and")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("Privacy Policy") {
                                    // TODO: Open privacy policy
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Social Sign In Button

struct SocialSignInButton: View {
    enum Provider {
        case apple, google
        
        var title: String {
            switch self {
            case .apple: return "Continue with Apple"
            case .google: return "Continue with Google"
            }
        }
        
        var iconName: String {
            switch self {
            case .apple: return "applelogo"
            case .google: return "globe" // Using system icon since we don't have Google logo
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .apple: return .black
            case .google: return .white
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .apple: return .white
            case .google: return .black
            }
        }
        
        var borderColor: Color {
            switch self {
            case .apple: return .clear
            case .google: return .gray.opacity(0.3)
            }
        }
    }
    
    let provider: Provider
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                        .tint(provider.foregroundColor)
                } else {
                    Image(systemName: provider.iconName)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text(provider.title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(provider.foregroundColor)
            .background(provider.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(provider.borderColor, lineWidth: 1)
            )
            .cornerRadius(25)
        }
        .disabled(isLoading)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationService())
}