import SwiftUI

// MARK: - Premium Glassmorphism UI Components

struct GlassCard: View {
    let content: AnyView
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init<Content: View>(
        cornerRadius: CGFloat = 24,
        shadowRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                ZStack {
                    // Glass effect background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border stroke
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }
}

// MARK: - Premium Button Component

struct PremiumButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonStyle
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color.blue
            case .secondary: return Color.gray.opacity(0.2)
            case .ghost: return Color.clear
            case .danger: return Color.red
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .danger: return Color.white
            case .secondary, .ghost: return Color.primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return Color.blue.opacity(0.3)
            case .secondary: return Color.gray.opacity(0.3)
            case .ghost: return Color.white.opacity(0.3)
            case .danger: return Color.red.opacity(0.3)
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(style.textColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Background with glass effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(style.backgroundColor)
                    
                    // Glass overlay for secondary buttons
                    if style == .secondary || style == .ghost {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                    }
                    
                    // Pressed state overlay
                    if isPressed {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.1))
                    }
                    
                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style.borderColor, lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(PremiumAnimations.quickSpring, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Floating Progress Bar

struct FloatingProgressBar: View {
    let progress: Double
    let totalSteps: Int
    let currentStep: Int
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(
                            index < currentStep ? .blue :
                            index == currentStep ? .blue.opacity(0.6) :
                            .white.opacity(0.3)
                        )
                        .scaleEffect(index == currentStep ? 1.3 : 1.0)
                        .animation(PremiumAnimations.gentleSpring.delay(Double(index) * 0.1), value: currentStep)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .blue,
                                    .cyan
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 6)
                        .animation(PremiumAnimations.smoothEaseOut, value: animatedProgress)
                }
            }
            .frame(height: 6)
            .onAppear {
                animatedProgress = progress
            }
            .onChange(of: progress) { _, newProgress in
                withAnimation(PremiumAnimations.smoothEaseOut.delay(0.3)) {
                    animatedProgress = newProgress
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Premium Tutorial Card

struct TutorialCard: View {
    let step: TutorialStep
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    let canGoBack: Bool
    
    @State private var cardOffset: CGFloat = 300
    @State private var cardOpacity: Double = 0
    @State private var isVisible = false
    
    struct TutorialStep {
        let title: String
        let description: String
        let illustration: String
        let actionText: String
        let isLastStep: Bool
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Skip button in top-right corner
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
            }
            .padding(.bottom, 16)
            
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Illustration/Icon
                HStack {
                    Spacer()
                    Text(step.illustration)
                        .font(.system(size: 64))
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(PremiumAnimations.ultraBouncySpring.delay(0.4), value: isVisible)
                    Spacer()
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 12) {
                    Text(step.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(PremiumAnimations.gentleSpring.delay(0.2), value: isVisible)
                    
                    Text(step.description)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(nil)
                        .lineSpacing(4)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(PremiumAnimations.gentleSpring.delay(0.3), value: isVisible)
                }
                
                Spacer(minLength: 20)
                
                // Navigation buttons
                HStack(spacing: 12) {
                    if canGoBack {
                        PremiumButton("Previous", icon: "chevron.left", style: .ghost) {
                            onPrevious()
                        }
                    }
                    
                    Spacer()
                    
                    PremiumButton(
                        step.isLastStep ? "Complete" : step.actionText,
                        icon: step.isLastStep ? "checkmark" : "chevron.right",
                        style: .primary
                    ) {
                        onNext()
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(PremiumAnimations.gentleSpring.delay(0.5), value: isVisible)
            }
        }
        .padding(28)
        .background(
            GlassCard {
                Color.clear
            }
        )
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(PremiumAnimations.heroSpring) {
                cardOffset = 0
                cardOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isVisible = true
            }
        }
    }
}

// MARK: - Premium Skip Dialog

struct PremiumSkipDialog: View {
    let onSkip: () -> Void
    let onNeverShow: () -> Void
    let onCancel: () -> Void
    
    @State private var dialogScale: Double = 0.8
    @State private var dialogOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissDialog()
                }
            
            // Dialog content
            VStack(spacing: 24) {
                // Icon and title
                VStack(spacing: 16) {
                    Text("⏭️")
                        .font(.system(size: 48))
                    
                    Text("Skip Tutorial?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("You can always restart the tutorial from Settings if you change your mind.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    PremiumButton("Skip for now", style: .secondary) {
                        onSkip()
                    }
                    
                    PremiumButton("Don't show again", style: .danger) {
                        onNeverShow()
                    }
                    
                    PremiumButton("Continue Tutorial", style: .primary) {
                        onCancel()
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(dialogScale)
            .opacity(dialogOpacity)
            .frame(maxWidth: 320)
        }
        .onAppear {
            withAnimation(PremiumAnimations.quickFade) {
                backgroundOpacity = 0.5
            }
            
            withAnimation(PremiumAnimations.ultraBouncySpring.delay(0.1)) {
                dialogScale = 1.0
                dialogOpacity = 1.0
            }
        }
    }
    
    private func dismissDialog() {
        withAnimation(PremiumAnimations.quickFade) {
            backgroundOpacity = 0
            dialogScale = 0.9
            dialogOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onCancel()
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let style: PremiumButton.ButtonStyle
    
    @State private var isPressed = false
    @State private var isVisible = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(style.backgroundColor)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.92 : (isVisible ? 1.0 : 0.8))
                .opacity(isVisible ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(PremiumAnimations.snapAnimation) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(PremiumAnimations.ultraBouncySpring.delay(0.5)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AnimatedGradientBackground()
        
        VStack(spacing: 20) {
            FloatingProgressBar(
                progress: 0.6,
                totalSteps: 8,
                currentStep: 4
            )
            
            TutorialCard(
                step: TutorialCard.TutorialStep(
                    title: "Welcome to Budget Management",
                    description: "Take control of your finances with smart budgeting tools. Track expenses, plan ahead, and achieve your financial goals.",
                    illustration: "💰",
                    actionText: "Get Started",
                    isLastStep: false
                ),
                onNext: {},
                onPrevious: {},
                onSkip: {},
                canGoBack: false
            )
        }
        .padding(20)
    }
}