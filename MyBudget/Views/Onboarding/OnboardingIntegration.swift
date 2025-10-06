import SwiftUI

// MARK: - Budget Onboarding Integration
struct BudgetOnboardingIntegration: ViewModifier {
    @StateObject private var coordinator = OnboardingCoordinator()
    @State private var showOnboarding = false

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showOnboarding) {
                PremiumOnboardingView()
            }
            .onAppear {
                checkAndShowOnboarding()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.showOnboardingTutorial)) { _ in
                showOnboarding = true
            }
    }

    private func checkAndShowOnboarding() {
        // First, mark budget module as visited
        OnboardingPreferences.markBudgetModuleVisited()

        // Check if we should auto-show onboarding for first-time visitors
        if OnboardingPreferences.shouldAutoShowOnboarding {
            // Delay auto-show by 1.5 seconds to allow UI to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showOnboarding = true
            }
        }
        // Also check if user manually requested to see it again
        else if OnboardingPreferences.shouldShowOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showOnboarding = true
            }
        }
    }
}

extension View {
    func budgetOnboarding() -> some View {
        self.modifier(BudgetOnboardingIntegration())
    }
}

// MARK: - Premium Onboarding View (unified implementation)
struct PremiumOnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @Environment(\.dismiss) var dismiss
    private let hapticManager = HapticManager()

    @State private var showConfetti = false
    @State private var backgroundAnimation: BackgroundAnimationState = .static
    @State private var cardOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.8
    @State private var contentOffset: CGSize = .zero
    @State private var iconRotation: Double = 0
    @State private var titleScale: CGFloat = 1.0
    @State private var buttonHoverScale: CGFloat = 1.0

    enum BackgroundAnimationState {
        case `static`
        case animated
        case celebration
    }

    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
                .ignoresSafeArea()

            // Ambient particles for key steps
            if coordinator.currentStep?.targetElement == "budget_header" ||
               coordinator.currentStep?.targetElement == "completion" {
                ParticleEmitter(
                    particleCount: 30,
                    particleLifetime: 3.0,
                    emissionAngle: .degrees(-90),
                    colors: [
                        BudgetDesignSystem.Colors.primary,
                        BudgetDesignSystem.Colors.primaryLight,
                        BudgetDesignSystem.Colors.success
                    ]
                )
                .allowsHitTesting(false)
            }

            // Main content with premium styling
            if let step = coordinator.currentStep {
                VStack(spacing: 0) {
                    // Progress indicator at top
                    FloatingProgressBar(
                        progress: coordinator.progress,
                        totalSteps: coordinator.steps.count,
                        currentStep: coordinator.currentStepIndex
                    )
                    .padding(.top, 20)

                    // Premium content card using BudgetDesignSystem
                    VStack(spacing: 0) {
                        onboardingCardContent(for: step)
                            .padding(28)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(BudgetDesignSystem.Colors.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        BudgetDesignSystem.Colors.primary.opacity(0.3),
                                                        BudgetDesignSystem.Colors.primaryLight.opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: BudgetDesignSystem.Colors.primary.opacity(0.1),
                                        radius: 25,
                                        x: 0,
                                        y: 10
                                    )
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                    // Navigation buttons
                    onboardingNavigationButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }

            // Celebration overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            coordinator.startOnboarding()
            withAnimation(.easeInOut(duration: 1.0)) {
                backgroundAnimation = .animated
                cardOpacity = 1.0
                cardScale = 1.0
            }

            // Subtle icon rotation animation
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                iconRotation = 360
            }
        }
        .onChange(of: coordinator.isCompleted) { completed in
            if completed {
                // Celebration sequence
                hapticManager.playSuccessPattern()
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    backgroundAnimation = .celebration
                    showConfetti = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
        .onChange(of: coordinator.isActive) { active in
            if !active {
                dismiss()
            }
        }
        .onChange(of: coordinator.currentStepIndex) { newIndex in
            // Animate content transition when step changes
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentOffset = .zero
                titleScale = 1.0
            }

            // Add a subtle bounce effect when moving to next step
            if let previousIndex = coordinator.steps.firstIndex(where: { $0.id == coordinator.currentStep?.id }) {
                if newIndex > previousIndex {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        contentOffset = CGSize(width: 20, height: 0)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            contentOffset = .zero
                        }
                    }
                }
            }
        }
    }

    // MARK: - Onboarding Content Card
    @ViewBuilder
    private func onboardingCardContent(for step: OnboardingStep) -> some View {
        VStack(spacing: BudgetDesignSystem.Spacing.xl) {
            // Header with icon and title
            HStack(spacing: BudgetDesignSystem.Spacing.lg) {
                Text(step.illustration)
                    .font(.system(size: 56))
                    .foregroundColor(iconColor(for: step.targetElement ?? ""))
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(titleScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: iconRotation)

                VStack(alignment: .leading, spacing: BudgetDesignSystem.Spacing.sm) {
                    Text(step.title)
                        .font(BudgetDesignSystem.Typography.title1)
                        .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                        .scaleEffect(titleScale)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: titleScale)

                    if step.interactionType != .automatic {
                        InteractionHint(type: step.interactionType)
                    }
                }

                Spacer()
            }

            // Description
            if let description = step.content {
                Text(description)
                    .font(BudgetDesignSystem.Typography.body)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }

            // Interactive element based on step type
            interactiveElement(for: step)
        }
    }

    // MARK: - Interactive Elements
    @ViewBuilder
    private func interactiveElement(for step: OnboardingStep) -> some View {
        switch step.targetElement {
        case "budget_creation":
            MockBudgetCreator()
        case "period_picker":
            MockPeriodPicker()
        case "categories":
            MockCategorySelector()
        case "planning":
            MockBudgetPlanner()
        case "transactions":
            MockTransactionEntry()
        case "analytics":
            MockAnalyticsPreview()
        case "broken_feature":
            MockBrokenFeature()
        case "error_handling":
            MockErrorScreen()
        case "completion":
            CompletionCelebration()
        default:
            EmptyView()
        }
    }

    // MARK: - Navigation Buttons
    private var onboardingNavigationButtons: some View {
        HStack(spacing: BudgetDesignSystem.Spacing.md) {
            if coordinator.canGoBack {
                Button(action: {
                    hapticManager.buttonTap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.goToPreviousStep()
                    }
                }) {
                    HStack(spacing: BudgetDesignSystem.Spacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(BudgetDesignSystem.Typography.body)
                    .foregroundColor(BudgetDesignSystem.Colors.primary)
                    .padding(.horizontal, BudgetDesignSystem.Spacing.lg)
                    .padding(.vertical, BudgetDesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(BudgetDesignSystem.Colors.primary.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            if coordinator.canSkip {
                Button(action: {
                    hapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.skipOnboarding()
                    }
                }) {
                    Text("Skip")
                        .font(BudgetDesignSystem.Typography.body)
                        .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                        .padding(.horizontal, BudgetDesignSystem.Spacing.lg)
                        .padding(.vertical, BudgetDesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(BudgetDesignSystem.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(BudgetDesignSystem.Colors.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button(action: {
                if coordinator.currentStepIndex < coordinator.steps.count - 1 {
                    hapticManager.buttonTap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.advanceToNextStep()
                    }
                } else {
                    hapticManager.playSuccessPattern()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        coordinator.completeOnboarding()
                    }
                }
            }) {
                HStack(spacing: BudgetDesignSystem.Spacing.sm) {
                    Text(coordinator.currentStepIndex < coordinator.steps.count - 1 ? "Next" : "Get Started")
                    Image(systemName: coordinator.currentStepIndex < coordinator.steps.count - 1 ? "chevron.right" : "checkmark")
                }
                .font(BudgetDesignSystem.Typography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, BudgetDesignSystem.Spacing.xl)
                .padding(.vertical, BudgetDesignSystem.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [
                            BudgetDesignSystem.Colors.primary,
                            BudgetDesignSystem.Colors.primaryLight
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(
                        color: BudgetDesignSystem.Colors.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                )
                .scaleEffect(buttonHoverScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonHoverScale)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    buttonHoverScale = isHovering ? 1.05 : 1.0
                }
            }
        }
    }

    // MARK: - Helpers
    private func iconColor(for elementId: String) -> Color {
        switch elementId {
        case "welcome": return BudgetDesignSystem.Colors.primary
        case "budget_creation": return BudgetDesignSystem.Colors.success
        case "period_picker": return BudgetDesignSystem.Colors.warning
        case "categories": return BudgetDesignSystem.Colors.primaryLight
        case "planning": return BudgetDesignSystem.Colors.savings
        case "transactions": return BudgetDesignSystem.Colors.expense
        case "analytics": return BudgetDesignSystem.Colors.primary
        case "broken_feature": return BudgetDesignSystem.Colors.warning
        case "error_handling": return BudgetDesignSystem.Colors.expense
        case "completion": return BudgetDesignSystem.Colors.success
        default: return BudgetDesignSystem.Colors.primary
        }
    }
}

// MARK: - Mock Broken Feature Component
struct MockBrokenFeature: View {
    @State private var isLoading = false
    @State private var showError = false
    @State private var retryCount = 0

    var body: some View {
        VStack(spacing: BudgetDesignSystem.Spacing.lg) {
            // Sync status indicator
            HStack {
                Circle()
                    .fill(BudgetDesignSystem.Colors.warning)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isLoading ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)

                Text("Cloud Sync")
                    .font(BudgetDesignSystem.Typography.body)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)

                Spacer()

                if showError {
                    Text("❌")
                        .font(.title2)
                } else {
                    Text("🔄")
                        .font(.title2)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: isLoading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(BudgetDesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(BudgetDesignSystem.Colors.warning.opacity(0.5), lineWidth: 1)
                    )
            )

            // Error message
            if showError {
                VStack(alignment: .leading, spacing: BudgetDesignSystem.Spacing.sm) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(BudgetDesignSystem.Colors.warning)
                        Text("Sync Failed")
                            .font(BudgetDesignSystem.Typography.bodyMedium)
                            .foregroundColor(BudgetDesignSystem.Colors.warning)
                    }

                    Text("Unable to connect to sync service. Please check your internet connection and try again.")
                        .font(BudgetDesignSystem.Typography.caption1)
                        .foregroundColor(BudgetDesignSystem.Colors.textSecondary)

                    Text("Error Code: SYNC_503")
                        .font(BudgetDesignSystem.Typography.caption1)
                        .foregroundColor(BudgetDesignSystem.Colors.textSecondary.opacity(0.7))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BudgetDesignSystem.Colors.warning.opacity(0.1))
                )
            }

            // Retry button
            Button(action: {
                isLoading = true
                showError = false
                retryCount += 1

                // Simulate failed sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isLoading = false
                    showError = true
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Sync (\(retryCount))")
                    }
                }
                .font(BudgetDesignSystem.Typography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, BudgetDesignSystem.Spacing.lg)
                .padding(.vertical, BudgetDesignSystem.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [BudgetDesignSystem.Colors.warning, BudgetDesignSystem.Colors.warning.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )
            }
            .disabled(isLoading)

            // Alternative actions
            VStack(spacing: BudgetDesignSystem.Spacing.sm) {
                Text("While we fix the sync issue:")
                    .font(BudgetDesignSystem.Typography.caption1)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)

                HStack(spacing: BudgetDesignSystem.Spacing.md) {
                    Button("Work Offline") {
                        // Simulate offline mode
                    }
                    .font(BudgetDesignSystem.Typography.caption1)
                    .foregroundColor(BudgetDesignSystem.Colors.primary)
                    .padding(.horizontal, BudgetDesignSystem.Spacing.md)
                    .padding(.vertical, BudgetDesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BudgetDesignSystem.Colors.primary.opacity(0.1))
                    )

                    Button("Skip This") {
                        // Skip sync for now
                    }
                    .font(BudgetDesignSystem.Typography.caption1)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                    .padding(.horizontal, BudgetDesignSystem.Spacing.md)
                    .padding(.vertical, BudgetDesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BudgetDesignSystem.Colors.surface)
                    )
                }
            }
        }
        .onAppear {
            // Start with loading state
            isLoading = true

            // Show error after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isLoading = false
                showError = true
            }
        }
    }
}

