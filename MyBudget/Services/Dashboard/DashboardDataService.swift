import SwiftUI
import CoreData
import Foundation
import Combine

class DashboardDataService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var dashboardMetrics = DashboardMetrics()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshTime: Date?
    
    // MARK: - Dependencies
    private var taskService: LocalTaskService?
    private var activityService: LocalActivityService?
    private var budgetViewModel: BudgetViewModel?
    private var smartInsightsEngine: SmartInsightsEngine?
    
    // MARK: - Auto-refresh
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupAutoRefresh()
        setupAppStateNotifications()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func setServices(taskService: LocalTaskService, activityService: LocalActivityService) {
        self.taskService = taskService
        self.activityService = activityService
    }
    
    func setBudgetViewModel(_ budgetViewModel: BudgetViewModel) {
        self.budgetViewModel = budgetViewModel
    }
    
    // MARK: - Data Loading
    @MainActor
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        // Load all data concurrently
        async let taskMetrics = loadTaskMetrics()
        async let budgetMetrics = loadBudgetMetrics()
        async let activityData = loadRecentActivity()
        async let correlationData = loadCorrelationData()
        async let chartData = loadChartData()
        
        let (tasks, budget, activity, correlation, charts) = await (taskMetrics, budgetMetrics, activityData, correlationData, chartData)
        
        // Combine all metrics
        dashboardMetrics = DashboardMetrics(
            productivity: tasks,
            financial: budget,
            recentActivities: activity,
            correlationInsights: correlation,
            chartData: charts,
            lastUpdated: Date()
        )
        
        lastRefreshTime = Date()
        isLoading = false
    }
    
    // MARK: - Task Metrics
    private func loadTaskMetrics() async -> ProductivityMetrics {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        guard let taskService = taskService else {
            return ProductivityMetrics()
        }
        let allTasks = await taskService.tasks
        
        // Today's metrics
        let todayTasks = allTasks.compactMap { $0 }.filter { task in
            if let createdDate = task.createdDate {
                return calendar.isDate(createdDate, inSameDayAs: today)
            }
            return false
        }
        
        let todayCompleted = todayTasks.filter { $0.isCompleted }
        let dailyCompletionRate = todayTasks.isEmpty ? 0.0 : Double(todayCompleted.count) / Double(todayTasks.count) * 100
        
        // Weekly metrics
        let weekTasks = allTasks.compactMap { $0 }.filter { task in
            if let createdDate = task.createdDate {
                return createdDate >= weekAgo
            }
            return false
        }
        
        let weekCompleted = weekTasks.filter { $0.isCompleted }
        let weeklyProductivityScore = calculateWeeklyProductivityScore(weekCompleted)
        
        // Overdue tasks
        let overdueTasks = allTasks.compactMap { $0 }.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate < Date()
        }
        
        // Average completion time (mock calculation for now)
        let avgCompletionTime = calculateAverageCompletionTime(allTasks.compactMap { $0 }.filter { $0.isCompleted })
        
        return ProductivityMetrics(
            dailyCompletionRate: dailyCompletionRate,
            weeklyProductivityScore: weeklyProductivityScore,
            overdueTaskCount: overdueTasks.count,
            averageCompletionTime: avgCompletionTime,
            totalTasksToday: todayTasks.count,
            completedToday: todayCompleted.count,
            totalTasksWeek: weekTasks.count,
            completedWeek: weekCompleted.count
        )
    }
    
    // MARK: - Budget Metrics
    private func loadBudgetMetrics() async -> FinancialMetrics {
        guard let budgetVM = budgetViewModel else {
            return FinancialMetrics()
        }
        
        await budgetVM.loadInitialData()
        
        _ = Calendar.current
        _ = Date()
        
        // Get real budget data from current period
        let totalPlannedExpenses = await budgetVM.totalPlannedExpenses
        let totalActualExpenses = await budgetVM.totalActualExpenses
        let totalActualIncome = await budgetVM.totalActualIncome
        _ = await budgetVM.totalPlannedIncome
        
        // Calculate real financial metrics
        let budgetAdherenceScore: Double
        if totalPlannedExpenses > 0 {
            budgetAdherenceScore = max(0, ((totalPlannedExpenses - totalActualExpenses) / totalPlannedExpenses) * 100)
        } else {
            budgetAdherenceScore = totalActualExpenses == 0 ? 100 : 0
        }
        
        let savingsRate: Double
        if totalActualIncome > 0 {
            savingsRate = max(0, ((totalActualIncome - totalActualExpenses) / totalActualIncome) * 100)
        } else {
            savingsRate = 0
        }
        
        // Calculate monthly spending trend (compare with previous period)
        let monthlySpendingTrend = await calculateSpendingTrend(budgetVM: budgetVM)
        
        // Financial goal progress (based on savings vs spending)
        let financialGoalProgress = min(100, max(0, budgetAdherenceScore))
        
        return FinancialMetrics(
            budgetAdherenceScore: budgetAdherenceScore,
            monthlySpendingTrend: monthlySpendingTrend,
            savingsRate: savingsRate,
            financialGoalProgress: financialGoalProgress,
            totalBudget: totalPlannedExpenses,
            totalSpent: totalActualExpenses,
            totalIncome: totalActualIncome,
            remainingBudget: max(0, totalPlannedExpenses - totalActualExpenses)
        )
    }
    
    // MARK: - Helper Methods for Budget Calculations
    @MainActor
    private func calculateSpendingTrend(budgetVM: BudgetViewModel) async -> Double {
        // Simple calculation - in real app, compare with previous period
        let currentSpending = budgetVM.totalActualExpenses
        let plannedSpending = budgetVM.totalPlannedExpenses
        
        if plannedSpending > 0 {
            let spendingRatio = currentSpending / plannedSpending
            if spendingRatio < 0.8 {
                return -20.0 // 20% under budget (good trend)
            } else if spendingRatio < 1.0 {
                return -5.0 // 5% under budget
            } else if spendingRatio < 1.2 {
                return 10.0 // 10% over budget
            } else {
                return 25.0 // 25% over budget (bad trend)
            }
        }
        
        return 0.0
    }
    
    // MARK: - Activity Data
    private func loadRecentActivity() async -> [DashboardActivity] {
        guard let activityService = activityService else {
            return []
        }
        return await Array(activityService.activities.prefix(5)).map { activity in
            DashboardActivity(
                id: activity.id?.uuidString ?? UUID().uuidString,
                title: activity.title ?? "Unknown Activity",
                description: activity.activityDescription,
                type: ActivityType.from(activity.module ?? ""),
                timestamp: activity.timestamp ?? Date(),
                icon: activity.icon,
                color: Color(activity.color)
            )
        }
    }
    
    // MARK: - Correlation Analysis
    private func loadCorrelationData() async -> CorrelationInsights {
        // Mock correlation analysis - in real implementation, analyze historical data
        let taskProductivityCorrelation: Double = 0.75 // Strong positive correlation
        let spendingProductivityCorrelation: Double = -0.45 // Moderate negative correlation
        
        let insights = [
            "You complete 20% more tasks when spending stays under $50/day",
            "Your productivity peaks on Tuesdays - consider scheduling important tasks then",
            "Task completion rate drops 30% when daily spending exceeds budget"
        ]
        
        return CorrelationInsights(
            taskBudgetCorrelation: taskProductivityCorrelation,
            spendingProductivityCorrelation: spendingProductivityCorrelation,
            insights: insights,
            confidenceScore: 0.85
        )
    }
    
    // MARK: - Helper Methods
    private func calculateWeeklyProductivityScore(_ completedTasks: [LocalTask]) -> Double {
        // Simple weighted score based on priority and completion
        let totalScore = completedTasks.reduce(0.0) { score, task in
            let priorityWeight = Double(task.priority) * 10.0
            let timeBonus = task.isCompleted ? 20.0 : 0.0
            return score + priorityWeight + timeBonus
        }
        return min(100.0, totalScore / 10.0) // Normalize to 0-100
    }
    
    private func calculateAverageCompletionTime(_ completedTasks: [LocalTask]) -> Double {
        guard !completedTasks.isEmpty else { return 0.0 }
        
        let totalHours = completedTasks.compactMap { task in
            guard let created = task.createdDate, let completed = task.completedDate else { return nil }
            return completed.timeIntervalSince(created) / 3600.0 // Convert to hours
        }.reduce(0.0, +)
        
        return totalHours / Double(completedTasks.count)
    }
    
    // MARK: - Chart Data Loading
    @MainActor
    private func loadChartData() async -> DashboardChartData {
        guard let taskService = taskService, 
              let budgetViewModel = budgetViewModel,
              let activityService = activityService else {
            return DashboardChartData()
        }
        
        // Initialize and configure smart insights engine if needed
        if smartInsightsEngine == nil {
            smartInsightsEngine = SmartInsightsEngine()
        }
        
        guard let insightsEngine = smartInsightsEngine else {
            return DashboardChartData(smartSuggestions: [])
        }
        
        insightsEngine.configure(
            taskService: taskService,
            budgetViewModel: budgetViewModel,
            activityService: activityService
        )
        
        await insightsEngine.analyzeAndGenerateInsights()
        
        return DashboardChartData(smartSuggestions: insightsEngine.smartSuggestions)
    }
    
    // MARK: - Auto-refresh Setup
    private func setupAutoRefresh() {
        // Refresh dashboard data every 5 minutes when app is active
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadDashboardData()
            }
        }
    }
    
    private func setupAppStateNotifications() {
        // Refresh when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Only refresh if it's been more than 2 minutes since last refresh
                    if let lastRefresh = self?.lastRefreshTime,
                       Date().timeIntervalSince(lastRefresh) > 120 {
                        await self?.loadDashboardData()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Stop timer when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.refreshTimer?.invalidate()
            }
            .store(in: &cancellables)
        
        // Restart timer when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.setupAutoRefresh()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Models
struct DashboardMetrics {
    let productivity: ProductivityMetrics
    let financial: FinancialMetrics
    let recentActivities: [DashboardActivity]
    let correlationInsights: CorrelationInsights
    let chartData: DashboardChartData
    let lastUpdated: Date
    
    init() {
        self.productivity = ProductivityMetrics()
        self.financial = FinancialMetrics()
        self.recentActivities = []
        self.correlationInsights = CorrelationInsights()
        self.chartData = DashboardChartData()
        self.lastUpdated = Date()
    }
    
    init(productivity: ProductivityMetrics, 
         financial: FinancialMetrics, 
         recentActivities: [DashboardActivity], 
         correlationInsights: CorrelationInsights,
         chartData: DashboardChartData,
         lastUpdated: Date) {
        self.productivity = productivity
        self.financial = financial
        self.recentActivities = recentActivities
        self.correlationInsights = correlationInsights
        self.chartData = chartData
        self.lastUpdated = lastUpdated
    }
}

struct ProductivityMetrics {
    let dailyCompletionRate: Double
    let weeklyProductivityScore: Double
    let overdueTaskCount: Int
    let averageCompletionTime: Double
    let totalTasksToday: Int
    let completedToday: Int
    let totalTasksWeek: Int
    let completedWeek: Int
    
    init() {
        self.dailyCompletionRate = 0.0
        self.weeklyProductivityScore = 0.0
        self.overdueTaskCount = 0
        self.averageCompletionTime = 0.0
        self.totalTasksToday = 0
        self.completedToday = 0
        self.totalTasksWeek = 0
        self.completedWeek = 0
    }
    
    init(dailyCompletionRate: Double, weeklyProductivityScore: Double, overdueTaskCount: Int, 
         averageCompletionTime: Double, totalTasksToday: Int, completedToday: Int, 
         totalTasksWeek: Int, completedWeek: Int) {
        self.dailyCompletionRate = dailyCompletionRate
        self.weeklyProductivityScore = weeklyProductivityScore
        self.overdueTaskCount = overdueTaskCount
        self.averageCompletionTime = averageCompletionTime
        self.totalTasksToday = totalTasksToday
        self.completedToday = completedToday
        self.totalTasksWeek = totalTasksWeek
        self.completedWeek = completedWeek
    }
}

struct FinancialMetrics {
    let budgetAdherenceScore: Double
    let monthlySpendingTrend: Double
    let savingsRate: Double
    let financialGoalProgress: Double
    let totalBudget: Double
    let totalSpent: Double
    let totalIncome: Double
    let remainingBudget: Double
    
    init() {
        self.budgetAdherenceScore = 0.0
        self.monthlySpendingTrend = 0.0
        self.savingsRate = 0.0
        self.financialGoalProgress = 0.0
        self.totalBudget = 0.0
        self.totalSpent = 0.0
        self.totalIncome = 0.0
        self.remainingBudget = 0.0
    }
    
    init(budgetAdherenceScore: Double, monthlySpendingTrend: Double, savingsRate: Double, 
         financialGoalProgress: Double, totalBudget: Double, totalSpent: Double, 
         totalIncome: Double, remainingBudget: Double) {
        self.budgetAdherenceScore = budgetAdherenceScore
        self.monthlySpendingTrend = monthlySpendingTrend
        self.savingsRate = savingsRate
        self.financialGoalProgress = financialGoalProgress
        self.totalBudget = totalBudget
        self.totalSpent = totalSpent
        self.totalIncome = totalIncome
        self.remainingBudget = remainingBudget
    }
}

struct DashboardActivity: Equatable {
    let id: String
    let title: String
    let description: String?
    let type: ActivityType
    let timestamp: Date
    let icon: String
    let color: Color
    
    static func == (lhs: DashboardActivity, rhs: DashboardActivity) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ActivityType {
    case task
    case budget
    case general
    
    static func from(_ module: String) -> ActivityType {
        switch module.lowercased() {
        case "task", "tasks":
            return .task
        case "budget", "finance":
            return .budget
        default:
            return .general
        }
    }
}

struct CorrelationInsights {
    let taskBudgetCorrelation: Double
    let spendingProductivityCorrelation: Double
    let insights: [String]
    let confidenceScore: Double
    
    init() {
        self.taskBudgetCorrelation = 0.0
        self.spendingProductivityCorrelation = 0.0
        self.insights = []
        self.confidenceScore = 0.0
    }
    
    init(taskBudgetCorrelation: Double, spendingProductivityCorrelation: Double, 
         insights: [String], confidenceScore: Double) {
        self.taskBudgetCorrelation = taskBudgetCorrelation
        self.spendingProductivityCorrelation = spendingProductivityCorrelation
        self.insights = insights
        self.confidenceScore = confidenceScore
    }
}

// MARK: - Chart Data Models
struct DashboardChartData {
    let hasChartsIntegration: Bool
    let smartSuggestions: [SmartSuggestion]
    
    init() {
        self.hasChartsIntegration = true // Swift Charts is integrated
        self.smartSuggestions = []
    }
    
    init(smartSuggestions: [SmartSuggestion]) {
        self.hasChartsIntegration = true
        self.smartSuggestions = smartSuggestions
    }
}