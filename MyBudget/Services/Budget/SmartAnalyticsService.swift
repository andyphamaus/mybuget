import Foundation
import Combine
import CoreML
import NaturalLanguage
import UIKit
import SwiftUI
import CoreData

// MARK: - Data Models

struct SpendingPattern {
    let categoryId: String
    let averageAmount: Double
    let frequency: Int
    let dayOfWeekPattern: [Double] // 0 = Sunday, 6 = Saturday
    let monthlyTrend: [Double] // Monthly spending trend
    let seasonalFactor: Double
    let confidenceScore: Double
}

struct AnomalyResult {
    let isAnomaly: Bool
    let confidence: Double
    let reason: String
    let severity: AnomalySeverity
    let transaction: LocalTransaction
}

enum AnomalySeverity {
    case low, medium, high, critical
}

struct BudgetForecast {
    let categoryId: String
    let forecastAmount: Double
    let confidenceInterval: (lower: Double, upper: Double)
    let forecastDate: Date
    let basedOnPattern: SpendingPattern?
}

struct FinancialHealthScore {
    let overallScore: Double // 0-100
    let budgetAdherenceScore: Double
    let consistencyScore: Double
    let savingsRateScore: Double
    let categoryBalanceScore: Double
    let trendScore: Double
    let lastCalculated: Date
}

struct SmartInsight {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let priority: InsightPriority
    let actionable: Bool
    let relatedCategoryId: String?
    let createdDate: Date
    let isRead: Bool
}

enum InsightType {
    case budgetAlert
    case spendingPattern
    case anomaly
    case recommendation
    case forecast
    case healthScore
}

enum InsightPriority: Int {
    case low = 1, medium = 2, high = 3, urgent = 4
}

struct HealthRecommendation {
    let icon: String
    let title: String
    let description: String
    let priority: Priority
    let relevanceScore: Double // 0.0 to 1.0, higher = more relevant
    let actionType: ActionType
    let relatedCategoryId: String?
    
    enum Priority {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange  
            case .high: return .red
            }
        }
    }
    
    enum ActionType {
        case setBudgetLimit
        case createBudgetPlan
        case setSpendingAlert
        case createGoal
        case reviewSpending
    }
}

// MARK: - Smart Analytics Service

