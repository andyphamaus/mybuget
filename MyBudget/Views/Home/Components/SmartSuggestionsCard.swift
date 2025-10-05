import SwiftUI

struct SmartSuggestionsCard: View {
    let suggestions: [SmartSuggestion]
    @State private var currentSuggestionIndex = 0
    @State private var animationTrigger = false
    @State private var cardAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.md) {
            cardHeader
            
            if suggestions.isEmpty {
                emptyStateView
            } else {
                suggestionContent
                    .opacity(cardAppeared ? 1 : 0)
                    .scaleEffect(cardAppeared ? 1.0 : 0.95)
                    .animation(DashboardDesignSystem.Animation.smooth, value: cardAppeared)
                
                suggestionNavigation
            }
        }
        .padding(DashboardDesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DashboardDesignSystem.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(DashboardDesignSystem.CornerRadius.medium)
        .dashboardCardShadow()
        .onAppear {
            withAnimation(DashboardDesignSystem.Animation.smooth.delay(0.2)) {
                cardAppeared = true
            }
            startAutoRotation()
        }
    }
    
    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .font(.title3)
                    
                    Text("Smart Suggestions")
                        .font(DashboardDesignSystem.Typography.cardTitle)
                        .foregroundColor(.primary)
                }
                
                if !suggestions.isEmpty {
                    Text("Personalized recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            confidenceIndicator
        }
    }
    
    private var confidenceIndicator: some View {
        Group {
            if !suggestions.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 6, height: 6)
                    
                    Text("\(currentSuggestion.confidenceScore, specifier: "%.0f")%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(confidenceColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var suggestionContent: some View {
        VStack(alignment: .leading, spacing: DashboardDesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: currentSuggestion.icon)
                    .foregroundColor(currentSuggestion.type.color)
                    .font(.title2)
                    .frame(width: 32, height: 32)
                    .background(currentSuggestion.type.color.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentSuggestion.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(currentSuggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            
            if let actionTitle = currentSuggestion.actionTitle {
                actionButton(title: actionTitle)
            }
            
            insightMetrics
        }
        .id(animationTrigger) // Force re-render for animation
    }
    
    private var emptyStateView: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Gathering Insights")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("We'll provide personalized suggestions as you use the app")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, DashboardDesignSystem.Spacing.sm)
    }
    
    private func actionButton(title: String) -> some View {
        Button(action: {
            handleSuggestionAction()
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(currentSuggestion.type.color)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var insightMetrics: some View {
        HStack(spacing: 16) {
            if let impact = currentSuggestion.potentialImpact {
                metricItem(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Impact",
                    value: impact
                )
            }
            
            if let timeframe = currentSuggestion.timeframe {
                metricItem(
                    icon: "clock",
                    label: "Timeframe",
                    value: timeframe
                )
            }
            
            Spacer()
        }
        .padding(.top, DashboardDesignSystem.Spacing.xs)
    }
    
    private func metricItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(label): \(value)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var suggestionNavigation: some View {
        Group {
            if suggestions.count > 1 {
                HStack(spacing: 12) {
                    // Pagination dots
                    HStack(spacing: 6) {
                        ForEach(0..<suggestions.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentSuggestionIndex ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .scaleEffect(index == currentSuggestionIndex ? 1.2 : 1.0)
                                .animation(DashboardDesignSystem.Animation.quick, value: currentSuggestionIndex)
                        }
                    }
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 8) {
                        Button(action: previousSuggestion) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .background(Color(.systemFill))
                                .cornerRadius(6)
                        }
                        
                        Button(action: nextSuggestion) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .background(Color(.systemFill))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.top, DashboardDesignSystem.Spacing.xs)
            }
        }
    }
    
    private var currentSuggestion: SmartSuggestion {
        guard !suggestions.isEmpty, 
              currentSuggestionIndex >= 0, 
              currentSuggestionIndex < suggestions.count else {
            return SmartSuggestion.placeholder
        }
        return suggestions[currentSuggestionIndex]
    }
    
    private var confidenceColor: Color {
        let confidence = currentSuggestion.confidenceScore
        if confidence >= 80 {
            return .green
        } else if confidence >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func nextSuggestion() {
        guard !suggestions.isEmpty else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(DashboardDesignSystem.Animation.quick) {
            currentSuggestionIndex = (currentSuggestionIndex + 1) % suggestions.count
            animationTrigger.toggle()
        }
    }
    
    private func previousSuggestion() {
        guard !suggestions.isEmpty else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(DashboardDesignSystem.Animation.quick) {
            currentSuggestionIndex = currentSuggestionIndex == 0 ? suggestions.count - 1 : currentSuggestionIndex - 1
            animationTrigger.toggle()
        }
    }
    
    private func handleSuggestionAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // TODO: Implement suggestion action handling
    }
    
    private func startAutoRotation() {
        guard suggestions.count > 1 else { return }
        
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            withAnimation(DashboardDesignSystem.Animation.smooth) {
                nextSuggestion()
            }
        }
    }
}

// MARK: - Smart Suggestion Model
struct SmartSuggestion: Identifiable, Hashable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let icon: String
    let confidenceScore: Double // 0-100
    let potentialImpact: String?
    let timeframe: String?
    let actionTitle: String?
    let actionData: [String: Any]?
    
    enum SuggestionType {
        case productivity
        case financial
        case habit
        case optimization
        case warning
        
        var color: Color {
            switch self {
            case .productivity: return DashboardDesignSystem.Colors.primaryBlue
            case .financial: return DashboardDesignSystem.Colors.successGreen
            case .habit: return Color.purple
            case .optimization: return Color.orange
            case .warning: return DashboardDesignSystem.Colors.errorRed
            }
        }
    }
    
    static let placeholder = SmartSuggestion(
        type: .productivity,
        title: "Loading insights...",
        description: "Analyzing your patterns to provide personalized recommendations.",
        icon: "brain.head.profile",
        confidenceScore: 0,
        potentialImpact: nil,
        timeframe: nil,
        actionTitle: nil,
        actionData: nil
    )
    
    init(type: SuggestionType, title: String, description: String, icon: String, 
         confidenceScore: Double, potentialImpact: String? = nil, timeframe: String? = nil,
         actionTitle: String? = nil, actionData: [String: Any]? = nil) {
        self.type = type
        self.title = title
        self.description = description
        self.icon = icon
        self.confidenceScore = confidenceScore
        self.potentialImpact = potentialImpact
        self.timeframe = timeframe
        self.actionTitle = actionTitle
        self.actionData = actionData
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SmartSuggestion, rhs: SmartSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    let sampleSuggestions = [
        SmartSuggestion(
            type: .productivity,
            title: "Focus on High-Priority Tasks",
            description: "You complete 40% more tasks when you tackle high-priority items first thing in the morning.",
            icon: "target",
            confidenceScore: 85,
            potentialImpact: "+40% completion",
            timeframe: "This week",
            actionTitle: "Prioritize Morning Tasks"
        ),
        SmartSuggestion(
            type: .financial,
            title: "Spending Pattern Alert",
            description: "Your daily spending increases by 30% on weekends. Consider setting weekend budget limits.",
            icon: "creditcard",
            confidenceScore: 72,
            potentialImpact: "Save $200/mo",
            timeframe: "Immediate",
            actionTitle: "Set Weekend Budget"
        ),
        SmartSuggestion(
            type: .habit,
            title: "Productivity-Spending Correlation",
            description: "Your most productive days align with spending under $50. Maintain this balance for optimal performance.",
            icon: "chart.bar.xaxis",
            confidenceScore: 91,
            potentialImpact: "Maintain balance",
            timeframe: "Daily",
            actionTitle: "Track Daily Balance"
        )
    ]
    
    return SmartSuggestionsCard(suggestions: sampleSuggestions)
        .padding()
}