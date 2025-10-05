import SwiftUI
import Combine


// MARK: - Onboarding Coordinator
@MainActor
class OnboardingCoordinator: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var isActive: Bool = false
    @Published private(set) var isCompleted: Bool = false
    @Published var showSkipOption: Bool = true
    @Published var highlightedElementId: String?
    @Published var tooltipPosition: TooltipPosition = .bottom

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var stepTimer: Timer?
    private let hapticManager = HapticManager()

    // Animation States
    @Published var cardAnimation: CardAnimationState = .idle
    @Published var backgroundAnimation: BackgroundAnimationState = .static

    enum CardAnimationState {
        case idle
        case entering
        case active
        case exiting
    }

    enum BackgroundAnimationState {
        case `static`
        case animated
        case transitioning
    }

    enum TooltipPosition {
        case top
        case bottom
        case leading
        case trailing
        case center
    }

    // MARK: - Onboarding Steps
    let steps: [OnboardingStep] = OnboardingStep.budgetOnboardingSteps

    // MARK: - Computed Properties
    var currentStep: OnboardingStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var canSkip: Bool {
        showSkipOption && !isCompleted
    }

    var canGoBack: Bool {
        currentStepIndex > 0 && !isCompleted
    }

    // MARK: - Initialization
    init() {
        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Update progress when step changes
        $currentStepIndex
            .map { Double($0) / Double(self.steps.count - 1) }
            .assign(to: &$progress)

        // Update highlighted element when step changes
        $currentStepIndex
            .compactMap { self.steps[safe: $0]?.targetElement }
            .assign(to: &$highlightedElementId)
    }

    // MARK: - Public Methods
    func startOnboarding() {
        guard !isActive else { return }

        isActive = true
        isCompleted = false
        currentStepIndex = 0
        cardAnimation = .entering
        backgroundAnimation = .animated

        // Play welcome sound

        // Haptic feedback
        hapticManager.notification(.success)

        // Start first step
        processCurrentStep()

        // Save onboarding started
        // Onboarding started - no specific method needed
    }

    func advanceToNextStep() {
        guard currentStepIndex < steps.count - 1 else {
            completeOnboarding()
            return
        }

        // Animate card exit
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            cardAnimation = .exiting
        }

        // Advance after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }

            self.currentStepIndex += 1

            // Animate card entry
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                self.cardAnimation = .entering
            }

            // Process new step
            self.processCurrentStep()

            // Sound and haptic
            self.hapticManager.selection()
        }
    }

    func goToPreviousStep() {
        guard canGoBack else { return }

        currentStepIndex -= 1
        processCurrentStep()

        // Sound and haptic
        hapticManager.selection()
    }

    func skipOnboarding() {
        guard canSkip else { return }

        // Animate dismissal
        withAnimation(.easeOut(duration: 0.3)) {
            cardAnimation = .exiting
            backgroundAnimation = .static
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isActive = false
            OnboardingPreferences.skipOnboarding()
        }
    }

    func completeOnboarding() {
        isCompleted = true

        // Celebration animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            cardAnimation = .active
        }

        // Play success sound

        // Strong haptic
        hapticManager.notification(.success)

        // Mark as completed after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isActive = false
            OnboardingPreferences.completeOnboarding()
        }
    }

    func pauseOnboarding() {
        stepTimer?.invalidate()
        // Checkpoints not implemented - would need to add to OnboardingPreferences
    }

    func resumeFromCheckpoint() {
        // Checkpoints not implemented - just start normally
        startOnboarding()
    }

    // MARK: - Element Highlighting
    func shouldHighlight(_ elementId: String) -> Bool {
        isActive && highlightedElementId == elementId
    }

    func setTooltipPosition(for elementId: String, position: TooltipPosition) {
        if highlightedElementId == elementId {
            tooltipPosition = position
        }
    }

    // MARK: - Private Methods
    private func processCurrentStep() {
        guard let step = currentStep else { return }

        // Update animation state
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardAnimation = .active
        }

        // Handle automatic steps
        if step.interactionType == .automatic, let duration = step.duration, duration > 0 {
            stepTimer?.invalidate()
            stepTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.advanceToNextStep()
                }
            }
        }
    }

    // MARK: - Interactive Actions
    func handleInteraction(type: OnboardingStep.InteractionType) {
        guard let step = currentStep, step.interactionType == type else { return }
        advanceToNextStep()
    }

    func handleDragGesture(translation: CGSize) {
        guard let step = currentStep, step.interactionType == .drag else { return }

        // Advance if dragged far enough
        if abs(translation.width) > 150 || abs(translation.height) > 150 {
            advanceToNextStep()
        }
    }

    func handleTap() {
        guard let step = currentStep, step.interactionType == .tap else { return }
        advanceToNextStep()
    }
}

// MARK: - Array Safe Subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}