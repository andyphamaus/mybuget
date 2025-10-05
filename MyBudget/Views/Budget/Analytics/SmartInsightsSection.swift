import SwiftUI

struct SmartInsightsSection: View {
    let insights: [SmartInsight]
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    let analytics: SmartAnalyticsService
    let onMarkAsRead: (UUID) -> Void
    
    @State private var showAllInsights = false
    
    private var displayedInsights: [SmartInsight] {
        let sortedInsights = insights.sorted { insight1, insight2 in
            // Sort by priority first, then by read status, then by date
            if insight1.priority != insight2.priority {
                return insight1.priority.rawValue > insight2.priority.rawValue
            }
            
            if insight1.isRead != insight2.isRead {
                return !insight1.isRead && insight2.isRead
            }
            
            return insight1.createdDate > insight2.createdDate
        }
        
        return showAllInsights ? sortedInsights : Array(sortedInsights.prefix(3))
    }
    
    private var unreadCount: Int {
        insights.filter { !$0.isRead }.count
    }
    
    private var urgentCount: Int {
        insights.filter { $0.priority == .urgent && !$0.isRead }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Smart Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    
                    // Bulk actions menu
                    if unreadCount > 0 {
                        Menu {
                            Button {
                                // Mark all as read
                                insights.filter { !$0.isRead }.forEach { insight in
                                    onMarkAsRead(insight.id)
                                }
                            } label: {
                                Label("Mark All as Read", systemImage: "checkmark.circle")
                            }
                            
                            Button {
                                // Mark urgent as read
                                insights.filter { $0.priority == .urgent && !$0.isRead }.forEach { insight in
                                    onMarkAsRead(insight.id)
                                }
                            } label: {
                                Label("Mark Urgent as Read", systemImage: "exclamationmark.circle")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                // Dismiss all (mark as read for now)
                                insights.forEach { insight in
                                    onMarkAsRead(insight.id)
                                }
                            } label: {
                                Label("Dismiss All", systemImage: "xmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                // Clear all insights completely
                                analytics.clearInsights()
                                analytics.resetAnalysisState()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if insights.count > 3 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAllInsights.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(showAllInsights ? "Show Less" : "Show All")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Image(systemName: showAllInsights ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Insights List
            if displayedInsights.isEmpty {
                EmptyInsightsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(displayedInsights, id: \.id) { insight in
                        SmartInsightCardView(
                            insight: insight,
                            transactions: transactions,
                            categories: categories,
                            analytics: analytics,
                            onMarkAsRead: onMarkAsRead
                        )
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                    }
                }
            }
            
            // Quick Actions
            if !insights.isEmpty {
                HStack {
                    if unreadCount > 0 {
                        Button(action: {
                            insights.filter { !$0.isRead }.forEach { insight in
                                onMarkAsRead(insight.id)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                Text("Mark All as Read")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    
                    Button(action: {
                        analytics.clearInsights()
                        analytics.resetAnalysisState()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("Clear All")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: displayedInsights.count)
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.7))
            
            VStack(spacing: 4) {
                Text("Building Your Financial Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Add more transactions to unlock personalized insights and predictions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Extensions

extension InsightPriority {
    var rawValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SmartInsightsSection(
                insights: [
                    SmartInsight(
                        id: UUID(),
                        type: .budgetAlert,
                        title: "Budget Alert",
                        description: "You're on track to exceed your dining budget by $150 this month based on your current spending pattern.",
                        priority: .urgent,
                        actionable: true,
                        relatedCategoryId: nil,
                        createdDate: Date(),
                        isRead: false
                    ),
                    SmartInsight(
                        id: UUID(),
                        type: .forecast,
                        title: "Spending Forecast",
                        description: "Based on your pattern, you're likely to spend $320 on groceries next month.",
                        priority: .medium,
                        actionable: true,
                        relatedCategoryId: nil,
                        createdDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                        isRead: false
                    ),
                    SmartInsight(
                        id: UUID(),
                        type: .healthScore,
                        title: "Great Financial Health!",
                        description: "Your financial health score is 85/100. You're doing great with budget adherence!",
                        priority: .low,
                        actionable: false,
                        relatedCategoryId: nil,
                        createdDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        isRead: true
                    ),
                    SmartInsight(
                        id: UUID(),
                        type: .anomaly,
                        title: "Unusual Transaction",
                        description: "Detected an unusually large transaction of $500 in Entertainment category.",
                        priority: .high,
                        actionable: true,
                        relatedCategoryId: nil,
                        createdDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                        isRead: false
                    )
                ],
                transactions: [],
                categories: [],
                analytics: SmartAnalyticsService(),
                onMarkAsRead: { _ in }
            )
            
            SmartInsightsSection(
                insights: [],
                transactions: [],
                categories: [],
                analytics: SmartAnalyticsService(),
                onMarkAsRead: { _ in }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}