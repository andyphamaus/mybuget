import SwiftUI

struct EnhancedActivityFeed: View {
    @ObservedObject var taskService: LocalTaskService
    @ObservedObject var budgetViewModel: BudgetViewModel
    @ObservedObject var activityService: LocalActivityService
    let isCompactMode: Bool
    
    @State private var selectedFilter: ActivityFilter = .all
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedActivity: UnifiedActivity?
    @State private var activityClusters: [ActivityCluster] = []
    
    private var filteredActivities: [UnifiedActivity] {
        let unified = unifiedActivities
        
        var filtered = unified
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.title.localizedCaseInsensitiveContains(searchText) ||
                activity.description.localizedCaseInsensitiveContains(searchText) ||
                activity.module.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .tasks:
            filtered = filtered.filter { $0.type == .task }
        case .budget:
            filtered = filtered.filter { $0.type == .budget }
        case .achievements:
            filtered = filtered.filter { $0.type == .achievement }
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .thisWeek:
            filtered = filtered.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }
        }
        
        let limit = isCompactMode ? 5 : 50
        return Array(filtered.prefix(limit)) // Limit for performance and compact mode
    }
    
    private var unifiedActivities: [UnifiedActivity] {
        var activities: [UnifiedActivity] = []
        
        // Convert LocalActivity to UnifiedActivity
        for activity in activityService.activities {
            activities.append(UnifiedActivity(from: activity))
        }
        
        // Add real budget activities from budget service
        activities.append(contentsOf: generateBudgetActivities())
        
        // Add achievement activities - DISABLED (fake data)
        // activities.append(contentsOf: generateAchievementActivities())
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !isCompactMode {
                searchAndFilterHeader
            }
            
            if filteredActivities.isEmpty {
                emptyStateView
            } else {
                activityContent
            }
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailSheet(activity: activity)
        }
        .sheet(isPresented: $showingFilters) {
            ActivityFiltersSheet(
                selectedFilter: $selectedFilter,
                onApply: { filter in
                    selectedFilter = filter
                    showingFilters = false
                }
            )
        }
        .onAppear {
            analyzeActivityClusters()
            generateActivityRecommendations()
        }
    }
    
    private var searchAndFilterHeader: some View {
        VStack(spacing: DashboardDesignSystem.Spacing.sm) {
            HStack(spacing: DashboardDesignSystem.Spacing.md) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.body)
                    
                    TextField("Search activities...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemFill))
                .cornerRadius(10)
                
                // Filter button
                Button(action: { showingFilters = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.body)
                        
                        if selectedFilter != .all {
                            Text(selectedFilter.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(selectedFilter == .all ? .secondary : DashboardDesignSystem.Colors.primaryBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        selectedFilter == .all ? 
                        Color(.systemFill) : 
                        DashboardDesignSystem.Colors.primaryBlue.opacity(0.15)
                    )
                    .cornerRadius(10)
                }
            }
            
            // Activity insights bar
            activityInsightsBar
        }
        .padding(.horizontal, DashboardDesignSystem.Spacing.md)
        .padding(.vertical, DashboardDesignSystem.Spacing.sm)
    }
    
    private var activityInsightsBar: some View {
        HStack(spacing: 16) {
            insightItem(
                icon: "clock.arrow.circlepath",
                label: "\(filteredActivities.count)",
                sublabel: "activities"
            )
            
            insightItem(
                icon: "calendar",
                label: "\(todayActivitiesCount)",
                sublabel: "today"
            )
            
            insightItem(
                icon: "chart.line.uptrend.xyaxis",
                label: streakCount,
                sublabel: "day streak"
            )
            
            Spacer()
            
            // Export button
            Button(action: exportActivities) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    DashboardDesignSystem.Colors.primaryBlue.opacity(0.05),
                    DashboardDesignSystem.Colors.successGreen.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(8)
    }
    
    private func insightItem(icon: String, label: String, sublabel: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(sublabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var activityContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Activity clusters section
                if !activityClusters.isEmpty {
                    clusteredActivitiesSection
                        .padding(.bottom, DashboardDesignSystem.Spacing.md)
                }
                
                // Individual activities
                ForEach(Array(filteredActivities.enumerated()), id: \.element.id) { index, activity in
                    ActivityItemView(activity: activity) {
                        selectedActivity = activity
                    }
                    .id(activity.id)
                    
                    if index < filteredActivities.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, DashboardDesignSystem.Spacing.sm)
        }
    }
    
    private var clusteredActivitiesSection: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.sm) {
            HStack {
                Text("Activity Patterns")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(activityClusters.count) patterns found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DashboardDesignSystem.Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DashboardDesignSystem.Spacing.sm) {
                    ForEach(activityClusters, id: \.id) { cluster in
                        ActivityClusterCard(cluster: cluster)
                    }
                }
                .padding(.horizontal, DashboardDesignSystem.Spacing.md)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Activities Found")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if searchText.isEmpty {
                    Text("Your activities will appear here as you use the app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Try adjusting your search or filters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var todayActivitiesCount: Int {
        filteredActivities.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }
    
    private var streakCount: String {
        let streak = calculateActivityStreak()
        return "\(streak)"
    }
    
    private func calculateActivityStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Check each day going backwards
        while streak < 30 { // Max 30 days
            let dayActivities = unifiedActivities.filter { activity in
                calendar.isDate(activity.timestamp, inSameDayAs: currentDate)
            }
            
            if dayActivities.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func generateBudgetActivities() -> [UnifiedActivity] {
        var activities: [UnifiedActivity] = []
        
        // Get recent transactions from budget service
        let recentTransactions = budgetViewModel.transactions
            .filter { transaction in
                // Only include transactions from the last 7 days
                guard let date = transaction.createdAt else { return false }
                return Calendar.current.dateInterval(of: .day, for: Date())?.contains(date) ?? false ||
                       Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains(date) ?? false
            }
            .sorted(by: { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) })
            .prefix(10)
        
        // Convert transactions to UnifiedActivity
        for transaction in recentTransactions {
            let categoryName = transaction.category?.name ?? "Uncategorized"
            let amountValue = Double(transaction.amountCents) / 100.0 // Convert cents to dollars
            let isIncome = amountValue > 0
            let actionTitle = isIncome ? "Income Added" : "Expense Added"
            let amountText = String(format: isIncome ? "+$%.2f" : "-$%.2f", abs(amountValue))
            let icon = isIncome ? "arrow.up.circle.fill" : (transaction.category?.icon ?? "creditcard.fill")
            let color = isIncome ? DashboardDesignSystem.Colors.successGreen : DashboardDesignSystem.Colors.warningOrange
            
            activities.append(UnifiedActivity(
                id: transaction.id ?? UUID().uuidString,
                type: .budget,
                module: "Budget",
                action: actionTitle,
                title: (transaction.notes?.isEmpty == false) ? (transaction.notes ?? categoryName) : categoryName,
                description: "\(actionTitle) \(amountText) to \(categoryName)",
                timestamp: transaction.createdAt ?? Date(),
                icon: icon,
                color: color,
                metadata: [
                    "amount": amountText,
                    "category": categoryName,
                    "transactionType": isIncome ? "income" : "expense"
                ]
            ))
        }
        
        // If no real transactions, add a few sample activities so the feed isn't empty
        if activities.isEmpty {
            let sampleDate = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            activities.append(UnifiedActivity(
                id: UUID().uuidString,
                type: .budget,
                module: "Budget",
                action: "Budget Created",
                title: "Budget Setup Complete",
                description: "Your budget tracking is now active and ready to use",
                timestamp: sampleDate,
                icon: "dollarsign.circle",
                color: DashboardDesignSystem.Colors.successGreen,
                metadata: ["status": "active"]
            ))
        }
        
        return activities
    }
    
    private func generateAchievementActivities() -> [UnifiedActivity] {
        let achievements = [
            UnifiedActivity(
                id: UUID().uuidString,
                type: .achievement,
                module: "Achievements",
                action: "Achievement Unlocked",
                title: "Task Master",
                description: "Completed 10 tasks in one day!",
                timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
                icon: "star.circle.fill",
                color: Color.purple,
                metadata: ["achievement": "task_master", "count": "10"]
            ),
            UnifiedActivity(
                id: UUID().uuidString,
                type: .achievement,
                module: "Achievements", 
                action: "Streak Achievement",
                title: "Budget Streak",
                description: "7 days of staying within budget!",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                icon: "flame.fill",
                color: Color.orange,
                metadata: ["streak": "7", "type": "budget"]
            )
        ]
        
        return achievements
    }
    
    private func analyzeActivityClusters() {
        let calendar = Calendar.current
        var clusters: [ActivityCluster] = []
        
        // Group activities by hour of day
        let hourlyGroups = Dictionary(grouping: unifiedActivities) { activity in
            calendar.component(.hour, from: activity.timestamp)
        }
        
        for (hour, activities) in hourlyGroups {
            if activities.count >= 3 {
                let cluster = ActivityCluster(
                    id: UUID(),
                    title: "\(formatHour(hour)) Pattern",
                    description: "\(activities.count) activities typically occur around \(formatHour(hour))",
                    activities: activities,
                    pattern: .timeOfDay(hour),
                    strength: min(Double(activities.count) / 10.0, 1.0)
                )
                clusters.append(cluster)
            }
        }
        
        // Group by activity type
        let typeGroups = Dictionary(grouping: unifiedActivities) { $0.type }
        for (type, activities) in typeGroups {
            if activities.count >= 5 {
                let cluster = ActivityCluster(
                    id: UUID(),
                    title: "\(type.displayName) Focus",
                    description: "\(activities.count) \(type.displayName.lowercased()) activities",
                    activities: activities,
                    pattern: .activityType(type),
                    strength: min(Double(activities.count) / 15.0, 1.0)
                )
                clusters.append(cluster)
            }
        }
        
        activityClusters = clusters.sorted { $0.strength > $1.strength }
    }
    
    private func generateActivityRecommendations() {
        let calendar = Calendar.current
        var recommendations: [ActivityRecommendation] = []
        
        // Analyze task completion patterns
        let taskActivities = unifiedActivities.filter { $0.type == .task }
        let completedTasks = taskActivities.filter { $0.action == "Task Completed" }
        let todayCompleted = completedTasks.filter { calendar.isDateInToday($0.timestamp) }
        
        if todayCompleted.count < 3 && !taskActivities.isEmpty {
            recommendations.append(ActivityRecommendation(
                title: "Complete More Tasks",
                description: "You've completed \(todayCompleted.count) tasks today. Try to complete at least 3 tasks daily for better productivity.",
                priority: .high,
                actionType: .taskManagement,
                estimatedImpact: "20% productivity boost"
            ))
        }
        
        // Analyze spending patterns
        let budgetActivities = unifiedActivities.filter { $0.type == .budget }
        let recentExpenses = budgetActivities.filter { 
            $0.action == "Expense Added" && 
            calendar.dateInterval(of: .day, for: Date())?.contains($0.timestamp) ?? false
        }
        
        if recentExpenses.count > 5 {
            recommendations.append(ActivityRecommendation(
                title: "Review Daily Spending",
                description: "You've logged \(recentExpenses.count) expenses today. Consider reviewing your spending patterns.",
                priority: .medium,
                actionType: .budgetReview,
                estimatedImpact: "Better budget control"
            ))
        }
        
        // Analyze time-based patterns from clusters
        for cluster in activityClusters {
            if case .timeOfDay(let hour) = cluster.pattern, cluster.strength > 0.7 {
                let timeDescription = formatHour(hour)
                recommendations.append(ActivityRecommendation(
                    title: "Optimize \(timeDescription) Routine",
                    description: "You're very active around \(timeDescription). Consider scheduling important tasks during this time.",
                    priority: .low,
                    actionType: .timeOptimization,
                    estimatedImpact: "Improved focus"
                ))
            }
        }
        
        // Store recommendations for potential future use (could be displayed in UI)
        for rec in recommendations {
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
    
    private func exportActivities() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Create CSV content
        let csvHeader = "Date,Time,Module,Action,Title,Description,Amount,Category\n"
        let csvRows = filteredActivities.map { activity in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let date = dateFormatter.string(from: activity.timestamp)
            
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let time = timeFormatter.string(from: activity.timestamp)
            
            let amount = activity.metadata["amount"] ?? ""
            let category = activity.metadata["category"] ?? ""
            
            return "\"\(date)\",\"\(time)\",\"\(activity.module)\",\"\(activity.action)\",\"\(activity.title)\",\"\(activity.description)\",\"\(amount)\",\"\(category)\""
        }
        
        let csvContent = csvHeader + csvRows.joined(separator: "\n")
        
        // Create share sheet with CSV data
        let fileName = "LifeLaunch_Activities_\(Date().formatted(.iso8601.year().month().day())).csv"
        
        if let data = csvContent.data(using: .utf8) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: tempURL)
                
                // Present share sheet
                let activityController = UIActivityViewController(
                    activityItems: [tempURL],
                    applicationActivities: nil
                )
                
                // Get the root view controller and present
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    
                    // For iPad compatibility
                    if let popover = activityController.popoverPresentationController {
                        popover.sourceView = rootViewController.view
                        popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    rootViewController.present(activityController, animated: true)
                }
                
                
            } catch {
            }
        }
    }
}