// MARK: - Mock Error Screen Component
struct MockErrorScreen: View {
    @State private var selectedError = 0
    private let errorTypes = [
        "Network Connection Lost",
        "Server Maintenance",
        "Data Corrupted",
        "Authentication Failed",
        "Feature Not Available"
    ]

    var body: some View {
        VStack(spacing: BudgetDesignSystem.Spacing.lg) {
            // Error header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(BudgetDesignSystem.Colors.expense)

                Text("Error Demonstration")
                    .font(BudgetDesignSystem.Typography.title3)
                    .foregroundColor(BudgetDesignSystem.Colors.textPrimary)

                Spacer()
            }

            // Error picker
            VStack(alignment: .leading, spacing: BudgetDesignSystem.Spacing.sm) {
                Text("Select Error Type:")
                    .font(BudgetDesignSystem.Typography.bodyMedium)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)

                Picker("Error Type", selection: $selectedError) {
                    ForEach(0..<errorTypes.count, id: \.self) { index in
                        Text(errorTypes[index]).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BudgetDesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(BudgetDesignSystem.Colors.border, lineWidth: 1)
                        )
                )
            }

            // Error display
            VStack(alignment: .leading, spacing: BudgetDesignSystem.Spacing.md) {
                // Error title and code
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(BudgetDesignSystem.Colors.expense)

                    Text(errorTypes[selectedError])
                        .font(BudgetDesignSystem.Typography.bodyMedium)
                        .foregroundColor(BudgetDesignSystem.Colors.expense)

                    Spacer()

                    Text("Error: \(String(format: "%03d", selectedError + 500))")
                        .font(BudgetDesignSystem.Typography.caption1)
                        .foregroundColor(BudgetDesignSystem.Colors.textSecondary.opacity(0.7))
                }

