import SwiftUI

struct HomeView: View {
    @StateObject private var dashboardService = DashboardDataService()
    @StateObject private var taskService = LocalTaskService()
    @StateObject private var activityService = LocalActivityService()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @EnvironmentObject var authService: LocalAuthenticationService
    
    let onAddTask: () -> Void
    
    // MARK: - State
    @State private var selectedTab = 0 // 0 = Dashboard, 1 = Activity
    @State private var showingTaskDetails = false
    @State private var showingBudgetDetails = false
    @State private var refreshing = false
    @State private var animationTrigger = UUID()
    
    // Animation states
    @State private var cardsAppeared = false
    @State private var metricsAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section with Blue Background
            VStack(spacing: 0) {
                // Header
                HomeHeaderView(
                    user: authService.currentUser,
                    selectedTab: selectedTab
                )
                
                // Tab selector
                HomeTabSelector(selectedTab: $selectedTab)
            }
            .background(ThemeColors.Home.gradient)
            
            // Content Section
            Group {
                switch selectedTab {
                case 0:
                    // Dashboard Tab
                    ScrollView {
                        LazyVStack(spacing: DashboardDesignSystem.Spacing.lg) {
                // Refresh indicator and timestamp - Removed
                
                // Personalized Greeting Card
                personalizedGreetingCard
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(DashboardDesignSystem.Animation.smooth.delay(0.1), value: cardsAppeared)
                
                // Key Metrics Section
                keyMetricsSection
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(DashboardDesignSystem.Animation.smooth.delay(0.2), value: cardsAppeared)
                
                // Smart Suggestions Section
                smartSuggestionsSection
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(DashboardDesignSystem.Animation.smooth.delay(0.3), value: cardsAppeared)
                
                
                // Enhanced Activity Feed Section
                enhancedActivitySection
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(DashboardDesignSystem.Animation.smooth.delay(0.4), value: cardsAppeared)
                
                // Smart Insights Section - Temporarily hidden
                // smartInsightsSection
                //     .opacity(cardsAppeared ? 1 : 0)
                //     .offset(y: cardsAppeared ? 0 : 20)
                //     .animation(DashboardDesignSystem.Animation.smooth.delay(0.5), value: cardsAppeared)
            }
                        .padding(.horizontal, DashboardDesignSystem.Spacing.lg)
                        .padding(.vertical, DashboardDesignSystem.Spacing.md)
                    }
                    .background(DashboardDesignSystem.Colors.neutralGray)
                    .refreshable {
                        await refreshDashboard()
                    }
                    .id(animationTrigger)
                    
                case 1:
                    // Activity Tab
                    SimplifiedHomeActivityView(activityService: activityService)
                        .id(animationTrigger)
                        
                default:
                    // Default to Dashboard
                    ScrollView {
                        LazyVStack(spacing: DashboardDesignSystem.Spacing.lg) {
                            personalizedGreetingCard
                        }
                        .padding(.horizontal, DashboardDesignSystem.Spacing.lg)
                        .padding(.vertical, DashboardDesignSystem.Spacing.md)
                    }
                    .background(DashboardDesignSystem.Colors.neutralGray)
                    .id(animationTrigger)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .task {
            dashboardService.setServices(taskService: taskService, activityService: activityService)
            dashboardService.setBudgetViewModel(budgetViewModel)
            await dashboardService.loadDashboardData()
            
            // Trigger staggered animations
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            cardsAppeared = true
            
            // Trigger metrics animations after cards appear
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            metricsAnimated = true
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            animationTrigger = UUID()
        }
        .overlay {
            if dashboardService.isLoading && dashboardService.dashboardMetrics.lastUpdated.timeIntervalSince1970 == 0 {
                loadingView
            }
        }
        .alert("Error", isPresented: Binding(
            get: { dashboardService.errorMessage != nil },
            set: { if !$0 { dashboardService.errorMessage = nil } }
        )) {
            Button("Retry") {
                Task {
                    await refreshDashboard()
                }
            }
            Button("OK", role: .cancel) {
                dashboardService.errorMessage = nil
            }
        } message: {
            Text(dashboardService.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Personalized Greeting Card
    private var personalizedGreetingCard: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.xs) {
                    Text("Welcome back")
                        .font(DashboardDesignSystem.Typography.cardTitle)
                        .foregroundColor(.primary)
                    
                    Text(authService.currentUser?.fullName ?? "User")
                        .font(DashboardDesignSystem.Typography.sectionHeader)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Weather or time indicator
                VStack {
                    Image(systemName: timeBasedIcon)
                        .font(.title2)
                        .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
                    
                    Text(currentTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(DashboardDesignSystem.Spacing.lg)
        .glassmorphismCard()
    }
    
    // MARK: - Key Metrics Section
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            Text("Today's Overview")
                .font(DashboardDesignSystem.Typography.sectionHeader)
                .foregroundColor(.primary)
            
            HStack(spacing: DashboardDesignSystem.Spacing.md) {
                // Productivity Card
                productivityMetricCard
                
                // Financial Health Card
                financialHealthCard
            }
            
            // Weekly Progress Card (full width) - Temporarily hidden
            // weeklyProgressCard
        }
    }
    
    private var productivityMetricCard: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
                    .font(.title3)
                
                Text("Tasks")
                    .font(DashboardDesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if dashboardService.isLoading {
                // Loading state with shimmer effect
                VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.xs) {
                    LoadingPlaceholder(height: 28, width: 60)
                    LoadingPlaceholder(height: 16, width: 120)
                }
                
                LoadingPlaceholder(height: 4, cornerRadius: 2)
                    .padding(.top, DashboardDesignSystem.Spacing.xs)
            } else {
                VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.xs) {
                    Text("\(dashboardService.dashboardMetrics.productivity.completedToday)")
                        .font(DashboardDesignSystem.Typography.sectionHeader)
                        .foregroundColor(.primary)
                        .scaleEffect(metricsAnimated ? 1.0 : 0.8)
                        .animation(DashboardDesignSystem.Animation.spring.delay(0.1), value: metricsAnimated)
                    
                    Text("of \(dashboardService.dashboardMetrics.productivity.totalTasksToday) today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar with animation
                ProgressView(value: metricsAnimated ? dashboardService.dashboardMetrics.productivity.dailyCompletionRate : 0, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: DashboardDesignSystem.Colors.primaryBlue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .animation(DashboardDesignSystem.Animation.smooth.delay(0.3), value: metricsAnimated)
            }
        }
        .padding(DashboardDesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(DashboardDesignSystem.CornerRadius.medium)
        .dashboardCardShadow()
    }
    
    private var financialHealthCard: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(DashboardDesignSystem.Colors.successGreen)
                    .font(.title3)
                
                Text("Budget")
                    .font(DashboardDesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if dashboardService.isLoading {
                // Loading state with shimmer effect
                VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.xs) {
                    LoadingPlaceholder(height: 28, width: 70)
                    LoadingPlaceholder(height: 16, width: 80)
                }
                
                HStack {
                    LoadingPlaceholder(height: 8, width: 8, cornerRadius: 4)
                    Spacer()
                }
                .padding(.top, DashboardDesignSystem.Spacing.xs)
            } else {
                VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.xs) {
                    Text(String(format: "%.0f%%", metricsAnimated ? dashboardService.dashboardMetrics.financial.budgetAdherenceScore : 0.0))
                        .font(DashboardDesignSystem.Typography.sectionHeader)
                        .foregroundColor(.primary)
                        .scaleEffect(metricsAnimated ? 1.0 : 0.8)
                        .animation(DashboardDesignSystem.Animation.spring.delay(0.2), value: metricsAnimated)
                    
                    Text("adherence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Health indicator with pulse animation
                Circle()
                    .fill(budgetHealthColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(metricsAnimated ? 1.0 : 0.5)
                    .animation(DashboardDesignSystem.Animation.spring.delay(0.4), value: metricsAnimated)
                    .overlay {
                        Circle()
                            .stroke(budgetHealthColor.opacity(0.3), lineWidth: 4)
                            .scaleEffect(metricsAnimated ? 1.5 : 1.0)
                            .animation(DashboardDesignSystem.Animation.smooth.delay(0.5), value: metricsAnimated)
                    }
            }
        }
        .padding(DashboardDesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(DashboardDesignSystem.CornerRadius.medium)
        .dashboardCardShadow()
    }
    
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Weekly Progress")
                        .font(DashboardDesignSystem.Typography.cardTitle)
                        .foregroundColor(.primary)
                    
                    if dashboardService.isLoading {
                        LoadingPlaceholder(height: 16, width: 140)
                    } else {
                        Text(String(format: "%.1f productivity score", dashboardService.dashboardMetrics.productivity.weeklyProductivityScore))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Trend indicator
                if dashboardService.isLoading {
                    LoadingPlaceholder(height: 16, width: 50)
                } else {
                    HStack(spacing: DashboardDesignSystem.Spacing.xs) {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(DashboardDesignSystem.Colors.successGreen)
                            .font(.caption)
                        
                        Text("+12%")
                            .font(.caption)
                            .foregroundColor(DashboardDesignSystem.Colors.successGreen)
                    }
                }
            }
            
            // Chart placeholder for Phase 3 (Swift Charts integrated)
            if dashboardService.isLoading {
                LoadingPlaceholder(height: 60, cornerRadius: DashboardDesignSystem.CornerRadius.small)
            } else if dashboardService.dashboardMetrics.chartData.hasChartsIntegration {
                RoundedRectangle(cornerRadius: DashboardDesignSystem.CornerRadius.small)
                    .fill(DashboardDesignSystem.Colors.primaryBlue.opacity(0.1))
                    .frame(height: 60)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title3)
                                .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
                            Text("Swift Charts Ready")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: DashboardDesignSystem.CornerRadius.small)
                    .fill(Color(.systemFill))
                    .frame(height: 60)
                    .overlay {
                        Text("Chart unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
            }
        }
        .padding(DashboardDesignSystem.Spacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(DashboardDesignSystem.CornerRadius.medium)
        .dashboardCardShadow()
    }
    
    
    
    // MARK: - Enhanced Activity Feed Section
    private var enhancedActivitySection: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            HStack {
                Text("Activity Feed")
                    .font(DashboardDesignSystem.Typography.sectionHeader)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full activity view with EnhancedActivityFeed
                }
                .font(.caption)
                .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
            }
            
            // Use EnhancedActivityFeed with compact mode for dashboard
            EnhancedActivityFeed(
                taskService: taskService,
                budgetViewModel: budgetViewModel,
                activityService: activityService,
                isCompactMode: true
            )
            .frame(maxHeight: 300) // Limit height for dashboard display
        }
    }
    
    private func recentActivityRow(activity: DashboardActivity) -> some View {
        HStack(spacing: DashboardDesignSystem.Spacing.md) {
            Image(systemName: activity.icon)
                .foregroundColor(activity.color)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.xs) {
                Text(activity.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = activity.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(DashboardDesignSystem.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(DashboardDesignSystem.CornerRadius.small)
        .dashboardCardShadow()
    }
    
    // MARK: - Smart Insights Section
    private var smartInsightsSection: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            Text("Smart Insights")
                .font(DashboardDesignSystem.Typography.sectionHeader)
                .foregroundColor(.primary)
            
            // Display insights directly
            ForEach(Array(dashboardService.dashboardMetrics.correlationInsights.insights.enumerated()), id: \.offset) { index, insight in
                insightRow(insight: insight, index: index)
            }
        }
    }
    
    private func insightRow(insight: String, index: Int) -> some View {
        HStack(spacing: DashboardDesignSystem.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            
            Text(insight)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(DashboardDesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.05), Color.orange.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(DashboardDesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DashboardDesignSystem.CornerRadius.medium)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: DashboardDesignSystem.Spacing.lg) {
            // Custom animated loading indicator
            ZStack {
                Circle()
                    .stroke(DashboardDesignSystem.Colors.primaryBlue.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(DashboardDesignSystem.Colors.primaryBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(dashboardService.isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: dashboardService.isLoading)
            }
            
            VStack(spacing: DashboardDesignSystem.Spacing.sm) {
                Text("Loading dashboard...")
                    .font(DashboardDesignSystem.Typography.cardTitle)
                    .foregroundColor(.primary)
                
                Text("Getting your latest data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(.systemGroupedBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .transition(.opacity.combined(with: .scale))
        .zIndex(1)
    }
    
    // MARK: - Helper Methods
    private func refreshDashboard() async {
        refreshing = true
        
        // Reset animation states for refresh
        cardsAppeared = false
        metricsAnimated = false
        
        dashboardService.setServices(taskService: taskService, activityService: activityService)
        dashboardService.setBudgetViewModel(budgetViewModel)
        await dashboardService.loadDashboardData()
        
        // Re-trigger animations after refresh
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        cardsAppeared = true
        
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        metricsAnimated = true
        
        refreshing = false
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<22:
            return "Good evening,"
        default:
            return "Hello,"
        }
    }
    
    private var timeBasedIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.max.fill"
        case 12..<17:
            return "sun.max"
        case 17..<20:
            return "sunset.fill"
        default:
            return "moon.stars.fill"
        }
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private var budgetHealthColor: Color {
        let score = dashboardService.dashboardMetrics.financial.budgetAdherenceScore
        if score >= 80 {
            return DashboardDesignSystem.Colors.successGreen
        } else if score >= 60 {
            return DashboardDesignSystem.Colors.warningOrange
        } else {
            return DashboardDesignSystem.Colors.errorRed
        }
    }
    
    // MARK: - Refresh Header View
    private var refreshHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Last updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if dashboardService.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                
                Text(refreshTimestamp)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Manual refresh button
            Button(action: {
                Task {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    await refreshDashboard()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
                    .rotationEffect(.degrees(refreshing ? 360 : 0))
                    .animation(refreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: refreshing)
            }
        }
        .padding(.horizontal, DashboardDesignSystem.Spacing.md)
        .padding(.vertical, DashboardDesignSystem.Spacing.xs)
        .background(Color(.systemGroupedBackground))
    }
    
    private var refreshTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: dashboardService.lastRefreshTime ?? Date())
    }
    
    // MARK: - Smart Suggestions Section
    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            Text("Smart Suggestions")
                .font(DashboardDesignSystem.Typography.sectionHeader)
                .foregroundColor(.primary)
            
            SmartSuggestionsCard(suggestions: dashboardService.dashboardMetrics.chartData.smartSuggestions)
        }
    }
    
}

// MARK: - Activity Views

struct SimplifiedHomeActivityView: View {
    @ObservedObject var activityService: LocalActivityService
    @State private var showingClearAllConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !activityService.activities.isEmpty {
                        Button("Clear All") {
                            showingClearAllConfirmation = true
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(activityService.activities) { activity in
                        ActivityItemRowView(activity: activity)
                    }
                    
                    if activityService.activities.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: "No Activity Yet",
                            subtitle: "Your activities will appear here!",
                            actionTitle: nil,
                            action: nil
                        )
                        .padding()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .confirmationDialog("Clear All Activities", isPresented: $showingClearAllConfirmation, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) {
                activityService.clearAllActivities()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all activity history. This action cannot be undone.")
        }
    }
}

struct ActivityItemRowView: View {
    let activity: LocalActivity
    
    private var activityColor: Color {
        switch activity.color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(activityColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.module ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(activity.action ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.title ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = activity.activityDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(activity.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding(40)
    }
}