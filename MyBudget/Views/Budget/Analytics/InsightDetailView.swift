import SwiftUI
import Charts

struct InsightDetailView: View {
    let insight: SmartInsight
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    let analytics: SmartAnalyticsService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeframe: TimeframeFilter = .month
    @State private var showingRelatedTransactions = false
    
    private var relatedTransactions: [LocalTransaction] {
        guard let categoryId = insight.relatedCategoryId else { return [] }
        return transactions.filter { $0.category?.id == categoryId }
    }
    
    private var relatedCategory: LocalCategory? {
        guard let categoryId = insight.relatedCategoryId else { return nil }
        return categories.first { $0.id == categoryId }
    }
    
    private var spendingPattern: SpendingPattern? {
        guard let categoryId = insight.relatedCategoryId else { return nil }
        return analytics.getPattern(for: categoryId)
    }
    
    private var forecast: BudgetForecast? {
        guard let categoryId = insight.relatedCategoryId else { return nil }
        return analytics.getForecast(for: categoryId)
    }
    
    enum TimeframeFilter: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with insight summary
                    InsightHeaderCard(insight: insight, category: relatedCategory)
                        .padding(.horizontal)
                    
                    // Interactive timeframe selector
                    if !relatedTransactions.isEmpty {
                        TimeframeSelector(selectedTimeframe: $selectedTimeframe)
                            .padding(.horizontal)
                    }
                    
                    // Detailed analysis based on insight type
                    switch insight.type {
                    case .anomaly:
                        AnomalyDetailSection(
                            transactions: filteredTransactions,
                            category: relatedCategory,
                            pattern: spendingPattern
                        )
                        .padding(.horizontal)
                        
                    case .forecast:
                        ForecastDetailSection(
                            forecast: forecast,
                            pattern: spendingPattern,
                            transactions: filteredTransactions
                        )
                        .padding(.horizontal)
                        
                    case .budgetAlert:
                        BudgetAlertDetailSection(
                            transactions: filteredTransactions,
                            category: relatedCategory
                        )
                        .padding(.horizontal)
                        
                    case .spendingPattern:
                        PatternDetailSection(
                            pattern: spendingPattern,
                            transactions: filteredTransactions,
                            timeframe: selectedTimeframe
                        )
                        .padding(.horizontal)
                        
                    case .healthScore, .recommendation:
                        RecommendationDetailSection(
                            insight: insight,
                            transactions: filteredTransactions
                        )
                        .padding(.horizontal)
                    }
                    
                    // Related transactions list
                    if !relatedTransactions.isEmpty {
                        RelatedTransactionsSection(
                            transactions: filteredTransactions,
                            category: relatedCategory,
                            showingAll: $showingRelatedTransactions
                        )
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    ActionButtonsSection(
                        insight: insight,
                        onDismiss: { dismiss() }
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredTransactions: [LocalTransaction] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return relatedTransactions.filter { transaction in
            guard let dateString = transaction.transactionDate,
                  let transactionDate = ISO8601DateFormatter().date(from: dateString) else { return false }
            return transactionDate >= startDate
        }
    }
}

struct InsightHeaderCard: View {
    let insight: SmartInsight
    let category: LocalCategory?
    
    private var priorityColor: Color {
        switch insight.priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: iconForInsightType(insight.type))
                            .font(.title2)
                            .foregroundColor(priorityColor)
                        