                // Error description
                Text("This is a demonstration of how the app handles errors gracefully. When something goes wrong, you'll see clear error messages with actionable information.")
                    .font(BudgetDesignSystem.Typography.body)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                    .lineSpacing(2)

                // Suggested actions
                VStack(alignment: .leading, spacing: BudgetDesignSystem.Spacing.sm) {
                    Text("Suggested Actions:")
                        .font(BudgetDesignSystem.Typography.bodyMedium)
                        .foregroundColor(BudgetDesignSystem.Colors.textPrimary)

                    VStack(alignment: .leading, spacing: BudgetDesignSystem.Spacing.xs) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(BudgetDesignSystem.Colors.success)
                            Text("Check your internet connection")
                                .font(BudgetDesignSystem.Typography.caption1)
                                .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                        }

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(BudgetDesignSystem.Colors.success)
                            Text("Restart the app")
                                .font(BudgetDesignSystem.Typography.caption1)
                                .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                        }

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(BudgetDesignSystem.Colors.success)
                            Text("Try again later")
                                .font(BudgetDesignSystem.Typography.caption1)
                                .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BudgetDesignSystem.Colors.success.opacity(0.1))
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(BudgetDesignSystem.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BudgetDesignSystem.Colors.expense.opacity(0.3), lineWidth: 1)
                    )
            )

            // Action buttons
            HStack(spacing: BudgetDesignSystem.Spacing.md) {
                Button("Report Issue") {
                    // Simulate reporting
                }
                .font(BudgetDesignSystem.Typography.bodyMedium)
                .foregroundColor(BudgetDesignSystem.Colors.primary)
                .padding(.horizontal, BudgetDesignSystem.Spacing.lg)
                .padding(.vertical, BudgetDesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BudgetDesignSystem.Colors.primary.opacity(0.1))
                )

                Button("Dismiss") {
                    // Dismiss error
                }
                .font(BudgetDesignSystem.Typography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, BudgetDesignSystem.Spacing.lg)
                .padding(.vertical, BudgetDesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BudgetDesignSystem.Colors.primary)
                )
            }
        }
    }
}