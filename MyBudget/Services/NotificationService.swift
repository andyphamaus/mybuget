import Foundation
import UserNotifications
import Combine
import CoreData

// MARK: - Notification Models

struct SmartNotification: Identifiable, Equatable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let priority: NotificationPriority
    let category: String?
    let actionButtons: [NotificationAction]
    let scheduledTime: Date?
    let badge: Int?
    let sound: NotificationSound
    let metadata: [String: Any]

    static func == (lhs: SmartNotification, rhs: SmartNotification) -> Bool {
        lhs.id == rhs.id
    }
}

enum NotificationType: String, CaseIterable {
    case budgetAlert = "budget_alert"
    case spendingWarning = "spending_warning"
    case anomalyDetection = "anomaly_detection"
    case goalAchieved = "goal_achieved"
    case weeklyReport = "weekly_report"
    case monthlyReport = "monthly_report"
    case reminderReview = "reminder_review"
    case insights = "insights"
}

enum NotificationPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"

    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .low: return .passive
        case .medium: return .active
        case .high: return .timeSensitive
        case .urgent: return .critical
        }
    }
}

enum NotificationSound: String, CaseIterable {
    case `default` = "default"
    case budgetAlert = "budget_alert"
    case achievement = "achievement"
    case warning = "warning"
    case gentle = "gentle"
    case none = "none"
}

struct NotificationAction {
    let identifier: String
    let title: String
    let isDestructive: Bool
    let requiresAuthentication: Bool
}

// MARK: - Smart Notification Service

