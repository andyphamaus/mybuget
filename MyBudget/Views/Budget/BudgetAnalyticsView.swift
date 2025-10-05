import SwiftUI
import CoreData

// MARK: - Enhanced Budget Analytics View (Tab 3: Analytics)

struct BudgetAnalyticsView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @EnvironmentObject var smartAnalytics: SmartAnalyticsService
    @StateObject private var notificationService = NotificationService()
    @State private var isAnalyzing = false
    @State private var lastPeriodId: String?
    
    // Helper to check actual user notification setting from Core Data
    private func areSmartNotificationsEnabled() -> Bool {
        let context = PersistenceController.shared.viewContext
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Financial Health Score Card (New)
                if let healthScore = smartAnalytics.currentHealthScore {
                    HealthScoreCard(
                        healthScore: healthScore,
                        transactions: viewModel.transactions,
                        categories: viewModel.categories
                    )
                    .padding(.horizontal)
                }
                
                // Smart Insights Section (New)
                if !smartAnalytics.insights.isEmpty {
                    SmartInsightsSection(
                        insights: smartAnalytics.insights,
                        transactions: viewModel.transactions,
                        categories: viewModel.categories,
                        analytics: smartAnalytics,
                        onMarkAsRead: { insightId in
                            smartAnalytics.markInsightAsRead(insightId)
                        }
                    )
                    .padding(.horizontal)
                }
                
                // Predictive Charts (New)
                if !smartAnalytics.forecasts.isEmpty {
                    PredictiveChartView(
                        forecasts: smartAnalytics.forecasts,
                        categories: viewModel.categories,
                        historicalData: viewModel.transactions
                    )
                    .padding(.horizontal)
                }
                
                // Overall Progress Card (Enhanced)
                if let summary = viewModel.budgetSummary {
                    OverallProgressCard(summary: summary)
                        .padding(.horizontal)
                }
                
                // Category Insights (Existing)
                CategoryInsightsSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Budget Insights (Existing)
                BudgetInsightsSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Smart Notifications Settings
                SmartNotificationToggleCard(
                    isEnabled: $smartAnalytics.notificationsEnabled,
                    isAuthorized: notificationService.isAuthorized,
                    onRequestPermission: {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    }
                )
                .padding(.horizontal)
                
                // Bottom padding for better scroll experience
                Spacer(minLength: 100)
            }
            .padding(.top, 10)
        }
        .refreshable {
            await refreshAnalytics()
        }
        .task {
            await runInitialAnalysis()
        }
        .onReceive(viewModel.$transactions) { transactions in
            Task {
                await smartAnalytics.notifyNewTransactions(transactions)
                
                // Check for immediate notifications on new transactions (only if smart notifications are enabled)
                if areSmartNotificationsEnabled() {
                    await notificationService.checkBudgetAlerts(
                        transactions: transactions,
                        categories: viewModel.categories,
                        plans: viewModel.plans,
                        insights: smartAnalytics.insights
                    )
                }
            }
        }
        .onReceive(viewModel.$currentPeriod) { period in
            // Only force refresh when actually changing periods (not during normal refresh)
            let currentPeriodId = period?.id
            if lastPeriodId != nil && lastPeriodId != currentPeriodId {
                Task {
                    // Only use force refresh when truly changing periods
                    await smartAnalytics.forceAnalyzeFinancialData(
                        transactions: viewModel.transactions,
                        categories: viewModel.categories,
                        plans: viewModel.plans,
                        budget: viewModel.currentBudget
                    )
                }
            }
            lastPeriodId = currentPeriodId
        }
        .overlay(
            Group {
                if isAnalyzing {
                    ProgressView("Analyzing your financial data...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(8)
                }
            }
        )
    }
    
    private func runInitialAnalysis() async {
        guard !viewModel.transactions.isEmpty else { return }
        
        isAnalyzing = true
        await smartAnalytics.analyzeFinancialData(
            transactions: viewModel.transactions,
            categories: viewModel.categories,
            plans: viewModel.plans,
            budget: viewModel.currentBudget
        )
        
        // Check for smart notifications after analysis (only if enabled)
        if areSmartNotificationsEnabled() {
            await notificationService.checkBudgetAlerts(
                transactions: viewModel.transactions,
                categories: viewModel.categories,
                plans: viewModel.plans,
                insights: smartAnalytics.insights
            )
        }
        
        isAnalyzing = false
    }
    
    private func refreshAnalytics() async {
        // Ensure we have a current period
        guard let currentPeriod = viewModel.currentPeriod else {
            return
        }
        
        // Refresh current budget data and ensure current period data is loaded
        await viewModel.refreshCurrentBudgetData()
        
        // Double-check that we have current period data loaded
        
        // Verify transactions are for current period
        let periodTransactions = viewModel.transactions.filter { transaction in
            transaction.period?.id == currentPeriod.id
        }
        
        // Verify plans are for current period  
        let periodPlans = viewModel.plans.filter { plan in
            plan.period?.id == currentPeriod.id
        }
        
        if periodTransactions.count != viewModel.transactions.count {
        }
        
        if periodPlans.count != viewModel.plans.count {
        }
        
        // Use only current period data for analysis
        await smartAnalytics.analyzeFinancialData(
            transactions: periodTransactions,
            categories: viewModel.categories,
            plans: periodPlans,
            budget: viewModel.currentBudget
        )
        
        // Check for smart notifications after analysis (only if enabled)
        if areSmartNotificationsEnabled() {
            await notificationService.checkBudgetAlerts(
                transactions: periodTransactions,
                categories: viewModel.categories,
                plans: periodPlans,
                insights: smartAnalytics.insights
            )
        }
        
    }
}

