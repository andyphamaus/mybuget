import SwiftUI

// MARK: - Budget Onboarding Integration
struct BudgetOnboardingIntegration: ViewModifier {
    @StateObject private var coordinator = OnboardingCoordinator()
    @State private var showOnboarding = false

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showOnboarding) {
                SimpleOnboardingView()
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

// MARK: - Simple Onboarding View (temporary implementation)
struct SimpleOnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.green.opacity(0.8), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Title
                Text("Welcome to MyBudget!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Content
                if let step = coordinator.currentStep {
                    VStack(spacing: 20) {
                        Text(step.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        if let description = step.content {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }

                // Progress
                ProgressView(value: coordinator.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .scaleEffect(y: 2)
                    .padding(.horizontal)

                // Buttons
                HStack(spacing: 20) {
                    if coordinator.canGoBack {
                        Button("Previous") {
                            coordinator.goToPreviousStep()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(.white.opacity(0.2))
                        .cornerRadius(10)
                    }

                    if coordinator.canSkip {
                        Button("Skip") {
                            coordinator.skipOnboarding()
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                    }

                    Button(coordinator.currentStepIndex < coordinator.steps.count - 1 ? "Next" : "Get Started") {
                        if coordinator.currentStepIndex < coordinator.steps.count - 1 {
                            coordinator.advanceToNextStep()
                        } else {
                            coordinator.completeOnboarding()
                        }
                    }
                    .foregroundColor(.green)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                }
            }
            .padding(30)
        }
        .onAppear {
            coordinator.startOnboarding()
        }
        .onChange(of: coordinator.isCompleted) { completed in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
        .onChange(of: coordinator.isActive) { active in
            if !active {
                dismiss()
            }
        }
    }
}