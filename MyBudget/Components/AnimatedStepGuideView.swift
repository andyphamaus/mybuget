import SwiftUI

// MARK: - Animated Step-by-Step Guide (Phase 4.4)

// MARK: - Step Guide Configuration

struct StepGuideConfiguration {
    let id: String
    let title: String
    let steps: [GuideStep]
    let animationStyle: GuideAnimationStyle
    let navigationStyle: GuideNavigationStyle
    let showProgress: Bool
    let allowSkipping: Bool
    let autoAdvance: Bool
    let autoAdvanceDelay: TimeInterval
    let isPersonalized: Bool
    
    init(
        id: String,
        title: String,
        steps: [GuideStep],
        animationStyle: GuideAnimationStyle = .slideHorizontal,
        navigationStyle: GuideNavigationStyle = .buttons,
        showProgress: Bool = true,
        allowSkipping: Bool = true,
        autoAdvance: Bool = false,
        autoAdvanceDelay: TimeInterval = 3.0,
        isPersonalized: Bool = true
    ) {
        self.id = id
        self.title = title
        self.steps = steps
        self.animationStyle = animationStyle
        self.navigationStyle = navigationStyle
        self.showProgress = showProgress
        self.allowSkipping = allowSkipping
        self.autoAdvance = autoAdvance
        self.autoAdvanceDelay = autoAdvanceDelay
        self.isPersonalized = isPersonalized
    }
}

struct GuideStep: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let animation: StepAnimation?
    let illustration: StepIllustration?
    let interactionHint: String?
    let requiredAction: StepAction?
    let duration: TimeInterval
    let personalizedContent: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        animation: StepAnimation? = nil,
        illustration: StepIllustration? = nil,
        interactionHint: String? = nil,
        requiredAction: StepAction? = nil,
        duration: TimeInterval = 2.0,
        personalizedContent: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.animation = animation
        self.illustration = illustration
        self.interactionHint = interactionHint
        self.requiredAction = requiredAction
        self.duration = duration
        self.personalizedContent = personalizedContent
    }
}

enum GuideAnimationStyle {
    case slideHorizontal
    case slideVertical
    case fade
    case scale
    case flip
    case carousel
    case parallax
}

enum GuideNavigationStyle {
    case buttons
    case swipe
    case tap
    case auto
    case mixed
}

struct StepAnimation {
    let type: AnimationType
    let duration: TimeInterval
    let delay: TimeInterval
    let repeatCount: Int?
    
    enum AnimationType {
        case bounce
        case pulse
        case rotate
        case shake
        case wave
        case typewriter
        case morph
    }
}

struct StepIllustration {
    let type: IllustrationType
    let content: String
    let highlightElements: [String]
    
    enum IllustrationType {
        case image
        case lottie
        case systemIcon
        case customIcon
        case screenshot
    }
}

struct StepAction {
    let type: ActionType
    let targetElement: String?
    let expectedResult: String?
    
    enum ActionType {
        case tap
        case swipe(direction: GestureDirection)
        case longPress
        case input(placeholder: String)
        case custom(identifier: String)
    }
}

// MARK: - Animated Step Guide View

struct AnimatedStepGuideView: View {
    @StateObject private var guideState = StepGuideState()
    // @EnvironmentObject var personalizationEngine: PersonalizationEngine
    @Environment(\.dismiss) private var dismiss
    
    let configuration: StepGuideConfiguration
    let onCompletion: (() -> Void)?
    let onStepComplete: ((GuideStep) -> Void)?
    
    @State private var currentStepIndex = 0
    @State private var isAnimating = false
    @State private var showStepContent = false
    @State private var autoAdvanceTimer: Timer?
    