                        Text(insight.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    if let category = category {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(category.name ?? "Unknown")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(priorityLabel(insight.priority))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(priorityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.15))
                        .cornerRadius(8)
                    
                    Text(insight.createdDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func iconForInsightType(_ type: InsightType) -> String {
        switch type {
        case .budgetAlert: return "exclamationmark.triangle.fill"
        case .spendingPattern: return "chart.line.uptrend.xyaxis"
        case .anomaly: return "eye.trianglebadge.exclamationmark"
        case .recommendation: return "star.circle"
        case .forecast: return "crystal.ball"
        case .healthScore: return "heart.fill"
        }
    }
    
    private func priorityLabel(_ priority: InsightPriority) -> String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

struct TimeframeSelector: View {
    @Binding var selectedTimeframe: InsightDetailView.TimeframeFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InsightDetailView.TimeframeFilter.allCases, id: \.rawValue) { timeframe in
                    Button(action: {
                        selectedTimeframe = timeframe
                    }) {
                        Text(timeframe.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeframe == timeframe ? Color.blue : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedTimeframe == timeframe ? .white : .primary
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct AnomalyDetailSection: View {
    let transactions: [LocalTransaction]
    let category: LocalCategory?
    let pattern: SpendingPattern?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anomaly Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let pattern = pattern {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Normal Range")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(Int(pattern.averageAmount * 0.7)) - $\(Int(pattern.averageAmount * 1.3))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Confidence Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(pattern.confidenceScore * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Transaction Count")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(pattern.frequency) transactions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Show recent unusual transactions
            if !transactions.isEmpty {
                Text("Recent Transactions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(transactions.prefix(3), id: \.id) { transaction in
                    InsightTransactionRowView(transaction: transaction)
                }
            }
        }
    }
}

struct ForecastDetailSection: View {
    let forecast: BudgetForecast?
    let pattern: SpendingPattern?
    let transactions: [LocalTransaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Forecast")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let forecast = forecast {
                VStack(spacing: 16) {
                    // Prediction card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Next Month Prediction")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("$\(Int(forecast.forecastAmount))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Range")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(Int(forecast.confidenceInterval.lower)) - $\(Int(forecast.confidenceInterval.upper))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Historical comparison
                    if !transactions.isEmpty {
                        let recentAverage = transactions.suffix(5).reduce(0) { $0 + $1.amountInCurrency } / Double(min(5, transactions.count))
                        let change = forecast.forecastAmount - recentAverage
                        let changePercent = recentAverage > 0 ? (change / recentAverage) * 100 : 0
                        
                        HStack {
                            Text("vs Recent Average")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: changePercent >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                    .foregroundColor(changePercent >= 0 ? .red : .green)
                                
                                Text("\(abs(Int(changePercent)))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(changePercent >= 0 ? .red : .green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

struct BudgetAlertDetailSection: View {
    let transactions: [LocalTransaction]
    let category: LocalCategory?
    
    private var totalSpent: Double {
        transactions.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Alert Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Spending")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("$\(Int(totalSpent))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Transactions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(transactions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct PatternDetailSection: View {
    let pattern: SpendingPattern?
    let transactions: [LocalTransaction]
    let timeframe: InsightDetailView.TimeframeFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Pattern Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let pattern = pattern {
                // Day of week chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Pattern")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            BarMark(
                                x: .value("Day", dayName(dayIndex)),
                                y: .value("Spending %", pattern.dayOfWeekPattern[dayIndex] * 100)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .frame(height: 120)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let percent = value.as(Double.self) {
                                    Text("\(Int(percent))%")
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private func dayName(_ index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard index >= 0 && index < days.count else {
            return "Unknown"
        }
        return days[index]
    }
}

struct RecommendationDetailSection: View {
    let insight: SmartInsight
    let transactions: [LocalTransaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendation Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Based on your spending patterns and financial data, here are personalized recommendations to improve your financial health.")
                .font(.body)
                .foregroundColor(.secondary)
            
            // Add specific recommendation cards based on insight
            if insight.type == .healthScore {
                HealthRecommendationCards()
            }
        }
    }
}

struct HealthRecommendationCards: View {
    var body: some View {
        VStack(spacing: 12) {
            RecommendationCard(
                icon: "chart.pie.fill",
                title: "Budget Adherence",
                description: "Try to stick to your planned amounts for better financial control",
                color: .blue
            )
            
            RecommendationCard(
                icon: "arrow.triangle.2.circlepath",
                title: "Consistency",
                description: "Maintain regular spending patterns to improve predictability",
                color: .green
            )
            
            RecommendationCard(
                icon: "banknote.fill",
                title: "Savings Rate",
                description: "Consider increasing your savings by 5% each month",
                color: .orange
            )
        }
    }
}

struct RecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RelatedTransactionsSection: View {
    let transactions: [LocalTransaction]
    let category: LocalCategory?
    @Binding var showingAll: Bool
    
    private var displayedTransactions: [LocalTransaction] {
        showingAll ? transactions : Array(transactions.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Related Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if transactions.count > 5 {
                    Button(showingAll ? "Show Less" : "Show All (\(transactions.count))") {
                        withAnimation(.easeInOut) {
                            showingAll.toggle()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            ForEach(displayedTransactions, id: \.id) { transaction in
                InsightTransactionRowView(transaction: transaction)
            }
        }
    }
}

struct InsightTransactionRowView: View {
    let transaction: LocalTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text(transaction.category?.name ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if let dateString = transaction.transactionDate,
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("$\(Int(transaction.amountInCurrency))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.amountInCurrency < 0 ? .red : .green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ActionButtonsSection: View {
    let insight: SmartInsight
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if insight.actionable {
                Button(action: {
                    // Handle insight action
                    onDismiss()
                }) {
                    Text("Take Action")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            
            Button(action: {
                // Mark as resolved
                onDismiss()
            }) {
                Text("Mark as Resolved")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    InsightDetailView(
        insight: SmartInsight(
            id: UUID(),
            type: .budgetAlert,
            title: "Budget Alert",
            description: "You're on track to exceed your dining budget by $150 this month based on your current spending pattern.",
            priority: .high,
            actionable: true,
            relatedCategoryId: "category1",
            createdDate: Date(),
            isRead: false
        ),
        transactions: [],
        categories: [],
        analytics: SmartAnalyticsService()
    )
}