// MARK: - Overall Progress Card

struct OverallProgressCard: View {
    let summary: BudgetSummary
    
    private var progressPercentage: Double {
        let totalPlanned = summary.plannedIncomeAmount + summary.plannedExpenseAmount
        let totalSpent = summary.actualIncomeAmount + summary.actualExpenseAmount
        guard totalPlanned > 0 else { return 0 }
        return min(totalSpent / totalPlanned, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Overall Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
            }
            
            // Circular progress
            HStack(spacing: 24) {
                // Progress circle
                CircularProgressView(
                    progress: progressPercentage,
                    lineWidth: 8,
                    color: (summary.actualIncomeAmount + summary.actualExpenseAmount) > (summary.plannedIncomeAmount + summary.plannedExpenseAmount) ? .red : .blue
                )
                .frame(width: 80, height: 80)
                
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Spent:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(summary.actualIncomeAmount + summary.actualExpenseAmount, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Planned:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(summary.plannedIncomeAmount + summary.plannedExpenseAmount, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Remaining:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        let remaining = (summary.plannedIncomeAmount + summary.plannedExpenseAmount) - (summary.actualIncomeAmount + summary.actualExpenseAmount)
                        Text("$\(remaining, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(remaining >= 0 ? .green : .red)
                    }
                }
            }
            
            // Progress percentage
            Text("\(Int(progressPercentage * 100))% of budget used")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Category Insights Section

struct CategoryInsightsSection: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Category Insights")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
            }
            
            // Top categories
            LazyVStack(spacing: 12) {
                ForEach(viewModel.expenseCategories.prefix(5), id: \.id) { category in
                    BudgetInsightCard(category: category, viewModel: viewModel)
                }
            }
            
            if viewModel.expenseCategories.isEmpty {
                Text("No spending data available yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Budget Insight Card

struct BudgetInsightCard: View {
    let category: LocalCategory
    let viewModel: BudgetViewModel
    
    private var progressPercentage: Double {
        let planned = plannedAmount
        let actual = actualAmount
        guard planned > 0 else { return 0 }
        return min(actual / planned, 1.0)
    }
    
    private var plannedAmount: Double {
        return viewModel.plans.filter { $0.category?.id == category.id }.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    private var actualAmount: Double {
        return viewModel.transactions.filter { $0.category?.id == category.id }.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name ?? "Unknown Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("$\(actualAmount, specifier: "%.0f") of $\(plannedAmount, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(actualAmount > plannedAmount ? .red : .blue)
                
                // Mini progress bar
                ProgressView(value: progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: actualAmount > plannedAmount ? .red : .blue))
                    .frame(width: 60)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Budget Insights Section

struct BudgetInsightsSection: View {
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showInsights = false
    @State private var insightOffset = CGSize.zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header with gradient background
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 Smart Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    
                    Text("AI-powered budget analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Animated sparkle icon
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(LinearGradient(
                        colors: [.yellow, .orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .scaleEffect(showInsights ? 1.2 : 1.0)
                    .rotationEffect(.degrees(showInsights ? 360 : 0))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showInsights)
            }
            
            // Insights with staggered animations
            VStack(alignment: .leading, spacing: 16) {
                if let summary = viewModel.budgetSummary {
                    // FIXED: Handle income vs expense insights properly
                    
                    // EXPENSE BUDGET ANALYSIS: spending MORE than planned = bad
                    if summary.plannedExpenseAmount > 0 && summary.actualExpenseAmount > summary.plannedExpenseAmount {
                        let overspent = summary.actualExpenseAmount - summary.plannedExpenseAmount
                        EnhancedInsightCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "⚠️ Expense Over Budget",
                            description: "You've exceeded your expense budget by $\(Int(overspent))",
                            colors: [.red, .pink],
                            delay: 0.1
                        )
                    }
                    
                    // INCOME ACHIEVEMENT ANALYSIS: earning MORE than planned = good!
                    if summary.plannedIncomeAmount > 0 && summary.actualIncomeAmount > summary.plannedIncomeAmount {
                        let extraIncome = summary.actualIncomeAmount - summary.plannedIncomeAmount
                        EnhancedInsightCard(
                            icon: "star.circle.fill",
                            title: "🎉 Income Achievement!",
                            description: "Congratulations! You've earned $\(Int(extraIncome)) more than planned",
                            colors: [.green, .mint],
                            delay: 0.1
                        )
                    }
                    
                    // EXPENSE BUDGET ON TRACK: spending less than planned = good
                    if summary.plannedExpenseAmount > 0 && summary.actualExpenseAmount <= summary.plannedExpenseAmount && summary.actualExpenseAmount > 0 {
                        let remaining = summary.plannedExpenseAmount - summary.actualExpenseAmount
                        EnhancedInsightCard(
                            icon: "checkmark.circle.fill",
                            title: "✅ Expense On Track",
                            description: "You have $\(Int(remaining)) remaining in your expense budget",
                            colors: [.green, .mint],
                            delay: 0.2
                        )
                    }
                    
                    // INCOME BELOW TARGET: earning LESS than planned = concern
                    if summary.plannedIncomeAmount > 0 && summary.actualIncomeAmount < summary.plannedIncomeAmount {
                        let shortfall = summary.plannedIncomeAmount - summary.actualIncomeAmount
                        EnhancedInsightCard(
                            icon: "arrow.down.circle",
                            title: "📉 Income Below Target",
                            description: "Your income is $\(Int(shortfall)) below your target. Consider reviewing income sources.",
                            colors: [.orange, .yellow],
                            delay: 0.3
                        )
                    }
                    
                    // Top spending category (only show if has both plans and transactions)
                    let categoriesWithPlansAndTransactions = viewModel.expenseCategories.filter { category in
                        let hasTransactions = !viewModel.transactions.filter { $0.category?.id == category.id }.isEmpty
                        let hasPlans = !viewModel.plans.filter { $0.category?.id == category.id }.isEmpty
                        return hasTransactions && hasPlans
                    }
                    
                    if let topCategory = categoriesWithPlansAndTransactions.first {
                        EnhancedInsightCard(
                            icon: "chart.bar.fill",
                            title: "📊 Top Spending",
                            description: "\(topCategory.name ?? "Unknown category") accounts for your highest expenses",
                            colors: [.blue, .cyan],
                            delay: 0.3
                        )
                    }
                    
                    // Categories without plans
                    let categoriesWithoutPlans = viewModel.categories.filter { category in
                        let hasTransactions = !viewModel.transactions.filter { $0.category?.id == category.id }.isEmpty
                        let hasPlans = !viewModel.plans.filter { $0.category?.id == category.id }.isEmpty
                        return hasTransactions && !hasPlans
                    }
                    if !categoriesWithoutPlans.isEmpty {
                        EnhancedInsightCard(
                            icon: "questionmark.circle.fill",
                            title: "🔍 Unplanned Spending",
                            description: "\(categoriesWithoutPlans.count) categories have spending without plans",
                            colors: [.orange, .yellow],
                            delay: 0.4
                        )
                    }
                }
                
                // If no insights with attractive empty state
                if viewModel.budgetSummary == nil || viewModel.categories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .scaleEffect(showInsights ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showInsights)
                        
                        VStack(spacing: 8) {
                            Text("🚀 Ready for Insights!")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Start tracking your budget to unlock personalized AI insights and recommendations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
                }
            }
            .opacity(showInsights ? 1 : 0)
            .offset(y: showInsights ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: showInsights)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            showInsights = true
        }
    }
}

// MARK: - Enhanced Insight Card

struct EnhancedInsightCard: View {
    let icon: String
    let title: String
    let description: String
    let colors: [Color]
    let delay: Double
    
    @State private var isVisible = false
    @State private var shimmerPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Animated icon with gradient background
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: colors.map { $0.opacity(0.15) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
                .opacity(0.6)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: colors.map { $0.opacity(0.08) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                // Shimmer effect
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: shimmerPhase)
                .clipped()
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(
                    colors: colors.map { $0.opacity(0.3) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        )
        .shadow(color: colors.first?.opacity(0.2) ?? .clear, radius: 5, x: 0, y: 2)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .animation(.easeOut(duration: 0.6).delay(delay), value: isVisible)
        .onAppear {
            isVisible = true
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerPhase = 300
            }
        }
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Real-time Status Card

struct RealTimeStatusCard: View {
    let lastUpdate: Date
    let isAnalyzing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(isAnalyzing ? .orange : .green)
                    .frame(width: 8, height: 8)
                    .opacity(isAnalyzing ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnalyzing)
                
                Text(isAnalyzing ? "Analyzing..." : "Live")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isAnalyzing ? .orange : .green)
            }
            
            Spacer()
            
            // Last update time
            VStack(alignment: .trailing, spacing: 2) {
                Text("Last Updated")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(lastUpdate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            // Real-time icon
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Smart Notification Toggle Card

struct SmartNotificationToggleCard: View {
    @Binding var isEnabled: Bool
    let isAuthorized: Bool
    let onRequestPermission: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Notification icon
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Notifications")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Get notified about spending insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isAuthorized {
                Button("Allow") {
                    onRequestPermission()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue)
                .cornerRadius(16)
            } else {
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    BudgetAnalyticsView(viewModel: BudgetViewModel())
        .environmentObject(LocalAuthenticationService())
}