@MainActor
class NotificationService: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var pendingNotifications: [SmartNotification] = []
    @Published var notificationHistory: [SmartNotification] = []
    @Published var settings = NotificationSettings()

    // MARK: - Private Properties
    private let center = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    private let persistenceController = PersistenceController.shared

    // Smart notification logic
    private var lastBudgetCheck: Date = Date.distantPast
    private var notificationCache: [String: Date] = [:]
    private let cooldownPeriod: TimeInterval = 3600 // 1 hour cooldown for similar notifications

    override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
        checkAuthorization()
    }

    // MARK: - Smart Notification Settings

    /// Check if smart notifications are enabled in user settings
    private func areSmartNotificationsEnabled() -> Bool {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()

        do {
            let users = try context.fetch(request)
            if let currentUser = users.first {
                return currentUser.smartNotificationsEnabled
            }
        } catch {
        }

        // Default to false if we can't determine the setting
        return false
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional, .criticalAlert])
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }

    private func checkAuthorization() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }

    // MARK: - Smart Notification Scheduling

    func scheduleSmartNotification(_ notification: SmartNotification) async {
        guard isAuthorized else {
            await requestAuthorization()
            return
        }

        // Check cooldown period
        let cacheKey = "\(notification.type.rawValue)_\(notification.category ?? "")"
        if let lastSent = notificationCache[cacheKey],
           Date().timeIntervalSince(lastSent) < cooldownPeriod {
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.categoryIdentifier = notification.type.rawValue

        // Set badge
        if let badge = notification.badge {
            content.badge = NSNumber(value: badge)
        }

        // Set sound
        switch notification.sound {
        case .default:
            content.sound = .default
        case .budgetAlert:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("budget_alert.caf"))
        case .achievement:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("achievement.caf"))
        case .warning:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("warning.caf"))
        case .gentle:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle.caf"))
        case .none:
            content.sound = nil
        }

        // Add metadata as user info
        content.userInfo = notification.metadata

        // Create trigger
        let trigger: UNNotificationTrigger?
        if let scheduledTime = notification.scheduledTime {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            // Immediate notification
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)

            // Update cache
            notificationCache[cacheKey] = Date()

            // Add to pending notifications
            pendingNotifications.append(notification)

        } catch {
        }
    }

    // MARK: - Budget-Specific Notifications

    func checkBudgetAlerts(
        transactions: [LocalTransaction],
        categories: [LocalCategory],
        plans: [LocalBudgetPeriodPlan],
        insights: [SmartInsight]
    ) async {

        // Early return if smart notifications are disabled
        guard areSmartNotificationsEnabled() else {
            return
        }

        // Limit frequency of budget checks
        guard Date().timeIntervalSince(lastBudgetCheck) > 1800 else { return } // 30 minutes
        lastBudgetCheck = Date()

        // Check for over-budget categories
        await checkOverBudgetAlerts(transactions: transactions, plans: plans, categories: categories)

        // Check for spending anomalies
        await checkAnomalyAlerts(insights: insights)

        // Check for achievement notifications
        await checkAchievementNotifications(transactions: transactions, categories: categories)

        // Schedule periodic reports
        await schedulePeriodicReports()
    }

    private func checkOverBudgetAlerts(
        transactions: [LocalTransaction],
        plans: [LocalBudgetPeriodPlan],
        categories: [LocalCategory]
    ) async {

        for plan in plans {
            guard let categoryId = plan.category?.id else { continue }

            let categoryTransactions = transactions.filter { $0.category?.id == categoryId }
            let actualSpent = categoryTransactions.reduce(0) { $0 + $1.amountInCurrency }
            let plannedAmount = plan.amountInCurrency

            let percentageUsed = plannedAmount > 0 ? (actualSpent / plannedAmount) * 100 : 0

            if percentageUsed > 100 {
                // Over budget alert
                let categoryName = categories.first { $0.id == categoryId }?.name ?? "Unknown Category"
                let overAmount = actualSpent - plannedAmount

                let notification = SmartNotification(
                    type: .budgetAlert,
                    title: "Budget Exceeded",
                    message: "You've exceeded your \(categoryName) budget by $\(Int(overAmount)). Consider reviewing your spending.",
                    priority: .high,
                    category: categoryId,
                    actionButtons: [
                        NotificationAction(identifier: "view_budget", title: "View Budget", isDestructive: false, requiresAuthentication: false),
                        NotificationAction(identifier: "adjust_plan", title: "Adjust Plan", isDestructive: false, requiresAuthentication: true)
                    ],
                    scheduledTime: nil,
                    badge: 1,
                    sound: .budgetAlert,
                    metadata: [
                        "categoryId": categoryId,
                        "overspentAmount": overAmount,
                        "actualSpent": actualSpent,
                        "plannedAmount": plannedAmount
                    ]
                )

                await scheduleSmartNotification(notification)

            } else if percentageUsed > 90 {
                // 90% warning
                let categoryName = categories.first { $0.id == categoryId }?.name ?? "Unknown Category"
                let remaining = plannedAmount - actualSpent

                let notification = SmartNotification(
                    type: .spendingWarning,
                    title: "Budget Warning",
                    message: "You've used 90% of your \(categoryName) budget. $\(Int(remaining)) remaining.",
                    priority: .medium,
                    category: categoryId,
                    actionButtons: [
                        NotificationAction(identifier: "view_spending", title: "View Spending", isDestructive: false, requiresAuthentication: false)
                    ],
                    scheduledTime: nil,
                    badge: nil,
                    sound: .warning,
                    metadata: [
                        "categoryId": categoryId,
                        "percentageUsed": percentageUsed,
                        "remaining": remaining
                    ]
                )

                await scheduleSmartNotification(notification)
            }
        }
    }

    private func checkAnomalyAlerts(insights: [SmartInsight]) async {
        let urgentAnomalies = insights.filter {
            $0.type == .anomaly && $0.priority == .urgent && !$0.isRead
        }

        for anomaly in urgentAnomalies.prefix(3) { // Limit to 3 urgent anomalies
            let notification = SmartNotification(
                type: .anomalyDetection,
                title: "Unusual Spending Detected",
                message: anomaly.description,
                priority: .high,
                category: anomaly.relatedCategoryId,
                actionButtons: [
                    NotificationAction(identifier: "view_insight", title: "View Details", isDestructive: false, requiresAuthentication: false),
                    NotificationAction(identifier: "mark_normal", title: "Mark as Normal", isDestructive: true, requiresAuthentication: false)
                ],
                scheduledTime: nil,
                badge: 1,
                sound: .warning,
                metadata: [
                    "insightId": anomaly.id.uuidString,
                    "categoryId": anomaly.relatedCategoryId ?? ""
                ]
            )

            await scheduleSmartNotification(notification)
        }
    }

    private func checkAchievementNotifications(
        transactions: [LocalTransaction],
        categories: [LocalCategory]
    ) async {

        // Check for spending streaks or improvements
        let thisMonthTransactions = transactions.filter { transaction in
            guard let dateString = transaction.transactionDate,
                  let date = ISO8601DateFormatter().date(from: dateString) else { return false }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        }

        if thisMonthTransactions.count >= 50 {
            let notification = SmartNotification(
                type: .goalAchieved,
                title: "Tracking Champion! 🏆",
                message: "You've tracked 50+ transactions this month. Great financial awareness!",
                priority: .medium,
                category: nil,
                actionButtons: [
                    NotificationAction(identifier: "view_stats", title: "View Stats", isDestructive: false, requiresAuthentication: false)
                ],
                scheduledTime: nil,
                badge: nil,
                sound: .achievement,
                metadata: [
                    "achievementType": "tracking_milestone",
                    "transactionCount": thisMonthTransactions.count
                ]
            )

            await scheduleSmartNotification(notification)
        }
    }

    private func schedulePeriodicReports() async {
        // Schedule weekly report for Sunday evening
        let calendar = Calendar.current
        let now = Date()

        if let nextSunday = calendar.nextDate(after: now, matching: .init(hour: 18, weekday: 1), matchingPolicy: .nextTime) {
            let notification = SmartNotification(
                type: .weeklyReport,
                title: "Weekly Financial Report",
                message: "Your spending summary and insights for this week are ready.",
                priority: .low,
                category: nil,
                actionButtons: [
                    NotificationAction(identifier: "view_report", title: "View Report", isDestructive: false, requiresAuthentication: false)
                ],
                scheduledTime: nextSunday,
                badge: nil,
                sound: .gentle,
                metadata: [
                    "reportType": "weekly",
                    "weekOf": now.ISO8601Format()
                ]
            )

            await scheduleSmartNotification(notification)
        }
    }

    // MARK: - Notification Categories Setup

    private func setupNotificationCategories() {
        let categories: Set<UNNotificationCategory> = [
            // Budget Alert Category
            UNNotificationCategory(
                identifier: NotificationType.budgetAlert.rawValue,
                actions: [
                    UNNotificationAction(identifier: "view_budget", title: "View Budget", options: [.foreground]),
                    UNNotificationAction(identifier: "adjust_plan", title: "Adjust Plan", options: [.foreground, .authenticationRequired])
                ],
                intentIdentifiers: [],
                options: []
            ),

            // Spending Warning Category
            UNNotificationCategory(
                identifier: NotificationType.spendingWarning.rawValue,
                actions: [
                    UNNotificationAction(identifier: "view_spending", title: "View Spending", options: [.foreground])
                ],
                intentIdentifiers: [],
                options: []
            ),

            // Anomaly Detection Category
            UNNotificationCategory(
                identifier: NotificationType.anomalyDetection.rawValue,
                actions: [
                    UNNotificationAction(identifier: "view_insight", title: "View Details", options: [.foreground]),
                    UNNotificationAction(identifier: "mark_normal", title: "Mark as Normal", options: [.destructive])
                ],
                intentIdentifiers: [],
                options: []
            ),

            // Achievement Category
            UNNotificationCategory(
                identifier: NotificationType.goalAchieved.rawValue,
                actions: [
                    UNNotificationAction(identifier: "view_stats", title: "View Stats", options: [.foreground])
                ],
                intentIdentifiers: [],
                options: []
            ),

            // Reports Category
            UNNotificationCategory(
                identifier: NotificationType.weeklyReport.rawValue,
                actions: [
                    UNNotificationAction(identifier: "view_report", title: "View Report", options: [.foreground])
                ],
                intentIdentifiers: [],
                options: []
            )
        ]

        center.setNotificationCategories(categories)
    }

    // MARK: - Notification Management

    func clearAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        await MainActor.run {
            self.pendingNotifications.removeAll()
        }
    }

    func clearNotification(withId id: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])

        await MainActor.run {
            self.pendingNotifications.removeAll { $0.id.uuidString == id }
        }
    }

    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
        // Apply settings changes
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {

        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            await self.handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        }

        completionHandler()
    }

    @MainActor
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        switch actionIdentifier {
        case "view_budget", "view_spending":
            // Navigate to budget view
            NotificationCenter.default.post(name: .navigateToBudget, object: userInfo)

        case "view_insight":
            // Navigate to insight detail
            NotificationCenter.default.post(name: .navigateToInsight, object: userInfo)

        case "view_report", "view_stats":
            // Navigate to analytics
            NotificationCenter.default.post(name: .navigateToAnalytics, object: userInfo)

        case "mark_normal":
            // Mark insight as normal
            if let insightIdString = userInfo["insightId"] as? String,
               let insightId = UUID(uuidString: insightIdString) {
                NotificationCenter.default.post(name: .markInsightAsNormal, object: insightId)
            }

        default:
            break
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettings {
    var budgetAlertsEnabled = true
    var spendingWarningsEnabled = true
    var anomalyDetectionEnabled = true
    var achievementNotificationsEnabled = true
    var weeklyReportsEnabled = true
    var monthlyReportsEnabled = true
    var reminderNotificationsEnabled = true

    var budgetAlertThreshold: Double = 90.0 // Percentage
    var anomalySensitivity: Double = 0.7 // 0.0 to 1.0
    var reportDeliveryTime: Date = Calendar.current.date(from: DateComponents(hour: 18)) ?? Date()
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let navigateToBudget = Notification.Name("navigateToBudget")
    static let navigateToInsight = Notification.Name("navigateToInsight")
    static let navigateToAnalytics = Notification.Name("navigateToAnalytics")
    static let markInsightAsNormal = Notification.Name("markInsightAsNormal")
}