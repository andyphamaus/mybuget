import Foundation
import SwiftUI

@MainActor
class SmartInsightsEngine: ObservableObject {
    @Published var smartSuggestions: [SmartSuggestion] = []
    @Published var correlationAnalysis: CorrelationAnalysisResult?
    @Published var isAnalyzing = false
    
    private var taskService: LocalTaskService?
    private var budgetViewModel: BudgetViewModel?
    private var activityService: LocalActivityService?
    
    // MARK: - Configuration
    func configure(taskService: LocalTaskService, budgetViewModel: BudgetViewModel, activityService: LocalActivityService) {
        self.taskService = taskService
        self.budgetViewModel = budgetViewModel
        self.activityService = activityService
    }
    
    // MARK: - Main Analysis Function
    func analyzeAndGenerateInsights() async {
        guard let taskService = taskService, let budgetViewModel = budgetViewModel else {
            return
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Perform correlation analysis
            let analysis = await performCorrelationAnalysis(
                taskService: taskService,
                budgetViewModel: budgetViewModel
            )
            
            correlationAnalysis = analysis
            
            // Generate smart suggestions based on analysis
            let suggestions = await generateSmartSuggestions(
                from: analysis,
                taskService: taskService,
                budgetViewModel: budgetViewModel
            )
            
            smartSuggestions = suggestions
            
        } catch {
            smartSuggestions = [generateFallbackSuggestion()]
        }
    }
    
    // MARK: - Correlation Analysis
    private func performCorrelationAnalysis(
        taskService: LocalTaskService,
        budgetViewModel: BudgetViewModel
    ) async -> CorrelationAnalysisResult {
        
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        // Collect daily data points
        var dailyDataPoints: [DailyAnalysisPoint] = []
        
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Task data for this day
            let dayTasks = taskService.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= dayStart && dueDate < dayEnd
            }
            
            let completedTasks = dayTasks.filter { $0.isCompleted }.count
            let totalTasks = max(dayTasks.count, 1) // Avoid division by zero
            let completionRate = Double(completedTasks) / Double(totalTasks)
            
            // Simulated spending data (in real implementation, this would come from actual transactions)
            let dailySpending = generateRealisticSpendingData(for: date)
            
            let dataPoint = DailyAnalysisPoint(
                date: date,
                tasksCompleted: completedTasks,
                totalTasks: totalTasks,
                completionRate: completionRate,
                dailySpending: dailySpending,
                isWeekend: calendar.isDateInWeekend(date)
            )
            
