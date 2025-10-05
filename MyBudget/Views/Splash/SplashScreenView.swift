import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var sparkleOffset: CGFloat = 0.0
    @State private var pulseScale: CGFloat = 1.0

    // Configuration
    private let splashDuration: TimeInterval = 3.0
    private let animationDelay: TimeInterval = 0.5

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.8, blue: 0.6),  // Teal green
                    Color(red: 0.2, green: 0.9, blue: 0.7),  // Light green
                    Color(red: 0.15, green: 0.85, blue: 0.65) // Mid green
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            // Animated sparkles background
            ZStack {
                ForEach(0..<15, id: \.self) { index in
                    SparkleView(
                        delay: Double(index) * 0.1,
                        duration: 2.0 + Double(index) * 0.2
                    )
                    .position(
                        x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                        y: CGFloat.random(in: 50...UIScreen.main.bounds.height - 50)
                    )
                }
            }
            .opacity(isAnimating ? 0.6 : 0.0)

            // Main content
            VStack(spacing: 40) {
                Spacer()

                // Logo section with animations
                VStack(spacing: 24) {
                    // Logo container with pulse effect
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseScale)
                            .opacity(logoOpacity)

                        // Middle ring
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseScale)
                            .opacity(logoOpacity)

                        // Main logo circle
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                        // Budget icon
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.green)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }

                    // App name with animation
                    VStack(spacing: 8) {
                        Text("MyBudget")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(textOpacity)
                            .scaleEffect(textOpacity > 0 ? 1.0 : 0.8)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                        Text("Smart Financial Management")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(textOpacity)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .scaleEffect(pulseScale)
                                .opacity(0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: pulseScale
                                )
                        }
                    }

                    Text("Loading your financial world...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(textOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: showContent) {
            if showContent {
                // Navigate to main content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // This will be handled by the parent view
                }
            }
        }
    }

    private func startAnimations() {
        // Stage 1: Background fade in
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }

        // Stage 2: Logo appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
        }

        // Stage 3: Text appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
            }
        }

        // Stage 4: Start pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.6) {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.1
            }
        }

        // Stage 5: Show content
        DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Sparkle Animation Component
struct SparkleView: View {
    let delay: TimeInterval
    let duration: TimeInterval
    @State private var isAnimating = false
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.0
    @State private var rotation: Double = 0.0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isAnimating.toggle()
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: false)
            ) {
                opacity = isAnimating ? 1.0 : 0.0
                scale = isAnimating ? 1.0 : 0.2
                rotation = isAnimating ? 360.0 : 0.0
            }
        }
    }
}

// MARK: - Splash Screen Manager
class SplashScreenManager: ObservableObject {
    @Published var shouldShowSplash = true
    @Published var splashCompleted = false

    func hideSplash() {
        withAnimation(.easeOut(duration: 0.5)) {
            shouldShowSplash = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.splashCompleted = true
        }
    }
}

// MARK: - Enhanced Splash Screen Container
struct EnhancedSplashScreenView: View {
    @StateObject private var splashManager = SplashScreenManager()
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        ZStack {
            if splashManager.shouldShowSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                // Main app content
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
                .opacity(splashManager.splashCompleted ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // Check if we should show splash based on app launch
            if shouldShowSplashOnLaunch() {
                // Hide splash after appropriate duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        splashManager.shouldShowSplash = false
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        splashManager.splashCompleted = true
                    }
                }
            } else {
                // Skip splash for returning users
                splashManager.hideSplash()
            }
        }
    }

    private func shouldShowSplashOnLaunch() -> Bool {
        // You can customize this logic based on your preferences
        // For now, always show splash
        return true
    }
}

// MARK: - Preview
#Preview {
    EnhancedSplashScreenView()
        .environmentObject(AuthenticationService())
}