// MARK: - Supporting Views
struct ActivityItemView: View {
    let activity: UnifiedActivity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity icon
                Image(systemName: activity.icon)
                    .font(.title3)
                    .foregroundColor(activity.color)
                    .frame(width: 32, height: 32)
                    .background(activity.color.opacity(0.15))
                    .cornerRadius(8)
                
                // Activity content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(activity.module)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(activity.action)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(activity.relativeTimeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(activity.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !activity.description.isEmpty {
                        Text(activity.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Type indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(activity.color)
                    .frame(width: 4, height: 40)
            }
            .padding(.horizontal, DashboardDesignSystem.Spacing.md)
            .padding(.vertical, DashboardDesignSystem.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityClusterCard: View {
    let cluster: ActivityCluster
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cluster.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Circle()
                    .fill(strengthColor)
                    .frame(width: 8, height: 8)
            }
            
            Text(cluster.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Strength indicator
            ProgressView(value: cluster.strength)
                .progressViewStyle(LinearProgressViewStyle(tint: strengthColor))
                .scaleEffect(x: 1, y: 0.5)
        }
        .padding(12)
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .dashboardCardShadow()
    }
    
    private var strengthColor: Color {
        if cluster.strength > 0.7 {
            return .green
        } else if cluster.strength > 0.4 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Data Models
struct UnifiedActivity: Identifiable {
    let id: String
    let type: ActivityType
    let module: String
    let action: String
    let title: String
    let description: String
    let timestamp: Date
    let icon: String
    let color: Color
    let metadata: [String: String]
    
    enum ActivityType: CaseIterable {
        case task
        case budget
        case achievement
        case system
        
        var displayName: String {
            switch self {
            case .task: return "Tasks"
            case .budget: return "Budget"
            case .achievement: return "Achievements" 
            case .system: return "System"
            }
        }
    }
    
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    init(from localActivity: LocalActivity) {
        self.id = localActivity.id?.uuidString ?? UUID().uuidString
        self.type = .task // LocalActivity is primarily task-related
        self.module = localActivity.module ?? "Tasks"
        self.action = localActivity.action ?? "Activity"
        self.title = localActivity.title ?? "Untitled"
        self.description = localActivity.activityDescription ?? ""
        self.timestamp = localActivity.timestamp ?? Date()
        self.icon = "circle" // LocalActivity doesn't have icon property
        self.color = .blue // LocalActivity doesn't have color property
        self.metadata = [:]
    }
    
    init(id: String, type: ActivityType, module: String, action: String, title: String, 
         description: String, timestamp: Date, icon: String, color: Color, metadata: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.module = module
        self.action = action
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.icon = icon
        self.color = color
        self.metadata = metadata
    }
}

struct ActivityCluster: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let activities: [UnifiedActivity]
    let pattern: ClusterPattern
    let strength: Double // 0.0 to 1.0
    
    enum ClusterPattern {
        case timeOfDay(Int)
        case activityType(UnifiedActivity.ActivityType)
        case frequency
        case sequential
    }
}

enum ActivityFilter: String, CaseIterable {
    case all = "all"
    case tasks = "tasks"
    case budget = "budget"
    case achievements = "achievements"
    case today = "today"
    case thisWeek = "this week"
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Activity Recommendation Model
struct ActivityRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: RecommendationPriority
    let actionType: RecommendationActionType
    let estimatedImpact: String
}

enum RecommendationPriority {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum RecommendationActionType {
    case taskManagement
    case budgetReview
    case timeOptimization
    