            dailyDataPoints.append(dataPoint)
        }
        
        // Calculate correlations
        let productivitySpendingCorrelation = calculateCorrelation(
            x: dailyDataPoints.map { $0.completionRate },
            y: dailyDataPoints.map { $0.dailySpending }
        )
        
        let weekendSpendingPattern = analyzeWeekendSpendingPattern(dailyDataPoints)
        let optimalSpendingRange = findOptimalSpendingRange(dailyDataPoints)
        let productivityTrends = analyzeProductivityTrends(dailyDataPoints)
        
        return CorrelationAnalysisResult(
            productivitySpendingCorrelation: productivitySpendingCorrelation,
            weekendSpendingPattern: weekendSpendingPattern,
            optimalSpendingRange: optimalSpendingRange,
            productivityTrends: productivityTrends,
            dailyDataPoints: dailyDataPoints,
            analysisDate: Date(),
            confidenceScore: calculateOverallConfidence(dailyDataPoints)
        )
    }
    
    // MARK: - Smart Suggestions Generation
    private func generateSmartSuggestions(
        from analysis: CorrelationAnalysisResult,
        taskService: LocalTaskService,
        budgetViewModel: BudgetViewModel
    ) async -> [SmartSuggestion] {
        
        var suggestions: [SmartSuggestion] = []
        
        // 1. Productivity-Spending Correlation Insights
        if abs(analysis.productivitySpendingCorrelation) > 0.3 {
            suggestions.append(generateProductivitySpendingInsight(from: analysis))
        }
        
        // 2. Weekend Spending Pattern Insights
        if analysis.weekendSpendingPattern.averageIncrease > 0.2 {
            suggestions.append(generateWeekendSpendingInsight(from: analysis))
        }
        
        // 3. Optimal Spending Range Insights
        if let optimalRange = analysis.optimalSpendingRange {
            suggestions.append(generateOptimalSpendingInsight(from: optimalRange, analysis: analysis))
        }
        
        // 4. Task Completion Pattern Insights
        suggestions.append(contentsOf: generateTaskPatternInsights(from: analysis, taskService: taskService))
        
        // 5. Budget Adherence Insights
        suggestions.append(contentsOf: await generateBudgetInsights(budgetViewModel: budgetViewModel, analysis: analysis))
        
        // 6. Predictive Insights
        suggestions.append(contentsOf: generatePredictiveInsights(from: analysis))
        
        // Sort by confidence score and return top suggestions
        return Array(suggestions.sorted { $0.confidenceScore > $1.confidenceScore }.prefix(5))
    }
    
    // MARK: - Individual Insight Generators
    private func generateProductivitySpendingInsight(from analysis: CorrelationAnalysisResult) -> SmartSuggestion {
        let correlation = analysis.productivitySpendingCorrelation
        
        if correlation > 0.5 {
            return SmartSuggestion(
                type: .habit,
                title: "Productivity-Spending Synergy",
                description: "Your productivity increases with moderate spending. You're \(Int(correlation * 100))% more efficient on days with balanced expenses.",
                icon: "chart.line.uptrend.xyaxis",
                confidenceScore: min(correlation * 100, 95),
                potentialImpact: "+\(Int(correlation * 40))% efficiency",
                timeframe: "Daily",
                actionTitle: "Maintain Balance"
            )
        } else if correlation < -0.5 {
            return SmartSuggestion(
                type: .warning,
                title: "Spending Impact Alert",
                description: "Higher spending correlates with lower productivity. Consider budget limits to maintain focus.",
                icon: "exclamationmark.triangle",
                confidenceScore: min(abs(correlation) * 100, 95),
                potentialImpact: "Reduce overspending",
                timeframe: "This week",
                actionTitle: "Set Spending Limits"
            )
        } else {
            return SmartSuggestion(
                type: .optimization,
                title: "Balanced Approach",
                description: "Your productivity and spending show a neutral relationship. Focus on consistency in both areas.",
                icon: "balance.horizontal",
                confidenceScore: 60,
                potentialImpact: "Maintain consistency",
                timeframe: "Ongoing",
                actionTitle: "Track Both Metrics"
            )
        }
    }
    
    private func generateWeekendSpendingInsight(from analysis: CorrelationAnalysisResult) -> SmartSuggestion {
        let pattern = analysis.weekendSpendingPattern
        let increasePercent = Int(pattern.averageIncrease * 100)
        
        return SmartSuggestion(
            type: .financial,
            title: "Weekend Spending Pattern",
            description: "Your weekend spending increases by \(increasePercent)% on average. Consider setting weekend-specific budgets.",
            icon: "calendar.badge.exclamationmark",
            confidenceScore: Double(min(increasePercent + 50, 90)),
            potentialImpact: "Save $\(Int(pattern.potentialSavings))/month",
            timeframe: "Weekends",
            actionTitle: "Set Weekend Budget"
        )
    }
    
    private func generateOptimalSpendingInsight(from range: OptimalSpendingRange, analysis: CorrelationAnalysisResult) -> SmartSuggestion {
        return SmartSuggestion(
            type: .optimization,
            title: "Optimal Spending Zone",
            description: "Your peak productivity occurs when daily spending is between $\(Int(range.minAmount))-$\(Int(range.maxAmount)).",
            icon: "target",
            confidenceScore: range.confidence,
            potentialImpact: "+\(Int(range.productivityBoost * 100))% productivity",
            timeframe: "Daily",
            actionTitle: "Stay in Range"
        )
    }
    
    private func generateTaskPatternInsights(from analysis: CorrelationAnalysisResult, taskService: LocalTaskService) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Analyze overdue tasks
        let overdueTasks = taskService.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        if overdueTasks.count > 3 {
            suggestions.append(SmartSuggestion(
                type: .warning,
                title: "Overdue Tasks Alert",
                description: "You have \(overdueTasks.count) overdue tasks. Clearing these can improve your productivity momentum.",
                icon: "clock.badge.exclamationmark",
                confidenceScore: 85,
                potentialImpact: "Clear backlog",
                timeframe: "This week",
                actionTitle: "Review Overdue Tasks"
            ))
        }
        
        // Analyze completion patterns from trends
        if let trends = analysis.productivityTrends {
            if trends.averageCompletionRate > 0.8 {
                suggestions.append(SmartSuggestion(
                    type: .productivity,
                    title: "High Performer",
                    description: "You're maintaining an excellent \(Int(trends.averageCompletionRate * 100))% task completion rate. Keep up the momentum!",
                    icon: "star.circle",
                    confidenceScore: 90,
                    potentialImpact: "Maintain excellence",
                    timeframe: "Ongoing",
                    actionTitle: "Set New Goals"
                ))
            } else if trends.averageCompletionRate < 0.5 {
                suggestions.append(SmartSuggestion(
                    type: .productivity,
                    title: "Productivity Boost Needed",
                    description: "Your completion rate is \(Int(trends.averageCompletionRate * 100))%. Try breaking tasks into smaller, manageable chunks.",
                    icon: "arrow.up.circle",
                    confidenceScore: 75,
                    potentialImpact: "Improve completion",
                    timeframe: "This week",
                    actionTitle: "Break Down Tasks"
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateBudgetInsights(budgetViewModel: BudgetViewModel, analysis: CorrelationAnalysisResult) async -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // FIXED: Budget adherence analysis - Handle income vs expense properly
        let totalPlannedIncome = await budgetViewModel.totalPlannedIncome
        let totalActualIncome = await budgetViewModel.totalActualIncome
        let totalPlannedExpenses = await budgetViewModel.totalPlannedExpenses
        let totalActualExpenses = await budgetViewModel.totalActualExpenses
        
        // INCOME ANALYSIS: More actual income than planned = GOOD
        if totalPlannedIncome > 0 {
            let incomeRatio = totalActualIncome / totalPlannedIncome
            
            if incomeRatio >= 1.2 { // 20% above income target = CELEBRATION!
                suggestions.append(SmartSuggestion(
                    type: .financial,
                    title: "Income Achievement! 🎉",
                    description: "Congratulations! You've earned \(Int((incomeRatio - 1.0) * 100))% more than your income target. Great work!",
                    icon: "star.circle.fill",
                    confidenceScore: 95,
                    potentialImpact: "Increase savings",
                    timeframe: "This month",
                    actionTitle: "Boost Savings Goal"
                ))
            } else if incomeRatio < 0.8 { // 20% below income target = concern
                suggestions.append(SmartSuggestion(
                    type: .warning,
                    title: "Income Below Target",
                    description: "Your income is \(Int((1.0 - incomeRatio) * 100))% below target. Consider reviewing income sources or adjusting budget expectations.",
                    icon: "arrow.down.circle",
                    confidenceScore: 85,
                    potentialImpact: "Meet income goals",
                    timeframe: "This month",
                    actionTitle: "Review Income Strategy"
                ))
            }
        }
        
        // EXPENSE ANALYSIS: Less actual spending than planned = GOOD
        if totalPlannedExpenses > 0 {
            let expenseRatio = totalActualExpenses / totalPlannedExpenses
            
            if expenseRatio > 1.2 { // 20% over expense budget = WARNING
                suggestions.append(SmartSuggestion(
                    type: .warning,
                    title: "Expense Budget Alert",
                    description: "You're \(Int((expenseRatio - 1.0) * 100))% over your planned expenses. Consider adjusting spending or budget categories.",
                    icon: "exclamationmark.octagon",
                    confidenceScore: 90,
                    potentialImpact: "Get back on track",
                    timeframe: "Immediate",
                    actionTitle: "Review Spending"
                ))
            } else if expenseRatio <= 0.8 { // 20% under expense budget = GOOD
                suggestions.append(SmartSuggestion(
                    type: .financial,
                    title: "Expense Champion! 👏",
                    description: "Excellent spending discipline! You're \(Int((1.0 - expenseRatio) * 100))% under your expense budget. Consider increasing savings goals.",
                    icon: "checkmark.seal",
                    confidenceScore: 85,
                    potentialImpact: "Increase savings",
                    timeframe: "Next month",
                    actionTitle: "Boost Savings Goal"
                ))
            }
        }
        
        return suggestions
    }
    
    private func generatePredictiveInsights(from analysis: CorrelationAnalysisResult) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Predict based on recent trends
        if let trends = analysis.productivityTrends {
            if trends.isImproving && trends.confidence > 0.7 {
                suggestions.append(SmartSuggestion(
                    type: .optimization,
                    title: "Momentum Building",
                    description: "Your productivity is trending upward! Maintain current habits to reach peak performance by month-end.",
                    icon: "arrow.up.right.circle",
                    confidenceScore: trends.confidence * 100,
                    potentialImpact: "Peak performance",
                    timeframe: "2 weeks",
                    actionTitle: "Keep Current Pace"
                ))
            } else if !trends.isImproving && trends.confidence > 0.6 {
                suggestions.append(SmartSuggestion(
                    type: .habit,
                    title: "Course Correction Needed",
                    description: "Productivity is trending downward. Consider reviewing your recent patterns and making adjustments.",
                    icon: "arrow.counterclockwise",
                    confidenceScore: trends.confidence * 100,
                    potentialImpact: "Reverse trend",
                    timeframe: "This week",
                    actionTitle: "Review Recent Changes"
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Fallback Suggestion
    private func generateFallbackSuggestion() -> SmartSuggestion {
        return SmartSuggestion(
            type: .productivity,
            title: "Getting Started",
            description: "Complete more tasks and track your spending to unlock personalized insights and recommendations.",
            icon: "sparkles",
            confidenceScore: 50,
            potentialImpact: "Unlock insights",
            timeframe: "This week",
            actionTitle: "Add More Data"
        )
    }
    
    // MARK: - Helper Functions
    private func generateRealisticSpendingData(for date: Date) -> Double {
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(date)
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        // Base spending varies by day
        var baseSpending: Double = 45.0
        
        // Weekend modifier
        if isWeekend {
            baseSpending *= 1.4 // 40% higher on weekends
        }
        
        // Friday modifier (often higher spending)
        if dayOfWeek == 6 { // Friday
            baseSpending *= 1.2
        }
        
        // Add some randomness
        let randomFactor = Double.random(in: 0.7...1.3)
        return baseSpending * randomFactor
    }
    
    private func calculateCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0.0
    }
    
    private func analyzeWeekendSpendingPattern(_ dataPoints: [DailyAnalysisPoint]) -> WeekendSpendingPattern {
        let weekdaySpending = dataPoints.filter { !$0.isWeekend }.map { $0.dailySpending }
        let weekendSpending = dataPoints.filter { $0.isWeekend }.map { $0.dailySpending }
        
        let avgWeekday = weekdaySpending.isEmpty ? 0 : weekdaySpending.reduce(0, +) / Double(weekdaySpending.count)
        let avgWeekend = weekendSpending.isEmpty ? 0 : weekendSpending.reduce(0, +) / Double(weekendSpending.count)
        
        let increase = avgWeekday > 0 ? (avgWeekend - avgWeekday) / avgWeekday : 0
        let potentialSavings = max(0, increase * avgWeekday * 8) // 8 weekend days per month
        
        return WeekendSpendingPattern(
            averageWeekdaySpending: avgWeekday,
            averageWeekendSpending: avgWeekend,
            averageIncrease: increase,
            potentialSavings: potentialSavings
        )
    }
    
    private func findOptimalSpendingRange(_ dataPoints: [DailyAnalysisPoint]) -> OptimalSpendingRange? {
        // Find spending range with highest productivity
        let sortedByProductivity = dataPoints.sorted { $0.completionRate > $1.completionRate }
        let topPerformers = Array(sortedByProductivity.prefix(10)) // Top 10 days
        
        guard !topPerformers.isEmpty else { return nil }
        
        let spendingAmounts = topPerformers.map { $0.dailySpending }.sorted()
        let minAmount = spendingAmounts.first ?? 0
        let maxAmount = spendingAmounts.last ?? 100
        let averageProductivity = topPerformers.map { $0.completionRate }.reduce(0, +) / Double(topPerformers.count)
        
        // Calculate confidence based on consistency
        let spendingVariance = calculateVariance(spendingAmounts)
        let confidence = max(50, 100 - (spendingVariance * 2))
        
        return OptimalSpendingRange(
            minAmount: minAmount,
            maxAmount: maxAmount,
            averageProductivity: averageProductivity,
            confidence: confidence,
            productivityBoost: averageProductivity - 0.5 // Assume 0.5 is baseline
        )
    }
    
    private func analyzeProductivityTrends(_ dataPoints: [DailyAnalysisPoint]) -> ProductivityTrends? {
        guard dataPoints.count > 7 else { return nil }
        
        let sortedPoints = dataPoints.sorted { $0.date < $1.date }
        let completionRates = sortedPoints.map { $0.completionRate }
        
        let firstHalf = Array(completionRates.prefix(completionRates.count / 2))
        let secondHalf = Array(completionRates.suffix(completionRates.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let isImproving = secondAvg > firstAvg
        let averageCompletionRate = completionRates.reduce(0, +) / Double(completionRates.count)
        let variance = calculateVariance(completionRates)
        let confidence = max(0.3, 1.0 - variance) // Lower variance = higher confidence
        
        return ProductivityTrends(
            averageCompletionRate: averageCompletionRate,
            isImproving: isImproving,
            trendStrength: abs(secondAvg - firstAvg),
            confidence: confidence
        )
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    private func calculateOverallConfidence(_ dataPoints: [DailyAnalysisPoint]) -> Double {
        let dataPointCount = dataPoints.count
        let baseConfidence = min(Double(dataPointCount) / 30.0, 1.0) // More data = higher confidence
        
        // Factor in data consistency
        let completionRates = dataPoints.map { $0.completionRate }
        let variance = calculateVariance(completionRates)
        let consistencyBonus = max(0, 1.0 - variance) * 0.2
        
        return min(1.0, baseConfidence + consistencyBonus)
    }
}

// MARK: - Supporting Data Models
struct DailyAnalysisPoint {
    let date: Date
    let tasksCompleted: Int
    let totalTasks: Int
    let completionRate: Double
    let dailySpending: Double
    let isWeekend: Bool
}

struct CorrelationAnalysisResult {
    let productivitySpendingCorrelation: Double
    let weekendSpendingPattern: WeekendSpendingPattern
    let optimalSpendingRange: OptimalSpendingRange?
    let productivityTrends: ProductivityTrends?
    let dailyDataPoints: [DailyAnalysisPoint]
    let analysisDate: Date
    let confidenceScore: Double
}

struct WeekendSpendingPattern {
    let averageWeekdaySpending: Double
    let averageWeekendSpending: Double
    let averageIncrease: Double // Percentage increase
    let potentialSavings: Double // Monthly potential savings
}

struct OptimalSpendingRange {
    let minAmount: Double
    let maxAmount: Double
    let averageProductivity: Double
    let confidence: Double
    let productivityBoost: Double
}

struct ProductivityTrends {
    let averageCompletionRate: Double
    let isImproving: Bool
    let trendStrength: Double
    let confidence: Double
}