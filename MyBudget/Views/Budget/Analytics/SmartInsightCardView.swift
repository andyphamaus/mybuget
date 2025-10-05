import SwiftUI

struct SmartInsightCardView: View {
    let insight: SmartInsight
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    let analytics: SmartAnalyticsService
    let onMarkAsRead: (UUID) -> Void
    
    @State private var showingDetail = false
    
    private var priorityColor: Color {
        switch insight.priority {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .urgent:
            return .red
        }
    }
    
    private var priorityIcon: String {
        switch insight.priority {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .urgent:
            return "exclamationmark.octagon.fill"
        }
    }
    
    private var typeIcon: String {
        switch insight.type {
        case .budgetAlert:
            return "exclamationmark.triangle.fill"
        case .spendingPattern:
            return "chart.line.uptrend.xyaxis"
        case .anomaly:
            return "eye.trianglebadge.exclamationmark"
        case .recommendation:
            return "star.circle"
        case .forecast:
            return "crystal.ball"
        case .healthScore:
            return "heart.fill"
        }
    }
    
    private var quickActionTitle: String {
        switch insight.type {
        case .budgetAlert:
            return "View Budget"
        case .spendingPattern:
            return "Analyze"
        case .anomaly:
            return "Review"
        case .recommendation:
            return "Apply"
        case .forecast:
            return "Plan"
        case .healthScore:
            return "Improve"
        }
    }
    
    private var quickActionIcon: String {
        switch insight.type {
        case .budgetAlert:
            return "chart.pie"
        case .spendingPattern:
            return "chart.line.uptrend.xyaxis"
        case .anomaly:
            return "magnifyingglass"
        case .recommendation:
            return "checkmark.seal"
        case .forecast:
            return "calendar"
        case .healthScore:
            return "heart"
        }
    }
    
    private func handleQuickAction() {
        // Handle quick actions based on insight type
        switch insight.type {
        case .budgetAlert:
            // Navigate to budget view
            showingDetail = true
        case .spendingPattern:
            // Show analysis detail
            showingDetail = true
        case .anomaly:
            // Mark as reviewed and show detail
            onMarkAsRead(insight.id)
            showingDetail = true
        case .recommendation:
            // Mark as applied
            onMarkAsRead(insight.id)
        case .forecast:
            // Show forecast detail
            showingDetail = true
        case .healthScore:
            // Show health score detail
            showingDetail = true
        }
    }
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
            // Header with type and priority
            HStack {
                Image(systemName: typeIcon)
                    .font(.title3)
                    .foregroundColor(priorityColor)
                
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                if !insight.isRead {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Description
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Footer with action
            HStack {
                if insight.actionable {
                    Button(action: {
                        onMarkAsRead(insight.id)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                            Text("Got it")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(priorityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    insight.isRead ? Color.clear : priorityColor.opacity(0.3),
                    lineWidth: insight.isRead ? 0 : 1
                )
        )
        .opacity(insight.isRead ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Quick dismiss action
            Button {
                onMarkAsRead(insight.id)
            } label: {
                Label("Mark Read", systemImage: "checkmark.circle")
            }
            .tint(.blue)
            
            // Delete/dismiss insight
            Button {
                // Add dismiss action - for now just mark as read
                onMarkAsRead(insight.id)
            } label: {
                Label("Dismiss", systemImage: "xmark.circle")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            // Quick action based on insight type
            if insight.actionable {
                Button {
                    handleQuickAction()
                } label: {
                    Label(quickActionTitle, systemImage: quickActionIcon)
                }
                .tint(.green)
            }
            
            // Favorite/important toggle
            Button {
                // For now, just mark as read - could be expanded to favorites
                onMarkAsRead(insight.id)
            } label: {
                Label("Important", systemImage: "star.fill")
            }
            .tint(.orange)
        }
        .sheet(isPresented: $showingDetail) {
            InsightDetailView(
                insight: insight,
                transactions: transactions,
                categories: categories,
                analytics: analytics
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SmartInsightCardView(
            insight: SmartInsight(
                id: UUID(),
                type: .budgetAlert,
                title: "Budget Alert",
                description: "You're on track to exceed your dining budget by $150 this month based on your current spending pattern.",
                priority: .high,
                actionable: true,
                relatedCategoryId: nil,
                createdDate: Date(),
                isRead: false
            ),
            transactions: [],
            categories: [],
            analytics: SmartAnalyticsService(),
            onMarkAsRead: { _ in }
        )
        
        SmartInsightCardView(
            insight: SmartInsight(
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
            transactions: [],
            categories: [],
            analytics: SmartAnalyticsService(),
            onMarkAsRead: { _ in }
        )
        
        SmartInsightCardView(
            insight: SmartInsight(
                id: UUID(),
                type: .anomaly,
                title: "Unusual Transaction",
                description: "Detected an unusually large transaction of $500 in Entertainment category.",
                priority: .urgent,
                actionable: true,
                relatedCategoryId: nil,
                createdDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isRead: true
            ),
            transactions: [],
            categories: [],
            analytics: SmartAnalyticsService(),
            onMarkAsRead: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}