    var icon: String {
        switch self {
        case .taskManagement: return "checklist"
        case .budgetReview: return "dollarsign.circle"
        case .timeOptimization: return "clock"
        }
    }
}

// MARK: - Detail Sheet
struct ActivityDetailSheet: View {
    let activity: UnifiedActivity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: activity.icon)
                            .font(.title)
                            .foregroundColor(activity.color)
                            .frame(width: 44, height: 44)
                            .background(activity.color.opacity(0.15))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(activity.module) • \(activity.action)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Description
                    if !activity.description.isEmpty {
                        Text(activity.description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Metadata
                    if !activity.metadata.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(activity.metadata.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(activity.metadata[key] ?? "")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemFill))
                        .cornerRadius(12)
                    }
                    
                    // Timestamp
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timestamp")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(activity.timestamp, style: .date)
                            .font(.subheadline)
                        
                        Text(activity.timestamp, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemFill))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Filters Sheet
struct ActivityFiltersSheet: View {
    @Binding var selectedFilter: ActivityFilter
    let onApply: (ActivityFilter) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Filter by Type") {
                    ForEach(ActivityFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            HStack {
                                Text(filter.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DashboardDesignSystem.Colors.primaryBlue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Activities")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Apply") { 
                    onApply(selectedFilter)
                }
            )
        }
    }
}

#Preview {
    EnhancedActivityFeed(
        taskService: LocalTaskService(),
        budgetViewModel: BudgetViewModel(),
        activityService: LocalActivityService(),
        isCompactMode: false
    )
    .padding()
}