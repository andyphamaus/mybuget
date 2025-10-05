import Foundation
import SwiftUI

// MARK: - Constants
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
    static let showOnboardingTutorial = Notification.Name("ShowOnboardingTutorial")
}

// MARK: - Onboarding Preferences Manager

class OnboardingPreferences {

    // MARK: - UserDefaults Keys
    private static let hasCompletedOnboardingKey = "MyBudget_HasCompletedOnboarding"
    private static let showOnboardingKey = "MyBudget_ShowOnboarding"
    private static let onboardingVersionKey = "MyBudget_OnboardingVersion"
    private static let lastShownDateKey = "MyBudget_OnboardingLastShown"
    private static let hasVisitedBudgetModuleKey = "MyBudget_HasVisitedBudgetModule"

    // MARK: - Current Version
    private static let currentOnboardingVersion = "1.0"

    // MARK: - Public Properties
    static var shouldShowOnboarding: Bool {
        get {
            // Always show if never completed
            guard hasCompletedOnboarding else { return true }

            // Check if user wants to see it again
            return UserDefaults.standard.bool(forKey: showOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showOnboardingKey)
        }
    }

    static var hasVisitedBudgetModule: Bool {
        get {
            return UserDefaults.standard.bool(forKey: hasVisitedBudgetModuleKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasVisitedBudgetModuleKey)
        }
    }

    // Auto-show logic: show onboarding for first-time Budget visitors who haven't completed or skipped
    static var shouldAutoShowOnboarding: Bool {
        return !hasVisitedBudgetModule && !hasCompletedOnboarding
    }

    static var hasCompletedOnboarding: Bool {
        get {
            return UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
            if newValue {
                UserDefaults.standard.set(currentOnboardingVersion, forKey: onboardingVersionKey)
                UserDefaults.standard.set(Date(), forKey: lastShownDateKey)
                shouldShowOnboarding = false // Automatically hide after completion
            }
        }
    }

    static var statusDescription: String {
        if hasCompletedOnboarding {
            return "Completed"
        } else {
            return "Not started"
        }
    }

    static var completedVersion: String? {
        return UserDefaults.standard.string(forKey: onboardingVersionKey)
    }

    static var lastShownDate: Date? {
        return UserDefaults.standard.object(forKey: lastShownDateKey) as? Date
    }

    // MARK: - Public Methods
    static func completeOnboarding() {
        hasCompletedOnboarding = true
        shouldShowOnboarding = false
        hasVisitedBudgetModule = true // Mark as visited when completing

        // Notify that onboarding is completed to trigger budget refresh
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    static func showTutorialAgain() {
        shouldShowOnboarding = true
    }

    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.removeObject(forKey: showOnboardingKey)
        UserDefaults.standard.removeObject(forKey: onboardingVersionKey)
        UserDefaults.standard.removeObject(forKey: lastShownDateKey)
        // Don't reset hasVisitedBudgetModule - this is for first-time detection only
    }

    static func skipOnboarding() {
        hasCompletedOnboarding = true
        shouldShowOnboarding = false
        hasVisitedBudgetModule = true // Mark as visited when skipping

        // Notify that onboarding is skipped to trigger budget refresh
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    static func markBudgetModuleVisited() {
        hasVisitedBudgetModule = true
    }

    // MARK: - Version Check
    static func shouldShowForVersionUpdate() -> Bool {
        guard let completedVersion = completedVersion else { return true }
        return completedVersion != currentOnboardingVersion
    }

    // MARK: - Analytics Support
    static func getOnboardingAnalytics() -> [String: Any] {
        return [
            "hasCompleted": hasCompletedOnboarding,
            "completedVersion": completedVersion ?? "none",
            "currentVersion": currentOnboardingVersion,
            "lastShownDate": lastShownDate?.timeIntervalSince1970 ?? 0,
            "shouldShow": shouldShowOnboarding
        ]
    }
}

// MARK: - SwiftUI Environment Support

struct OnboardingPreferencesKey: EnvironmentKey {
    typealias Value = OnboardingPreferences.Type
    static let defaultValue: OnboardingPreferences.Type = OnboardingPreferences.self
}

extension EnvironmentValues {
    var onboardingPreferences: OnboardingPreferences.Type {
        get { self[OnboardingPreferencesKey.self] }
        set { self[OnboardingPreferencesKey.self] = newValue }
    }
}

// MARK: - Property Wrapper for SwiftUI

@propertyWrapper
struct OnboardingState: DynamicProperty {
    @State private var shouldShow: Bool
    @State private var hasCompleted: Bool

    init() {
        self._shouldShow = State(initialValue: OnboardingPreferences.shouldShowOnboarding)
        self._hasCompleted = State(initialValue: OnboardingPreferences.hasCompletedOnboarding)
    }

    var wrappedValue: (shouldShow: Bool, hasCompleted: Bool) {
        get { (shouldShow, hasCompleted) }
        nonmutating set {
            shouldShow = newValue.shouldShow
            hasCompleted = newValue.hasCompleted
            OnboardingPreferences.shouldShowOnboarding = newValue.shouldShow
            OnboardingPreferences.hasCompletedOnboarding = newValue.hasCompleted
        }
    }

    var projectedValue: Binding<(shouldShow: Bool, hasCompleted: Bool)> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    mutating func update() {
        shouldShow = OnboardingPreferences.shouldShowOnboarding
        hasCompleted = OnboardingPreferences.hasCompletedOnboarding
    }
}