@MainActor
class SmartAnalyticsService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var insights: [SmartInsight] = []
    @Published var currentHealthScore: FinancialHealthScore?
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    @Published var notificationsEnabled = true {
        didSet {
            saveNotificationSetting()
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let persistenceController = PersistenceController.shared
    private var patternsCache: [String: SpendingPattern] = [:] // categoryId -> pattern
    private var forecastsCache: [String: BudgetForecast] = [:] // categoryId -> forecast
    
    // Real-time update properties
    private var transactionCount: Int = 0
    
    private var lastTransactionDate: Date?
    private var isRealTimeEnabled = true
    private var autoRefreshTimer: Timer?
    
    // Track analyzed transactions to prevent duplicate insights
    private var analyzedTransactionIds: Set<String> = []
    
    // Track cleared/blacklisted insights to permanently hide them
    private var blacklistedTransactionIds: Set<String> = [] {
        didSet {
            // Persist blacklist to UserDefaults
            let array = Array(blacklistedTransactionIds)
            UserDefaults.standard.set(array, forKey: "SmartAnalytics_BlacklistedTransactions")
        }
    }
    
    // Track last analysis to prevent repeated notifications
    private var lastAnalysisHash: String = ""
    private var lastAnalysisTimestamp: Date = Date.distantPast
    private let minimumAnalysisInterval: TimeInterval = 300 // 5 minutes
    
    // Expose forecasts for UI access
    var forecasts: [String: BudgetForecast] {
        return forecastsCache
    }
    
    var patterns: [String: SpendingPattern] {
        return patternsCache
    }
    private var analysisQueue = DispatchQueue(label: "analytics", qos: .userInitiated)
    
    // Performance optimization properties
    private var patternCache: [String: Any] = [:] {
        didSet {
            if patternCache.count > maxCacheSize {
                let keysToRemove = Array(patternCache.keys.prefix(patternCache.count - maxCacheSize))
                keysToRemove.forEach { patternCache.removeValue(forKey: $0) }
            }
        }
    }
    private var cacheExpiryTime: TimeInterval = 3600 // 1 hour
    private var lastCacheUpdate: Date = Date.distantPast

    // Advanced caching
    private var healthScoreCache: (score: FinancialHealthScore, expiry: Date)? {
        didSet {
            // Clear old health score cache
            if let cached = healthScoreCache, Date().timeIntervalSince(cached.expiry) > 0 {
                healthScoreCache = nil
            }
        }
    }
    private var anomalyCache: [String: (anomalies: [AnomalyResult], expiry: Date)] = [:] {
        didSet {
            // Clear expired entries
            let now = Date()
            anomalyCache = anomalyCache.compactMapValues { entry in
                now < entry.expiry ? entry : nil
            }
        }
    }
    private var transactionHashCache: [String: Int] = [:] {
        didSet {
            if transactionHashCache.count > maxCacheSize {
                let keysToRemove = Array(transactionHashCache.keys.prefix(transactionHashCache.count - maxCacheSize))
                keysToRemove.forEach { transactionHashCache.removeValue(forKey: $0) }
            }
        }
    }

    // Performance settings
    private let maxCacheSize: Int = 1000
    private let batchSize: Int = 100
    private let maxParallelTasks: Int = 4

    // Memory management
    private var memoryWarningObserver: NSObjectProtocol?
    private var performanceCleanupTimer: Timer?
    
    // MARK: - Initialization
    init() {
        loadNotificationSetting()
        setupAnalytics()
        setupRealTimeMonitoring()
        loadPersistedInsights()
        loadBlacklistedTransactions()
    }
    
    // MARK: - Public Methods
    
    /// Analyze all transaction data and generate insights - Optimized with caching
    func analyzeFinancialData(
        transactions: [LocalTransaction],
        categories: [LocalCategory],
        plans: [LocalBudgetPeriodPlan],
        budget: LocalBudget?
    ) async {
        guard !transactions.isEmpty else { return }
        
        // Check if we should skip analysis to prevent annoying repeated notifications
        let currentHash = generateDataHash(transactions: transactions, categories: categories, plans: plans)
        let timeSinceLastAnalysis = Date().timeIntervalSince(lastAnalysisTimestamp)
        
        if currentHash == lastAnalysisHash && timeSinceLastAnalysis < minimumAnalysisInterval {
            return
        }
        
        // Update tracking
        lastAnalysisHash = currentHash
        lastAnalysisTimestamp = Date()
        
        await MainActor.run {
            self.isAnalyzing = true
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check if we can use cached results
        let transactionHashes = calculateTransactionHashes(transactions, categories: categories)
        let shouldUseCache = await shouldUseCachedResults(transactionHashes)
        
        if shouldUseCache {
            await MainActor.run {
                self.isAnalyzing = false
                self.lastAnalysisDate = Date()
            }
            return
        }
        
        // Process large datasets in batches
        if transactions.count > 500 {
            await processInBatches(
                transactions: transactions,
                categories: categories,
                plans: plans,
                budget: budget
            )
        } else {
            // Regular parallel processing for smaller datasets
            await withTaskGroup(of: Void.self) { group in
                // Limit concurrent tasks to avoid overwhelming the system
                let semaphore = DispatchSemaphore(value: maxParallelTasks)
                
                group.addTask {
                    await withCheckedContinuation { continuation in
                        semaphore.wait()
                        Task {
                            await self.detectSpendingPatterns(transactions: transactions, categories: categories)
                            semaphore.signal()
                            continuation.resume()
                        }
                    }
                }
                
                group.addTask {
                    await withCheckedContinuation { continuation in
                        semaphore.wait()
                        Task {
                            await self.detectAnomalies(transactions: transactions)
                            semaphore.signal()
                            continuation.resume()
                        }
                    }
                }
                
                group.addTask {
                    await withCheckedContinuation { continuation in
                        semaphore.wait()
                        Task {
                            await self.generateForecasts(transactions: transactions, categories: categories)
                            semaphore.signal()
                            continuation.resume()
                        }
                    }
                }
            
                group.addTask {
                    await withCheckedContinuation { continuation in
                        semaphore.wait()
                        Task {
                            await self.calculateHealthScore(transactions: transactions, plans: plans, budget: budget)
                            semaphore.signal()
                            continuation.resume()
                        }
                    }
                }
            }
        }
        
        // Generate insights based on all analyses
        await generateInsights(transactions: transactions, categories: categories, plans: plans)
        
        // Update caches with new data
        await updateTransactionHashes(transactionHashes)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        await MainActor.run {
            self.isAnalyzing = false
            self.lastAnalysisDate = Date()
        }
    }
    
    /// Get spending pattern for a specific category
    func getPattern(for categoryId: String) -> SpendingPattern? {
        return patternsCache[categoryId]
    }
    
    /// Get forecast for a specific category
    func getForecast(for categoryId: String) -> BudgetForecast? {
        return forecastsCache[categoryId]
    }
    
    /// Mark insight as read
    func markInsightAsRead(_ insightId: UUID) {
        if let index = insights.firstIndex(where: { $0.id == insightId }) {
            insights[index] = SmartInsight(
                id: insights[index].id,
                type: insights[index].type,
                title: insights[index].title,
                description: insights[index].description,
                priority: insights[index].priority,
                actionable: insights[index].actionable,
                relatedCategoryId: insights[index].relatedCategoryId,
                createdDate: insights[index].createdDate,
                isRead: true
            )
        }
    }
    
    /// Generate AI/ML-powered dynamic improvement recommendations
    func generateDynamicImprovementTips(
        healthScore: FinancialHealthScore,
        transactions: [LocalTransaction],
        categories: [LocalCategory]
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // AI Analysis 1: Pattern-based spending recommendations
        let spendingPatternRecommendations = analyzeSpendingPatterns(transactions: transactions, categories: categories)
        recommendations.append(contentsOf: spendingPatternRecommendations)
        
        // AI Analysis 2: Behavioral analysis
        let behaviorRecommendations = analyzeBehavioralPatterns(healthScore: healthScore, transactions: transactions)
        recommendations.append(contentsOf: behaviorRecommendations)
        
        // AI Analysis 3: Seasonal and contextual tips
        let contextualRecommendations = generateContextualTips(transactions: transactions, categories: categories)
        recommendations.append(contentsOf: contextualRecommendations)
        
        // AI Analysis 4: Goal-oriented recommendations
        let goalRecommendations = generateGoalBasedTips(healthScore: healthScore, transactions: transactions)
        recommendations.append(contentsOf: goalRecommendations)
        
        // Sort by priority and return top 5 most relevant
        return Array(recommendations.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(5))
    }
    
    private func analyzeSpendingPatterns(
        transactions: [LocalTransaction],
        categories: [LocalCategory]
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Group transactions by category
        let categoryGroups = Dictionary(grouping: transactions) { $0.category?.id ?? "" }
        
        for (categoryId, categoryTransactions) in categoryGroups {
            guard let category = categories.first(where: { $0.id == categoryId }),
                  categoryTransactions.count >= 3 else { continue }
            
            let categoryName = category.name ?? "Unknown"
            let amounts = categoryTransactions.map { $0.amountInCurrency }
            let totalSpent = amounts.reduce(0, +)
            let averageSpent = totalSpent / Double(amounts.count)
            
            // AI Logic: Detect increasing spend trend
            let sortedTransactions = categoryTransactions.sorted { 
                guard let date1 = $0.transactionDate, let date2 = $1.transactionDate else { return false }
                return date1 < date2 
            }
            
            if sortedTransactions.count >= 4 {
                let recentHalf = Array(sortedTransactions.suffix(sortedTransactions.count/2))
                let earlierHalf = Array(sortedTransactions.prefix(sortedTransactions.count/2))
                
                let recentAvg = recentHalf.reduce(0) { $0 + $1.amountInCurrency } / Double(recentHalf.count)
                let earlierAvg = earlierHalf.reduce(0) { $0 + $1.amountInCurrency } / Double(earlierHalf.count)
                
                if recentAvg > earlierAvg * 1.3 { // 30% increase
                    let increasePercent = Int(((recentAvg - earlierAvg) / earlierAvg) * 100)
                    recommendations.append(HealthRecommendation(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Increasing \(categoryName) Spending",
                        description: "Your \(categoryName.lowercased()) spending has increased by \(increasePercent)% recently. Consider setting a monthly limit of $\(Int(earlierAvg * 1.1)) to control this trend.",
                        priority: .high,
                        relevanceScore: 0.9,
                        actionType: .setBudgetLimit,
                        relatedCategoryId: categoryId
                    ))
                }
            }
            
            // AI Logic: Detect high-variance spending (inconsistent patterns)
            let variance = amounts.map { pow($0 - averageSpent, 2) }.reduce(0, +) / Double(amounts.count)
            let standardDeviation = sqrt(variance)
            let coefficientOfVariation = averageSpent > 0 ? standardDeviation / averageSpent : 0
            
            if coefficientOfVariation > 0.8 { // High variance
                recommendations.append(HealthRecommendation(
                    icon: "waveform.path.ecg",
                    title: "Inconsistent \(categoryName) Spending",
                    description: "Your \(categoryName.lowercased()) spending varies significantly ($\(Int(averageSpent - standardDeviation)) - $\(Int(averageSpent + standardDeviation))). Try budgeting $\(Int(averageSpent)) monthly for better consistency.",
                    priority: .medium,
                    relevanceScore: 0.7,
                    actionType: .createBudgetPlan,
                    relatedCategoryId: categoryId
                ))
            }
        }
        
        return recommendations
    }
    
    private func analyzeBehavioralPatterns(
        healthScore: FinancialHealthScore,
        transactions: [LocalTransaction]
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // AI Analysis: Weekend vs weekday spending
        let calendar = Calendar.current
        var weekendSpending: Double = 0
        var weekdaySpending: Double = 0
        var weekendCount = 0
        var weekdayCount = 0
        
        for transaction in transactions {
            guard let dateString = transaction.transactionDate,
                  let date = ISO8601DateFormatter().date(from: dateString) else { continue }
            
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendSpending += transaction.amountInCurrency
                weekendCount += 1
            } else {
                weekdaySpending += transaction.amountInCurrency
                weekdayCount += 1
            }
        }
        
        if weekendCount > 0 && weekdayCount > 0 {
            let avgWeekendSpending = weekendSpending / Double(weekendCount)
            let avgWeekdaySpending = weekdaySpending / Double(weekdayCount)
            
            if avgWeekendSpending > avgWeekdaySpending * 1.5 {
                let difference = Int(avgWeekendSpending - avgWeekdaySpending)
                recommendations.append(HealthRecommendation(
                    icon: "calendar.badge.exclamationmark",
                    title: "Weekend Overspending Pattern",
                    description: "You spend $\(difference) more per transaction on weekends. Consider planning weekend activities with a set budget to control impulse spending.",
                    priority: .medium,
                    relevanceScore: 0.8,
                    actionType: .setSpendingAlert,
                    relatedCategoryId: nil
                ))
            }
        }
        
        // AI Analysis: Large transaction frequency
        let largeTransactions = transactions.filter { $0.amountInCurrency > 200 }
        if largeTransactions.count >= 3 {
            let averageLarge = largeTransactions.reduce(0) { $0 + $1.amountInCurrency } / Double(largeTransactions.count)
            recommendations.append(HealthRecommendation(
                icon: "exclamationmark.triangle",
                title: "Frequent Large Purchases",
                description: "You've made \(largeTransactions.count) transactions over $200 (avg: $\(Int(averageLarge))). Consider implementing a 24-hour waiting period for purchases over $150.",
                priority: .high,
                relevanceScore: 0.85,
                actionType: .setSpendingAlert,
                relatedCategoryId: nil
            ))
        }
        
        return recommendations
    }
    
    private func generateContextualTips(
        transactions: [LocalTransaction],
        categories: [LocalCategory]
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // AI Analysis: Seasonal spending patterns
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        // Holiday season spending advice
        if [11, 12, 1].contains(currentMonth) {
            let recentTransactions = transactions.filter { transaction in
                guard let dateString = transaction.transactionDate,
                      let date = ISO8601DateFormatter().date(from: dateString) else { return false }
                return Date().timeIntervalSince(date) < 2592000 // Last 30 days
            }
            
            let monthlySpending = recentTransactions.reduce(0) { $0 + $1.amountInCurrency }
            if monthlySpending > 1500 {
                recommendations.append(HealthRecommendation(
                    icon: "gift",
                    title: "Holiday Season Budget Alert",
                    description: "Holiday spending can quickly add up. You've spent $\(Int(monthlySpending)) this month. Consider setting aside a specific amount for gifts and celebrations.",
                    priority: .medium,
                    relevanceScore: 0.75,
                    actionType: .createBudgetPlan,
                    relatedCategoryId: nil
                ))
            }
        }
        
        // AI Analysis: Day-of-month spending patterns
        var earlyMonthSpending: Double = 0
        var lateMonthSpending: Double = 0
        var earlyCount = 0
        var lateCount = 0
        
        for transaction in transactions {
            guard let dateString = transaction.transactionDate,
                  let date = ISO8601DateFormatter().date(from: dateString) else { continue }
            
            let dayOfMonth = calendar.component(.day, from: date)
            if dayOfMonth <= 15 {
                earlyMonthSpending += transaction.amountInCurrency
                earlyCount += 1
            } else {
                lateMonthSpending += transaction.amountInCurrency
                lateCount += 1
            }
        }
        
        if earlyCount > 0 && lateCount > 0 {
            let earlyAvg = earlyMonthSpending / Double(earlyCount)
            let lateAvg = lateMonthSpending / Double(lateCount)
            
            if earlyAvg > lateAvg * 1.4 {
                recommendations.append(HealthRecommendation(
                    icon: "calendar.badge.clock",
                    title: "Early Month Overspending",
                    description: "You tend to spend more in the first half of the month. Try spreading expenses evenly or save larger purchases for mid-month.",
                    priority: .low,
                    relevanceScore: 0.6,
                    actionType: .setSpendingAlert,
                    relatedCategoryId: nil
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateGoalBasedTips(
        healthScore: FinancialHealthScore,
        transactions: [LocalTransaction]
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // AI Analysis: Progress toward financial health goals
        let totalMonthlySpending = transactions.reduce(0) { $0 + $1.amountInCurrency }
        
        if healthScore.overallScore < 70 {
            // Custom tips based on the weakest score component
            let scores = [
                ("Budget Adherence", healthScore.budgetAdherenceScore),
                ("Consistency", healthScore.consistencyScore),
                ("Savings Rate", healthScore.savingsRateScore),
                ("Category Balance", healthScore.categoryBalanceScore)
            ]
            
            if let weakestArea = scores.min(by: { $0.1 < $1.1 }) {
                let improvementNeeded = Int(75 - weakestArea.1)
                recommendations.append(HealthRecommendation(
                    icon: "target",
                    title: "Focus on \(weakestArea.0)",
                    description: "Your \(weakestArea.0.lowercased()) score is \(Int(weakestArea.1))/100. Improving this by \(improvementNeeded) points would boost your overall health score significantly. Start with small, consistent changes.",
                    priority: .high,
                    relevanceScore: 0.95,
                    actionType: .createGoal,
                    relatedCategoryId: nil
                ))
            }
        }
        
        // AI Analysis: Spending velocity recommendations
        if totalMonthlySpending > 3000 {
            let dailyAverage = totalMonthlySpending / 30
            recommendations.append(HealthRecommendation(
                icon: "speedometer",
                title: "High Spending Velocity",
                description: "You're spending $\(Int(dailyAverage)) per day on average. Consider implementing a daily spending limit of $\(Int(dailyAverage * 0.8)) to build better control.",
                priority: .medium,
                relevanceScore: 0.7,
                actionType: .setSpendingAlert,
                relatedCategoryId: nil
            ))
        }
        
        return recommendations
    }
    
    /// Generate a unique hash for the current data state
    private func generateDataHash(transactions: [LocalTransaction], categories: [LocalCategory], plans: [LocalBudgetPeriodPlan]) -> String {
        var hasher = Hasher()
        
        // Hash transaction count and total amount
        hasher.combine(transactions.count)
        let totalAmount = transactions.reduce(0) { $0 + $1.amountInCurrency }
        hasher.combine(totalAmount)
        
        // Hash categories count
        hasher.combine(categories.count)
        
        // Hash plans count and total planned amount
        hasher.combine(plans.count)
        let totalPlanned = plans.reduce(0) { $0 + $1.amountInCurrency }
        hasher.combine(totalPlanned)
        
        // Hash most recent transaction date
        if let latestTransaction = transactions.max(by: { 
            let date1 = $0.transactionDate.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date.distantPast
            let date2 = $1.transactionDate.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date.distantPast
            return date1 < date2
        }),
        let dateString = latestTransaction.transactionDate,
        let date = ISO8601DateFormatter().date(from: dateString) {
            hasher.combine(date.timeIntervalSince1970)
        }
        
        return String(hasher.finalize())
    }
    
    func clearOldInsights() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Remove old read insights
        insights = insights.filter { insight in
            if insight.isRead && insight.createdDate < thirtyDaysAgo {
                return false // Remove old read insights
            }
            return true // Keep recent or unread insights
        }
        
        // Optionally clear analyzed transaction IDs older than a week
        // (We keep this short to allow re-analysis of very old transactions if needed)
        // Note: In a real app, you might want to persist this in UserDefaults or Core Data
    }
    
    func resetAnalysisState() {
        analyzedTransactionIds.removeAll()
        blacklistedTransactionIds.removeAll() // This completely resets everything
        // This method can be called manually if user wants to reset the analysis
    }
    
    /// Force analysis even if data hasn't changed (for manual refresh)
    func forceAnalyzeFinancialData(
        transactions: [LocalTransaction],
        categories: [LocalCategory],
        plans: [LocalBudgetPeriodPlan],
        budget: LocalBudget?
    ) async {
        // Reset timestamp to force analysis
        lastAnalysisTimestamp = Date.distantPast
        lastAnalysisHash = ""
        
        await analyzeFinancialData(
            transactions: transactions,
            categories: categories,
            plans: plans,
            budget: budget
        )
    }
    
    /// Clear all insights and permanently blacklist them from future detection
    func clearInsights() {
        // Mark all current insights as dismissed in Core Data
        let context = persistenceController.container.viewContext
        
        for insight in insights {
            // Find and dismiss in Core Data
            let request: NSFetchRequest<LocalSmartInsight> = LocalSmartInsight.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", insight.id as CVarArg)
            
            do {
                let results = try context.fetch(request)
                for entity in results {
                    entity.isDismissed = true
                }
            } catch {
                // Handle error silently
            }
            
            // Add to blacklist for this session
            if let relatedCategoryId = insight.relatedCategoryId,
               insight.type == .anomaly {
                blacklistedTransactionIds.insert("\(relatedCategoryId)_\(insight.title)")
            }
        }
        
        // Save Core Data changes
        do {
            try context.save()
        } catch {
            // Handle error silently
        }
        
        insights.removeAll()
        // Keep analyzedTransactionIds to prevent re-analysis, but now also check blacklist
    }
    
    /// Load persisted insights from Core Data (only non-dismissed ones)
    private func loadPersistedInsights() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<LocalSmartInsight> = LocalSmartInsight.fetchRequest()
        request.predicate = NSPredicate(format: "isDismissed == false")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalSmartInsight.createdDate, ascending: false)]
        
        do {
            let persistedInsights = try context.fetch(request)
            insights = persistedInsights.map { $0.toSmartInsight() }
        } catch {
            // Handle error silently
        }
    }
    
    /// Load blacklisted transactions from UserDefaults
    private func loadBlacklistedTransactions() {
        if let array = UserDefaults.standard.array(forKey: "SmartAnalytics_BlacklistedTransactions") as? [String] {
            blacklistedTransactionIds = Set(array)
        }
    }
    
    /// Check if insight already exists in database (including dismissed ones)
    private func insightExistsInDatabase(_ insight: SmartInsight) -> Bool {
        let context = persistenceController.container.viewContext
        
        let uniqueKey = LocalSmartInsight.createUniqueKey(
            type: insight.type.stringValue,
            title: insight.title,
            categoryId: insight.relatedCategoryId,
            periodId: nil // TODO: Add period context
        )
        
        let request: NSFetchRequest<LocalSmartInsight> = LocalSmartInsight.fetchRequest()
        request.predicate = NSPredicate(format: "uniqueKey == %@", uniqueKey)
        
        do {
            let existingInsights = try context.fetch(request)
            return !existingInsights.isEmpty
        } catch {
            return false
        }
    }
    
    /// Save insight to Core Data to prevent duplicates
    private func saveInsightToCoreData(_ insight: SmartInsight) {
        let context = persistenceController.container.viewContext
        
        // Check if insight already exists
        let uniqueKey = LocalSmartInsight.createUniqueKey(
            type: insight.type.stringValue,
            title: insight.title,
            categoryId: insight.relatedCategoryId,
            periodId: nil // TODO: Add period context
        )
        
        let request: NSFetchRequest<LocalSmartInsight> = LocalSmartInsight.fetchRequest()
        request.predicate = NSPredicate(format: "uniqueKey == %@", uniqueKey) // Check ALL insights, including dismissed ones
        
        do {
            let existingInsights = try context.fetch(request)
            if !existingInsights.isEmpty {
                return // Don't create duplicate
            }
            
            // Create new insight
            _ = LocalSmartInsight.fromSmartInsight(insight, context: context)
            
            try context.save()
        } catch {
            // Handle error silently
        }
    }
    
    // MARK: - Private Analysis Methods
    
    private func setupAnalytics() {
        // Setup any initial configurations
        setupMemoryManagement()
        setupPerformanceMonitoring()
    }
    
    private func setupMemoryManagement() {
        // Listen for memory warnings
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.clearCacheOnMemoryWarning()
            }
        }
    }
    
    private func setupPerformanceMonitoring() {
        // Periodic cache cleanup with proper memory management
        performanceCleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performPeriodicCacheCleanup()
            }
        }
    }
    
    private func clearCacheOnMemoryWarning() async {
        
        // Clear non-essential caches
        patternCache.removeAll()
        anomalyCache.removeAll()
        
        // Keep only recent health score
        if let cached = healthScoreCache,
           Date().timeIntervalSince(cached.expiry) > 300 { // 5 minutes
            healthScoreCache = nil
        }
        
        // Clear old forecasts
        forecastsCache = forecastsCache.compactMapValues { forecast in
            Date().timeIntervalSince(forecast.forecastDate) < 86400 ? forecast : nil
        }
    }
    
    private func performPeriodicCacheCleanup() async {
        let now = Date()
        
        // Clean expired health score cache
        if let cached = healthScoreCache,
           now > cached.expiry {
            healthScoreCache = nil
        }
        
        // Clean expired anomaly cache
        anomalyCache = anomalyCache.compactMapValues { entry in
            now < entry.expiry ? entry : nil
        }
        
        // Limit pattern cache size
        if patternCache.count > maxCacheSize {
            let keysToRemove = Array(patternCache.keys.prefix(patternCache.count - maxCacheSize))
            keysToRemove.forEach { patternCache.removeValue(forKey: $0) }
        }
    }
    
    // MARK: - Real-time Monitoring
    
    private func setupRealTimeMonitoring() {
        // Start auto-refresh timer for periodic updates
        startAutoRefreshTimer()
    }
    
    private func startAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        
        // Auto-refresh every 30 seconds when real-time is enabled
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                guard self.isRealTimeEnabled else { return }
                
                // Only refresh if we have recent data updates
                if let lastTransaction = self.lastTransactionDate,
                   Date().timeIntervalSince(lastTransaction) < 300 { // 5 minutes
                    await self.performIncrementalUpdate()
                }
            }
        }
    }
    
    func enableRealTimeUpdates(_ enabled: Bool) {
        isRealTimeEnabled = enabled
        if enabled {
            startAutoRefreshTimer()
        } else {
            autoRefreshTimer?.invalidate()
        }
    }
    
    /// Called when new transactions are detected
    func notifyNewTransactions(_ transactions: [LocalTransaction]) async {
        guard isRealTimeEnabled else { return }
        
        let newTransactionCount = transactions.count
        if newTransactionCount > transactionCount {
            transactionCount = newTransactionCount
            lastTransactionDate = Date()
            
            // Perform immediate analysis for new transactions
            await performIncrementalUpdate(newTransactions: Array(transactions.suffix(newTransactionCount - transactionCount)))
        }
    }
    
    /// Perform lightweight incremental update for new data
    private func performIncrementalUpdate(newTransactions: [LocalTransaction] = []) async {
        guard !isAnalyzing else { return } // Prevent overlapping updates
        
        await MainActor.run {
            self.isAnalyzing = true
        }
        
        // Quick analysis for new transactions
        if !newTransactions.isEmpty {
            await analyzeNewTransactions(newTransactions)
        }
        
        // Update timestamps
        await MainActor.run {
            self.lastAnalysisDate = Date()
            self.isAnalyzing = false
        }
    }
    
    private func analyzeNewTransactions(_ newTransactions: [LocalTransaction]) async {
        // Quick anomaly detection for new transactions
        for transaction in newTransactions {
            await analyzeTransactionForAnomalies(transaction)
        }
        
        // Update health score if significant changes
        if newTransactions.count >= 3 {
            await updateHealthScoreIncremental(newTransactions)
        }
        
        // Generate real-time insights for new transactions
        await generateRealTimeInsights(newTransactions)
    }
    
    private func analyzeTransactionForAnomalies(_ transaction: LocalTransaction) async {
        guard let categoryId = transaction.category?.id,
              let pattern = patternsCache[categoryId],
              let transactionId = transaction.id else { return }
        
        // Check if we've already analyzed this transaction or if it's blacklisted
        let blacklistKey = "\(categoryId)_Unusual Transaction Detected"
        if analyzedTransactionIds.contains(transactionId) || blacklistedTransactionIds.contains(blacklistKey) {
            return // Skip already analyzed or blacklisted transaction
        }
        
        var isAnomaly = detectAnomaly(
            amount: transaction.amountInCurrency,
            categoryPattern: pattern
        )
        isAnomaly = AnomalyResult(
            isAnomaly: isAnomaly.isAnomaly,
            confidence: isAnomaly.confidence,
            reason: isAnomaly.reason,
            severity: isAnomaly.severity,
            transaction: transaction
        )
        
        if isAnomaly.isAnomaly && (isAnomaly.severity == AnomalySeverity.high || isAnomaly.severity == AnomalySeverity.critical) {
            // Mark this transaction as analyzed
            analyzedTransactionIds.insert(transactionId)
            
            // Check if we already have an insight for this transaction
            let existingInsight = await MainActor.run {
                return self.insights.first { insight in
                    insight.type == .anomaly && 
                    insight.description.contains(transaction.amountInCurrency.formatted(.currency(code: "USD"))) &&
                    insight.relatedCategoryId == categoryId
                }
            }
            
            // Only create new insight if one doesn't already exist AND it's not in the database
            if existingInsight == nil {
                let tempInsight = SmartInsight(
                    id: UUID(),
                    type: .anomaly,
                    title: "Unusual Transaction Detected",
                    description: "New \(transaction.amountInCurrency.formatted(.currency(code: "USD"))) transaction in \(transaction.category?.name ?? "Unknown") category is unusual based on your spending pattern.",
                    priority: isAnomaly.severity == AnomalySeverity.critical ? .urgent : .high,
                    actionable: true,
                    relatedCategoryId: categoryId,
                    createdDate: Date(),
                    isRead: false
                )
                
                // Check database before creating - if insight exists (even if dismissed), don't show it again
                if !insightExistsInDatabase(tempInsight) {
                    await MainActor.run {
                        // Save to Core Data for persistence and duplicate prevention
                        self.saveInsightToCoreData(tempInsight)
                        // Add to current session for immediate UI display
                        self.insights.insert(tempInsight, at: 0)
                    }
                } else {
                    // Insight already exists in database
                }
            }
        } else {
            // Even if not anomaly, mark as analyzed to avoid re-checking
            analyzedTransactionIds.insert(transactionId)
        }
    }
    
    private func updateHealthScoreIncremental(_ newTransactions: [LocalTransaction]) async {
        guard let currentScore = currentHealthScore else { return }
        
        // Quick health score adjustment based on new transactions
        let totalNewSpending = newTransactions.reduce(0) { $0 + $1.amountInCurrency }
        let avgTransactionAmount = totalNewSpending / Double(newTransactions.count)
        
        // Adjust consistency score based on new transaction patterns
        var adjustedConsistencyScore = currentScore.consistencyScore
        if avgTransactionAmount > 1000 { // Large transactions impact consistency
            adjustedConsistencyScore = max(0, adjustedConsistencyScore - 5)
        }
        
        let updatedScore = FinancialHealthScore(
            overallScore: (currentScore.overallScore + adjustedConsistencyScore) / 2,
            budgetAdherenceScore: currentScore.budgetAdherenceScore,
            consistencyScore: adjustedConsistencyScore,
            savingsRateScore: currentScore.savingsRateScore,
            categoryBalanceScore: currentScore.categoryBalanceScore,
            trendScore: currentScore.trendScore,
            lastCalculated: Date()
        )
        
        await MainActor.run {
            self.currentHealthScore = updatedScore
        }
    }
    
    private func generateRealTimeInsights(_ newTransactions: [LocalTransaction]) async {
        let categorySpending = Dictionary(grouping: newTransactions) { $0.category?.name ?? "Unknown" }
        
        for (categoryName, transactions) in categorySpending {
            let totalSpent = transactions.reduce(0) { $0 + $1.amountInCurrency }
            
            if totalSpent > 500 { // Significant spending threshold
                let insight = SmartInsight(
                    id: UUID(),
                    type: .spendingPattern,
                    title: "High Spending Alert",
                    description: "You've spent \(totalSpent.formatted(.currency(code: "USD"))) in \(categoryName) recently. Consider reviewing your budget for this category.",
                    priority: totalSpent > 1000 ? .high : .medium,
                    actionable: true,
                    relatedCategoryId: transactions.first?.category?.id,
                    createdDate: Date(),
                    isRead: false
                )
                
                await MainActor.run {
                    // Save to Core Data for persistence and duplicate prevention
                    self.saveInsightToCoreData(insight)
                    // Add to current session for immediate UI display
                    self.insights.insert(insight, at: 0)
                }
            }
        }
    }
    
    deinit {
        // Clean up all timers to prevent memory leaks
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil

        performanceCleanupTimer?.invalidate()
        performanceCleanupTimer = nil

        // Remove notification observers
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Clear all caches to release memory
        patternsCache.removeAll()
        forecastsCache.removeAll()
        patternCache.removeAll()
        anomalyCache.removeAll()
        transactionHashCache.removeAll()
        healthScoreCache = nil

        // Clear tracking sets
        analyzedTransactionIds.removeAll()
        blacklistedTransactionIds.removeAll()

        // Clear cancellables
        cancellables.removeAll()
    }
    
    // MARK: - Performance Optimization Methods
    
    private func calculateTransactionHashes(_ transactions: [LocalTransaction], categories: [LocalCategory]) -> [String: Int] {
        var hashes: [String: Int] = [:]
        
        for category in categories {
            guard let categoryId = category.id else { continue }
            
            let categoryTransactions = transactions.filter { $0.category?.id == categoryId }
            let hash = categoryTransactions.reduce(0) { result, transaction in
                var hasher = Hasher()
                hasher.combine(transaction.id)
                hasher.combine(transaction.amountInCurrency)
                hasher.combine(transaction.transactionDate)
                return result ^ hasher.finalize()
            }
            
            hashes[categoryId] = hash
        }
        
        return hashes
    }
    
    private func shouldUseCachedResults(_ newHashes: [String: Int]) async -> Bool {
        // Check if transaction data has changed
        for (categoryId, newHash) in newHashes {
            if let cachedHash = transactionHashCache[categoryId],
               cachedHash != newHash {
                return false
            }
        }
        
        // Check cache expiry
        if let cached = healthScoreCache,
           Date() < cached.expiry,
           !patternsCache.isEmpty,
           !forecastsCache.isEmpty {
            return true
        }
        
        return false
    }
    
    private func updateTransactionHashes(_ hashes: [String: Int]) async {
        await MainActor.run {
            self.transactionHashCache = hashes
        }
    }
    
    private func processInBatches(
        transactions: [LocalTransaction],
        categories: [LocalCategory],
        plans: [LocalBudgetPeriodPlan],
        budget: LocalBudget?
    ) async {
        
        let sortedTransactions = transactions.sorted { transaction1, transaction2 in
            guard let date1 = transaction1.transactionDate,
                  let date2 = transaction2.transactionDate else { return false }
            return date1 > date2 // Most recent first
        }
        
        var processedTransactions: [LocalTransaction] = []
        
        // Process in batches to avoid memory spikes
        for batchStart in stride(from: 0, to: sortedTransactions.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedTransactions.count)
            let batch = Array(sortedTransactions[batchStart..<batchEnd])
            processedTransactions.append(contentsOf: batch)
            
            // Process this batch
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.detectSpendingPatterns(transactions: processedTransactions, categories: categories)
                }
                
                group.addTask {
                    await self.detectAnomalies(transactions: batch) // Only anomalies for new batch
                }
                
                if batchEnd == sortedTransactions.count {
                    // Final batch - run full analysis
                    group.addTask {
                        await self.generateForecasts(transactions: processedTransactions, categories: categories)
                    }
                    
                    group.addTask {
                        await self.calculateHealthScore(transactions: processedTransactions, plans: plans, budget: budget)
                    }
                }
            }
            
            // Small delay between batches to prevent UI blocking
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    private func detectSpendingPatterns(transactions: [LocalTransaction], categories: [LocalCategory]) async {
        await analysisQueue.run {
            let groupedByCategory = Dictionary(grouping: transactions) { $0.category?.id ?? "" }
            
            for (categoryId, categoryTransactions) in groupedByCategory {
                guard !categoryId.isEmpty, categoryTransactions.count >= 3 else { continue }
                
                let pattern = self.calculateSpendingPattern(for: categoryTransactions)
                await MainActor.run {
                    self.patternsCache[categoryId] = pattern
                }
            }
        }
    }
    
    private func calculateSpendingPattern(for transactions: [LocalTransaction]) -> SpendingPattern {
        let amounts = transactions.map { $0.amountInCurrency }
        let averageAmount = amounts.reduce(0, +) / Double(amounts.count)
        
        // Calculate day of week pattern
        var dayPattern = Array(repeating: 0.0, count: 7)
        for transaction in transactions {
            if let dateString = transaction.transactionDate,
               let date = ISO8601DateFormatter().date(from: dateString) {
                let dayOfWeek = Calendar.current.component(.weekday, from: date) - 1
                dayPattern[dayOfWeek] += transaction.amountInCurrency
            }
        }
        
        // Normalize day pattern
        let totalDaySpending = dayPattern.reduce(0, +)
        if totalDaySpending > 0 {
            dayPattern = dayPattern.map { $0 / totalDaySpending }
        }
        
        // Calculate monthly trend (simplified)
        let monthlyTrend = calculateMonthlyTrend(transactions)
        
        // Calculate seasonal factor (simplified)
        let seasonalFactor = calculateSeasonalFactor(transactions)
        
        // Calculate confidence score based on data points
        let confidenceScore = min(Double(transactions.count) / 10.0, 1.0)
        
        return SpendingPattern(
            categoryId: transactions.first?.category?.id ?? "",
            averageAmount: averageAmount,
            frequency: transactions.count,
            dayOfWeekPattern: dayPattern,
            monthlyTrend: monthlyTrend,
            seasonalFactor: seasonalFactor,
            confidenceScore: confidenceScore
        )
    }
    
    private func calculateMonthlyTrend(_ transactions: [LocalTransaction]) -> [Double] {
        // Group by month and calculate trend
        let calendar = Calendar.current
        let monthlyData = Dictionary(grouping: transactions) { transaction in
            guard let dateString = transaction.transactionDate,
                  let date = ISO8601DateFormatter().date(from: dateString) else { return 0 }
            return calendar.component(.month, from: date)
        }
        
        var trend = Array(repeating: 0.0, count: 12)
        for (month, monthTransactions) in monthlyData {
            let monthTotal = monthTransactions.reduce(0) { $0 + $1.amountInCurrency }
            // Ensure month is valid (1-12) before using as array index
            if month >= 1 && month <= 12 {
                trend[month - 1] = monthTotal
            }
        }
        
        return trend
    }
    
    private func calculateSeasonalFactor(_ transactions: [LocalTransaction]) -> Double {
        // Simplified seasonal factor calculation
        let calendar = Calendar.current
        let seasonalData = transactions.compactMap { transaction -> Double? in
            guard let dateString = transaction.transactionDate,
                  let date = ISO8601DateFormatter().date(from: dateString) else { return nil }
            let month = calendar.component(.month, from: date)
            
            // Summer spending factor
            if [6, 7, 8].contains(month) {
                return transaction.amountInCurrency * 1.1
            } else if [12, 1, 2].contains(month) {
                return transaction.amountInCurrency * 1.2 // Holiday spending
            } else {
                return transaction.amountInCurrency
            }
        }
        
        let averageSeasonalAmount = seasonalData.isEmpty ? 1.0 : seasonalData.reduce(0, +) / Double(seasonalData.count)
        let regularAverage = transactions.reduce(0) { $0 + $1.amountInCurrency } / Double(transactions.count)
        
        return regularAverage > 0 ? averageSeasonalAmount / regularAverage : 1.0
    }
    
    private func detectAnomalies(transactions: [LocalTransaction]) async {
        await analysisQueue.run {
            // Simple anomaly detection using statistical approach
            let amounts = transactions.map { $0.amountInCurrency }
            guard amounts.count > 5 else { return }
            
            let mean = amounts.reduce(0, +) / Double(amounts.count)
            let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
            let standardDeviation = sqrt(variance)
            
            // Detect outliers (transactions more than 2.5 standard deviations from mean)
            let threshold = 2.5
            
            for transaction in transactions {
                let zScore = abs(transaction.amountInCurrency - mean) / standardDeviation
                if zScore > threshold {
                    let anomaly = AnomalyResult(
                        isAnomaly: true,
                        confidence: min(zScore / threshold, 1.0),
                        reason: "Transaction amount is \(String(format: "%.1f", zScore)) standard deviations from your average",
                        severity: self.determineSeverity(zScore: zScore),
                        transaction: transaction
                    )
                    
                    await MainActor.run {
                        self.createAnomalyInsight(from: anomaly)
                    }
                }
            }
        }
    }
    
    private func determineSeverity(zScore: Double) -> AnomalySeverity {
        if zScore > 4.0 {
            return .critical
        } else if zScore > 3.5 {
            return .high
        } else if zScore > 3.0 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func detectAnomaly(amount: Double, categoryPattern: SpendingPattern) -> AnomalyResult {
        let averageAmount = categoryPattern.averageAmount
        let deviation = abs(amount - averageAmount)
        let relativeDeviation = averageAmount > 0 ? deviation / averageAmount : 0
        
        let isAnomaly = relativeDeviation > 1.5 // 150% deviation threshold
        let confidence = min(relativeDeviation / 2.0, 1.0)
        let severity = determineSeverity(zScore: relativeDeviation * 2.0)
        
        let reason = "Transaction of \(amount.formatted(.currency(code: "USD"))) is \(String(format: "%.1f", relativeDeviation * 100))% different from your average of \(averageAmount.formatted(.currency(code: "USD")))"
        
        return AnomalyResult(
            isAnomaly: isAnomaly,
            confidence: confidence,
            reason: reason,
            severity: severity,
            transaction: LocalTransaction() // This will be set by the caller
        )
    }
    
    private func generateForecasts(transactions: [LocalTransaction], categories: [LocalCategory]) async {
        await analysisQueue.run {
            let groupedByCategory = Dictionary(grouping: transactions) { $0.category?.id ?? "" }
            
            for (categoryId, categoryTransactions) in groupedByCategory {
                guard !categoryId.isEmpty, categoryTransactions.count >= 5 else { continue }
                
                let forecast = self.calculateForecast(for: categoryTransactions, categoryId: categoryId)
                await MainActor.run {
                    self.forecastsCache[categoryId] = forecast
                }
            }
        }
    }
    
    private func calculateForecast(for transactions: [LocalTransaction], categoryId: String) -> BudgetForecast {
        // Simple linear trend forecasting
        let dateFormatter = ISO8601DateFormatter()
        let sortedTransactions = transactions.sorted { 
            let date1 = ($0.transactionDate.flatMap { dateFormatter.date(from: $0) }) ?? Date.distantPast
            let date2 = ($1.transactionDate.flatMap { dateFormatter.date(from: $0) }) ?? Date.distantPast
            return date1 < date2
        }
        
        let amounts = sortedTransactions.map { $0.amountInCurrency }
        let n = Double(amounts.count)
        let sumX = n * (n + 1) / 2 // 1 + 2 + ... + n
        let sumY = amounts.reduce(0, +)
        let sumXY = zip(1...amounts.count, amounts).reduce(0) { $0 + Double($1.0) * $1.1 }
        let sumXX = n * (n + 1) * (2 * n + 1) / 6 // sum of squares
        
        // Linear regression: y = ax + b
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Forecast for next period
        let nextPeriod = n + 1
        let forecastAmount = slope * nextPeriod + intercept
        
        // Calculate confidence interval (simplified)
        let residuals = zip(1...amounts.count, amounts).map { item in
            let predicted = Double(item.0) * slope + intercept
            let actual = item.1
            return predicted - actual
        }
        let squaredResiduals = residuals.map { $0 * $0 }
        let mse = squaredResiduals.reduce(0, +) / n
        let standardError = sqrt(mse)
        
        let confidenceInterval = (
            lower: max(0, forecastAmount - 1.96 * standardError),
            upper: forecastAmount + 1.96 * standardError
        )
        
        return BudgetForecast(
            categoryId: categoryId,
            forecastAmount: max(0, forecastAmount),
            confidenceInterval: confidenceInterval,
            forecastDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            basedOnPattern: patternsCache[categoryId]
        )
    }
    
    private func calculateHealthScore(
        transactions: [LocalTransaction], 
        plans: [LocalBudgetPeriodPlan], 
        budget: LocalBudget?
    ) async {
        await analysisQueue.run {
            let healthScore = self.computeHealthScore(transactions: transactions, plans: plans, budget: budget)
            await MainActor.run {
                self.currentHealthScore = healthScore
            }
        }
    }
    
    private func computeHealthScore(
        transactions: [LocalTransaction], 
        plans: [LocalBudgetPeriodPlan], 
        budget: LocalBudget?
    ) -> FinancialHealthScore {
        
        // 1. Budget Adherence Score - FIXED: Handle Income vs Expense properly
        var budgetAdherenceScore = 100.0
        if !plans.isEmpty {
            // Separate income and expense transactions/plans
            let incomeTransactions = transactions.filter { $0.type == "INCOME" }
            let expenseTransactions = transactions.filter { $0.type == "EXPENSE" }
            
            var incomePlans: [LocalBudgetPeriodPlan] = []
            var expensePlans: [LocalBudgetPeriodPlan] = []
            
            for plan in plans {
                if let category = plan.category,
                   let headCategory = category.headCategory,
                   headCategory.preferType == "INCOME" {
                    incomePlans.append(plan)
                } else {
                    expensePlans.append(plan)
                }
            }
            
            var scores: [Double] = []
            
            // Income adherence: MORE income than planned = BETTER score
            if !incomePlans.isEmpty {
                let totalIncomeePlanned = incomePlans.reduce(0) { $0 + $1.amountInCurrency }
                let totalIncomeActual = incomeTransactions.reduce(0) { $0 + $1.amountInCurrency }
                
                if totalIncomeePlanned > 0 {
                    let incomeRatio = totalIncomeActual / totalIncomeePlanned
                    // For income: ratio >= 1.0 = perfect score, ratio < 1.0 = lower score
                    let incomeScore = min(100.0, 100.0 * incomeRatio)
                    scores.append(incomeScore)
                }
            }
            
            // Expense adherence: LESS spending than planned = BETTER score  
            if !expensePlans.isEmpty {
                let totalExpensePlanned = expensePlans.reduce(0) { $0 + $1.amountInCurrency }
                let totalExpenseActual = expenseTransactions.reduce(0) { $0 + $1.amountInCurrency }
                
                if totalExpensePlanned > 0 {
                    let expenseRatio = min(totalExpenseActual / totalExpensePlanned, 2.0) // Cap at 200%
                    // For expenses: ratio <= 1.0 = perfect score, ratio > 1.0 = lower score
                    let expenseScore = max(0, 100.0 * (2.0 - expenseRatio))
                    scores.append(expenseScore)
                }
            }
            
            // Average the scores if we have both income and expense
            if !scores.isEmpty {
                budgetAdherenceScore = scores.reduce(0, +) / Double(scores.count)
            }
        }
        
        // 2. Consistency Score (based on spending variance)
        let consistencyScore = calculateConsistencyScore(transactions)
        
        // 3. Savings Rate Score (simplified)
        let savingsRateScore = calculateSavingsRateScore(transactions, budget: budget)
        
        // 4. Category Balance Score
        let categoryBalanceScore = calculateCategoryBalanceScore(transactions)
        
        // 5. Trend Score
        let trendScore = calculateTrendScore(transactions)
        
        // Weighted overall score
        let weights: [Double] = [0.3, 0.2, 0.25, 0.15, 0.1]
        let scores = [budgetAdherenceScore, consistencyScore, savingsRateScore, categoryBalanceScore, trendScore]
        let overallScore = zip(weights, scores).reduce(0) { $0 + $1.0 * $1.1 }
        
        return FinancialHealthScore(
            overallScore: max(0, min(100, overallScore)),
            budgetAdherenceScore: budgetAdherenceScore,
            consistencyScore: consistencyScore,
            savingsRateScore: savingsRateScore,
            categoryBalanceScore: categoryBalanceScore,
            trendScore: trendScore,
            lastCalculated: Date()
        )
    }
    
    private func calculateConsistencyScore(_ transactions: [LocalTransaction]) -> Double {
        guard transactions.count > 1 else { return 100.0 }
        
        let amounts = transactions.map { $0.amountInCurrency }
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let coefficientOfVariation = mean > 0 ? sqrt(variance) / mean : 0
        
        // Lower coefficient of variation = higher consistency
        return max(0, 100.0 * (1.0 - min(coefficientOfVariation, 1.0)))
    }
    
    private func calculateSavingsRateScore(_ transactions: [LocalTransaction], budget: LocalBudget?) -> Double {
        // Simplified - would need income data for real calculation
        return 75.0 // Placeholder score
    }
    
    private func calculateCategoryBalanceScore(_ transactions: [LocalTransaction]) -> Double {
        let categoryGroups = Dictionary(grouping: transactions) { $0.category?.id ?? "" }
        guard categoryGroups.count > 1 else { return 50.0 }
        
        let categoryTotals = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amountInCurrency } }
        let totalSpent = categoryTotals.values.reduce(0, +)
        
        if totalSpent == 0 { return 100.0 }
        
        // Calculate Gini coefficient for balance measurement
        let proportions = categoryTotals.values.map { $0 / totalSpent }.sorted()
        let n = Double(proportions.count)
        
        var giniSum = 0.0
        for (index, proportion) in proportions.enumerated() {
            let rank = Double(index + 1)
            giniSum += (2 * rank - n - 1) * proportion
        }
        let proportionSum = proportions.reduce(0, +)
        let gini = giniSum / (n - 1) / proportionSum
        
        // Lower Gini = better balance
        return max(0, 100.0 * (1.0 - gini))
    }
    
    private func calculateTrendScore(_ transactions: [LocalTransaction]) -> Double {
        guard transactions.count > 2 else { return 50.0 }
        
        let dateFormatter = ISO8601DateFormatter()
        let sortedTransactions = transactions.sorted { 
            let date1 = ($0.transactionDate.flatMap { dateFormatter.date(from: $0) }) ?? Date.distantPast
            let date2 = ($1.transactionDate.flatMap { dateFormatter.date(from: $0) }) ?? Date.distantPast
            return date1 < date2
        }
        
        let recentAmount = sortedTransactions.suffix(transactions.count / 3).reduce(0) { $0 + $1.amountInCurrency }
        let earlierAmount = sortedTransactions.prefix(transactions.count / 3).reduce(0) { $0 + $1.amountInCurrency }
        
        if earlierAmount == 0 { return 50.0 }
        
        let trendRatio = recentAmount / earlierAmount
        
        // Stable or decreasing trend is better for expenses
        if trendRatio <= 1.0 {
            return 100.0 * trendRatio
        } else {
            return max(0, 100.0 / trendRatio)
        }
    }
    
    private func generateInsights(
        transactions: [LocalTransaction], 
        categories: [LocalCategory], 
        plans: [LocalBudgetPeriodPlan]
    ) async {
        // Early return if smart notifications are disabled
        guard notificationsEnabled else {
            return
        }
        
        var newInsights: [SmartInsight] = []
        
        // Budget health insights
        if let healthScore = currentHealthScore {
            if healthScore.overallScore < 60 {
                newInsights.append(SmartInsight(
                    id: UUID(),
                    type: .healthScore,
                    title: "Financial Health Needs Attention",
                    description: "Your financial health score is \(Int(healthScore.overallScore))/100. Focus on budget adherence and consistency.",
                    priority: .high,
                    actionable: true,
                    relatedCategoryId: nil,
                    createdDate: Date(),
                    isRead: false
                ))
            } else if healthScore.overallScore > 85 {
                newInsights.append(SmartInsight(
                    id: UUID(),
                    type: .healthScore,
                    title: "Excellent Financial Health!",
                    description: "Your financial health score is \(Int(healthScore.overallScore))/100. Keep up the great work!",
                    priority: .low,
                    actionable: false,
                    relatedCategoryId: nil,
                    createdDate: Date(),
                    isRead: false
                ))
            }
        }
        
        // Forecast insights
        for (categoryId, forecast) in forecastsCache {
            let category = categories.first { $0.id == categoryId }
            let categoryName = category?.name ?? "Unknown Category"
            
            newInsights.append(SmartInsight(
                id: UUID(),
                type: .forecast,
                title: "Spending Forecast",
                description: "Based on your pattern, you're likely to spend $\(Int(forecast.forecastAmount)) on \(categoryName) next month.",
                priority: .medium,
                actionable: true,
                relatedCategoryId: categoryId,
                createdDate: Date(),
                isRead: false
            ))
        }
        
        await MainActor.run {
            // Save all new insights to Core Data for persistence
            for insight in newInsights {
                self.saveInsightToCoreData(insight)
            }
            
            // Add to current session for immediate UI display
            self.insights.append(contentsOf: newInsights)
            // Keep only recent insights (last 30)
            if self.insights.count > 30 {
                self.insights = Array(self.insights.suffix(30))
            }
        }
    }
    
    private func createAnomalyInsight(from anomaly: AnomalyResult) {
        let priority: InsightPriority = switch anomaly.severity {
        case .low: .low
        case .medium: .medium
        case .high: .high
        case .critical: .urgent
        }
        
        let insight = SmartInsight(
            id: UUID(),
            type: .anomaly,
            title: "Unusual Transaction Detected",
            description: anomaly.reason,
            priority: priority,
            actionable: true,
            relatedCategoryId: anomaly.transaction.category?.id,
            createdDate: Date(),
            isRead: false
        )
        
        // Save to Core Data for persistence and duplicate prevention
        saveInsightToCoreData(insight)
        // Add to current session for immediate UI display  
        insights.append(insight)
    }
    
    // MARK: - Notification Settings Persistence
    
    private func loadNotificationSetting() {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
        
        do {
            let users = try context.fetch(request)
            if let currentUser = users.first {
                DispatchQueue.main.async { [weak self] in
                    self?.notificationsEnabled = currentUser.smartNotificationsEnabled
                }
            } else {
                // No user found - using default notification setting
            }
        } catch {
            // Failed to load notification setting
        }
    }
    
    private func saveNotificationSetting() {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
        
        do {
            let users = try context.fetch(request)
            if let currentUser = users.first {
                currentUser.smartNotificationsEnabled = notificationsEnabled
                try context.save()
            } else {
                // No user found - cannot save notification setting
            }
        } catch {
            // Failed to save notification setting
        }
    }
}

// MARK: - Extensions

extension DispatchQueue {
    func run<T>(operation: @escaping () async -> T) async -> T {
        return await withUnsafeContinuation { continuation in
            self.async {
                Task {
                    let result = await operation()
                    continuation.resume(returning: result)
                }
            }
        }
    }
}