    init(
        configuration: StepGuideConfiguration,
        onCompletion: (() -> Void)? = nil,
        onStepComplete: ((GuideStep) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.onCompletion = onCompletion
        self.onStepComplete = onStepComplete
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    // Main content area
                    ZStack {
                        ForEach(Array(configuration.steps.enumerated()), id: \.element.id) { index, step in
                            StepContentView(
                                step: personalizeStep(step),
                                isActive: index == currentStepIndex,
                                animationStyle: configuration.animationStyle,
                                geometry: geometry
                            )
                            .opacity(index == currentStepIndex ? 1.0 : 0.0)
                            .scaleEffect(index == currentStepIndex ? 1.0 : 0.9)
                            .offset(x: calculateStepOffset(index: index, geometry: geometry))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Navigation controls
                    navigationControls
                }
            }
        }
        .onAppear {
            setupGuide()
            startGuide()
        }
        .onDisappear {
            autoAdvanceTimer?.invalidate()
        }
        .gesture(
            configuration.navigationStyle == .swipe || configuration.navigationStyle == .mixed ?
            DragGesture()
                .onEnded(handleSwipeGesture) : nil
        )
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                BudgetDesignSystem.Colors.primary.opacity(0.1),
                BudgetDesignSystem.Colors.background,
                BudgetDesignSystem.Colors.surfaceSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text(configuration.title)
                    .font(BudgetDesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if configuration.allowSkipping {
                    Button("Skip") {
                        completeGuide()
                    }
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress indicator
            if configuration.showProgress {
                StepProgressView(
                    currentStep: currentStepIndex,
                    totalSteps: configuration.steps.count,
                    animationStyle: configuration.animationStyle
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Navigation Controls
    
    private var navigationControls: some View {
        VStack(spacing: 16) {
            if configuration.navigationStyle == .buttons || configuration.navigationStyle == .mixed {
                HStack(spacing: 20) {
                    // Previous button
                    if currentStepIndex > 0 {
                        Button(action: goToPreviousStep) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Previous")
                            }
                            .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(BudgetDesignSystem.Colors.surfaceSecondary)
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Complete button
                    Button(action: handleNextAction) {
                        HStack(spacing: 8) {
                            Text(isLastStep ? "Complete" : "Next")
                            
                            if !isLastStep {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(BudgetDesignSystem.Colors.primary)
                        .cornerRadius(8)
                    }
                    .disabled(isAnimating)
                }
                .padding(.horizontal, 20)
            }
            
            // Gesture hint
            if configuration.navigationStyle == .swipe || configuration.navigationStyle == .mixed {
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 12))
                        .foregroundColor(BudgetDesignSystem.Colors.textTertiary)
                    
                    Text("Swipe to navigate")
                        .font(BudgetDesignSystem.Typography.caption2)
                        .foregroundColor(BudgetDesignSystem.Colors.textTertiary)
                }
            }
            
            // Step dots indicator
            StepDotsIndicator(
                currentStep: currentStepIndex,
                totalSteps: configuration.steps.count,
                onStepTap: { index in
                    goToStep(index)
                }
            )
            .padding(.top, 8)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Properties
    
    private var isLastStep: Bool {
        currentStepIndex >= configuration.steps.count - 1
    }
    
    private var currentStep: GuideStep? {
        guard currentStepIndex < configuration.steps.count else { return nil }
        return configuration.steps[currentStepIndex]
    }
    
    // MARK: - Navigation Methods
    
    private func goToNextStep() {
        guard !isAnimating, currentStepIndex < configuration.steps.count - 1 else { return }
        
        withAnimation(animationForStyle(configuration.animationStyle)) {
            isAnimating = true
            currentStepIndex += 1
        }
        
        // Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
            onStepComplete?(configuration.steps[currentStepIndex])
            
            // Setup auto-advance if enabled
            if configuration.autoAdvance && !isLastStep {
                scheduleAutoAdvance()
            }
        }
    }
    
    private func goToPreviousStep() {
        guard !isAnimating, currentStepIndex > 0 else { return }
        
        withAnimation(animationForStyle(configuration.animationStyle)) {
            isAnimating = true
            currentStepIndex -= 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
    
    private func goToStep(_ index: Int) {
        guard !isAnimating,
              index >= 0,
              index < configuration.steps.count,
              index != currentStepIndex else { return }
        
        withAnimation(animationForStyle(configuration.animationStyle)) {
            isAnimating = true
            currentStepIndex = index
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
    
    private func handleNextAction() {
        if isLastStep {
            completeGuide()
        } else {
            goToNextStep()
        }
    }
    
    private func completeGuide() {
        onCompletion?()
        dismiss()
    }
    
    // MARK: - Gesture Handling
    
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let threshold: CGFloat = 50
        
        if value.translation.width > threshold {
            // Swipe right - go to previous step
            goToPreviousStep()
        } else if value.translation.width < -threshold {
            // Swipe left - go to next step
            if isLastStep {
                completeGuide()
            } else {
                goToNextStep()
            }
        }
    }
    
    // MARK: - Animation Helpers
    
    private func animationForStyle(_ style: GuideAnimationStyle) -> Animation {
        switch style {
        case .slideHorizontal, .slideVertical:
            return .easeInOut(duration: 0.4)
        case .fade:
            return .easeIn(duration: 0.3)
        case .scale:
            return .spring(response: 0.5, dampingFraction: 0.8)
        case .flip:
            return .easeInOut(duration: 0.6)
        case .carousel:
            return .easeInOut(duration: 0.5)
        case .parallax:
            return .easeOut(duration: 0.4)
        }
    }
    
    private func calculateStepOffset(index: Int, geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        switch configuration.animationStyle {
        case .slideHorizontal:
            return CGFloat(index - currentStepIndex) * screenWidth
        case .carousel:
            let offset = CGFloat(index - currentStepIndex) * (screenWidth * 0.8)
            return offset
        default:
            return 0
        }
    }
    
    // MARK: - Setup and Auto-advance
    
    private func setupGuide() {
        guideState.startGuide(configuration)
    }
    
    private func startGuide() {
        if configuration.autoAdvance && !isLastStep {
            scheduleAutoAdvance()
        }
    }
    
    private func scheduleAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: configuration.autoAdvanceDelay, repeats: false) { _ in
            goToNextStep()
        }
    }
    
    // MARK: - Personalization
    
    private func personalizeStep(_ step: GuideStep) -> GuideStep {
        guard step.personalizedContent else { return step }
        
        let personalizedDescription = step.description // Simplified without personalization engine
        
        return GuideStep(
            id: step.id,
            title: step.title,
            description: personalizedDescription,
            icon: step.icon,
            animation: step.animation,
            illustration: step.illustration,
            interactionHint: step.interactionHint,
            requiredAction: step.requiredAction,
            duration: step.duration,
            personalizedContent: step.personalizedContent
        )
    }
}

// MARK: - Step Content View

struct StepContentView: View {
    let step: GuideStep
    let isActive: Bool
    let animationStyle: GuideAnimationStyle
    let geometry: GeometryProxy
    
    @State private var isContentVisible = false
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // Step illustration/icon
            stepIllustration
                .scaleEffect(isContentVisible ? 1.0 : 0.8)
                .offset(y: animationOffset)
            
            // Step content
            VStack(spacing: 20) {
                Text(step.title)
                    .font(BudgetDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isContentVisible ? 1.0 : 0.0)
                
                Text(step.description)
                    .font(BudgetDesignSystem.Typography.body)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(isContentVisible ? 1.0 : 0.0)
                
                // Interaction hint
                if let hint = step.interactionHint {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.point.up.left")
                            .font(.system(size: 16))
                            .foregroundColor(BudgetDesignSystem.Colors.primary)
                        
                        Text(hint)
                            .font(BudgetDesignSystem.Typography.caption1)
                            .foregroundColor(BudgetDesignSystem.Colors.primary)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(BudgetDesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                    .opacity(isContentVisible ? 1.0 : 0.0)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isActive) { active in
            if active {
                showStepContent()
            } else {
                hideStepContent()
            }
        }
        .onAppear {
            if isActive {
                showStepContent()
            }
        }
    }
    
    // MARK: - Step Illustration
    
    private var stepIllustration: some View {
        Group {
            if let illustration = step.illustration {
                switch illustration.type {
                case .systemIcon:
                    Image(systemName: illustration.content)
                        .font(.system(size: 64))
                        .foregroundColor(BudgetDesignSystem.Colors.primary)
                case .customIcon, .image:
                    Image(illustration.content)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                default:
                    Image(systemName: step.icon)
                        .font(.system(size: 64))
                        .foregroundColor(BudgetDesignSystem.Colors.primary)
                }
            } else {
                Image(systemName: step.icon)
                    .font(.system(size: 64))
                    .foregroundColor(BudgetDesignSystem.Colors.primary)
            }
        }
        .frame(width: 120, height: 120)
        .background(
            Circle()
                .fill(BudgetDesignSystem.Colors.primary.opacity(0.1))
        )
    }
    
    // MARK: - Animation Methods
    
    private func showStepContent() {
        withAnimation(.easeOut(duration: 0.6)) {
            isContentVisible = true
            animationOffset = 0
        }
        
        // Apply step-specific animation if defined
        if let animation = step.animation {
            applyStepAnimation(animation)
        }
    }
    
    private func hideStepContent() {
        withAnimation(.easeIn(duration: 0.3)) {
            isContentVisible = false
            animationOffset = -20
        }
    }
    
    private func applyStepAnimation(_ animation: StepAnimation) {
        // Apply custom animations based on the step configuration
        switch animation.type {
        case .bounce:
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 8).delay(animation.delay)) {
                // Bounce effect would be applied here
            }
        case .pulse:
            // Pulsing animation would be implemented
            break
        case .rotate:
            // Rotation animation would be implemented
            break
        default:
            break
        }
    }
}

// MARK: - Step Progress View

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let animationStyle: GuideAnimationStyle
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(BudgetDesignSystem.Typography.caption1)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(BudgetDesignSystem.Typography.caption1)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(BudgetDesignSystem.Colors.surfaceSecondary)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(BudgetDesignSystem.Colors.primary)
                        .frame(width: geometry.size.width * progressPercentage, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.4), value: progressPercentage)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var progressPercentage: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep + 1) / Double(totalSteps)
    }
}

// MARK: - Step Dots Indicator

struct StepDotsIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let onStepTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(
                        index <= currentStep ?
                        BudgetDesignSystem.Colors.primary :
                        BudgetDesignSystem.Colors.surfaceSecondary
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentStep ? 1.3 : 1.0)
                    .onTapGesture {
                        onStepTap(index)
                    }
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Step Guide State

@MainActor
class StepGuideState: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentConfiguration: StepGuideConfiguration?
    @Published var startTime: Date?
    @Published var stepTimes: [TimeInterval] = []
    
