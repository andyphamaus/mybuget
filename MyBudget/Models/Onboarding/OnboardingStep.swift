import SwiftUI

// MARK: - Onboarding Step Model

struct OnboardingStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let content: String? // Additional content (optional)
    let illustration: String // SF Symbol or emoji
    let actionText: String
    let interactionType: InteractionType
    let targetElement: String?
    let position: StepPosition
    let order: Int
    let isSkippable: Bool
    let autoAdvance: Bool
    let duration: TimeInterval? // For auto-advance steps

    enum InteractionType: String, CaseIterable {
        case tap = "tap"
        case swipe = "swipe"
        case drag = "drag"
        case interactive = "interactive"
        case automatic = "automatic"

        var iconName: String {
            switch self {
            case .tap: return "hand.tap.fill"
            case .swipe: return "hand.wave.fill"
            case .drag: return "hand.drag.fill"
            case .interactive: return "person.fill.questionmark"
            case .automatic: return "clock.fill"
            }
        }
    }

    enum StepPosition: String, CaseIterable {
        case center = "center"
        case top = "top"
        case bottom = "bottom"
        case topLeft = "topLeft"
        case topRight = "topRight"
        case bottomLeft = "bottomLeft"
        case bottomRight = "bottomRight"
    }

    // MARK: - Initializers

    init(
        title: String,
        description: String,
        content: String? = nil,
        illustration: String = "sparkles",
        actionText: String = "Continue",
        interactionType: InteractionType = .tap,
        targetElement: String? = nil,
        position: StepPosition = .center,
        order: Int,
        isSkippable: Bool = true,
        autoAdvance: Bool = false,
        duration: TimeInterval? = nil
    ) {
        self.title = title
        self.description = description
        self.content = content
        self.illustration = illustration
        self.actionText = actionText
        self.interactionType = interactionType
        self.targetElement = targetElement
        self.position = position
        self.order = order
        self.isSkippable = isSkippable
        self.autoAdvance = autoAdvance
        self.duration = duration
    }

    // MARK: - Computed Properties

    var hasAction: Bool {
        interactionType != .automatic
    }

    var shouldAutoAdvance: Bool {
        autoAdvance || interactionType == .automatic
    }

    var isLastStep: Bool {
        // This will be set by the coordinator
        false
    }

    // MARK: - Static Methods

    static func == (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Budget Onboarding Steps Factory

extension OnboardingStep {

    static var budgetOnboardingSteps: [OnboardingStep] {
        return [
            // Step 1: Welcome & Overview
            OnboardingStep(
                title: "Welcome to Budget Management! 💰",
                description: "Take control of your finances with smart budgeting tools. Track expenses, plan ahead, and achieve your financial goals with style.",
                illustration: "💰",
                actionText: "Let's Start!",
                interactionType: .tap,
                order: 1
            ),

            // Step 2: Budget Concept
            OnboardingStep(
                title: "Understanding Budgets 📊",
                description: "A budget is your financial plan. Create separate budgets for different purposes - personal, business, or projects. Each budget has its own categories and tracking.",
                illustration: "📊",
                actionText: "Got it!",
                interactionType: .tap,
                targetElement: "budget_header",
                order: 2
            ),

            // Step 3: Period Management
            OnboardingStep(
                title: "Budget Periods ⏰",
                description: "Organize your finances by time periods - monthly, quarterly, or custom ranges. Each period tracks your income and expenses separately.",
                illustration: "⏰",
                actionText: "Makes sense",
                interactionType: .tap,
                targetElement: "period_picker",
                order: 3
            ),

            // Step 4: Categories & Sections
            OnboardingStep(
                title: "Categories & Sections 🗂️",
                description: "Organize your money into categories like 'Income', 'Housing', 'Food', etc. Group related categories into sections for better organization.",
                illustration: "🗂️",
                actionText: "Show me more",
                interactionType: .tap,
                targetElement: "category_list",
                order: 4
            ),

            // Step 5: Income vs Expenses
            OnboardingStep(
                title: "Income vs Expenses 💸",
                description: "Income categories track money coming in (salary, freelance). Expense categories track money going out (rent, groceries). Understanding this difference is key!",
                illustration: "💸",
                actionText: "That's important!",
                interactionType: .tap,
                order: 5
            ),

            // Step 6: Planning Your Budget
            OnboardingStep(
                title: "Planning Your Budget 📝",
                description: "Set target amounts for each category. Plan how much you expect to earn and how much you want to spend. This becomes your financial roadmap.",
                illustration: "📝",
                actionText: "Let's plan!",
                interactionType: .interactive,
                targetElement: "planning_slider",
                order: 6
            ),

            // Step 7: Adding Transactions
            OnboardingStep(
                title: "Track Your Spending 💳",
                description: "Add transactions to see how you're doing against your plan. Quick entry makes it easy to stay on top of your finances daily.",
                illustration: "💳",
                actionText: "Add transaction",
                interactionType: .interactive,
                targetElement: "transaction_entry",
                order: 7
            ),

            // Step 8: Analytics & Insights
            OnboardingStep(
                title: "Discover Insights 📈",
                description: "View detailed analytics to understand your spending patterns. See trends, forecasts, and get actionable insights to improve your financial health.",
                illustration: "📈",
                actionText: "Explore Analytics",
                interactionType: .tap,
                targetElement: "analytics_chart",
                order: 8
            )
        ]
    }
}

// MARK: - Step Extensions for Animations

extension OnboardingStep {

    var entryAnimation: AnyTransition {
        switch position {
        case .center:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale),
                removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale)
            )
        case .top, .topLeft, .topRight:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .bottom, .bottomLeft, .bottomRight:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        }
    }

    var preferredAlignment: Alignment {
        switch position {
        case .center: return .center
        case .top: return .top
        case .bottom: return .bottom
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - Preview Support

extension OnboardingStep {
    static let preview = OnboardingStep(
        title: "Welcome to MyBudget",
        description: "This is a preview step for testing the onboarding system with premium animations and interactions.",
        content: "Additional content for testing purposes",
        illustration: "✨",
        actionText: "Continue",
        interactionType: .tap,
        order: 1
    )
}