    func startGuide(_ configuration: StepGuideConfiguration) {
        self.currentConfiguration = configuration
        self.isActive = true
        self.startTime = Date()
    }
    
    func completeGuide() {
        guard let startTime = startTime else { return }
        let totalTime = Date().timeIntervalSince(startTime)
        
        
        // Reset state
        isActive = false
        currentConfiguration = nil
        self.startTime = nil
        stepTimes.removeAll()
    }
    
    func recordStepTime(_ duration: TimeInterval) {
        stepTimes.append(duration)
    }
}

// MARK: - Predefined Step Guides

extension AnimatedStepGuideView {
    static func budgetBasicsGuide() -> StepGuideConfiguration {
        let steps = [
            GuideStep(
                title: "Welcome to Budgeting!",
                description: "Let's learn the basics of creating and managing your budget. This guide will walk you through each step.",
                icon: "hand.wave.fill",
                interactionHint: "Swipe left or tap Next to continue"
            ),
            GuideStep(
                title: "Track Your Income",
                description: "Start by adding all sources of income. Include your salary, freelance work, and any other regular payments.",
                icon: "dollarsign.circle.fill",
                interactionHint: "Remember to include all income sources for accurate budgeting"
            ),
            GuideStep(
                title: "List Your Expenses",
                description: "Add your monthly expenses, starting with fixed costs like rent, then variable costs like groceries.",
                icon: "list.bullet.rectangle.fill",
                interactionHint: "Don't forget small recurring payments like subscriptions"
            ),
            GuideStep(
                title: "Set Your Goals",
                description: "Define your financial goals. Whether it's saving for emergencies, paying off debt, or planning for a big purchase.",
                icon: "target",
                interactionHint: "Specific goals help you stay motivated"
            ),
            GuideStep(
                title: "You're All Set!",
                description: "Great job! You now have the foundation for successful budgeting. Keep tracking and adjusting as needed.",
                icon: "checkmark.seal.fill",
                interactionHint: "Tap Complete to finish the guide"
            )
        ]
        
        return StepGuideConfiguration(
            id: "budget_basics_guide",
            title: "Budget Basics Guide",
            steps: steps,
            animationStyle: .slideHorizontal,
            navigationStyle: .mixed,
            showProgress: true,
            allowSkipping: true,
            autoAdvance: false
        )
    }
}

// MARK: - Preview

struct AnimatedStepGuideView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedStepGuideView(
            configuration: AnimatedStepGuideView.budgetBasicsGuide()
        )
        // .environmentObject(PersonalizationEngine())
    }
}
