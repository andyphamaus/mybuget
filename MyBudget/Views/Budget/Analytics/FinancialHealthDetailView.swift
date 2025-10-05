import SwiftUI
import Charts

struct FinancialHealthDetailView: View {
    let healthScore: FinancialHealthScore
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingImprovementTips = false
    
    private var scoreColor: Color {
        let score = healthScore.overallScore
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Summary
                    HealthScoreSummaryCard(healthScore: healthScore)
                        .padding(.horizontal)
                    
                    // Detailed Score Breakdown
                    ScoreBreakdownSection(healthScore: healthScore)
                        .padding(.horizontal)
                    
                    // Spending Pattern Analysis
                    SpendingPatternSection(
                        transactions: transactions,
                        categories: categories
                    )
                    .padding(.horizontal)
                    
                    // Improvement Recommendations
                    ImprovementRecommendationsSection(
                        healthScore: healthScore,
                        transactions: transactions,
                        categories: categories,
                        showingTips: $showingImprovementTips
                    )
                    .padding(.horizontal)
                    
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("Financial Health Details")
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
}

struct HealthScoreSummaryCard: View {
    let healthScore: FinancialHealthScore
    
    private var scoreColor: Color {
        let score = healthScore.overallScore
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var scoreGrade: String {
        let score = healthScore.overallScore
        if score >= 90 {
            return "A"
        } else if score >= 80 {
            return "B"
        } else if score >= 70 {
            return "C"
        } else if score >= 60 {
            return "D"
        } else {
            return "F"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Health Score")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Text("\(Int(healthScore.overallScore))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Grade: \(scoreGrade)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(scoreColor)
                            
                            Text("/ 100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: healthScore.overallScore / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(healthScore.overallScore))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                }
            }
            
            Text(getStatusMessage())
                .font(.body)
                .foregroundColor(.secondary)
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
    
    private func getStatusMessage() -> String {
        let score = healthScore.overallScore
        if score >= 85 {
            return "Excellent! Your financial health is outstanding. You're managing your money very well and staying on track with your financial goals."
        } else if score >= 70 {
            return "Good progress! Your financial health is solid with some areas for improvement. Continue building good financial habits."
        } else if score >= 50 {
            return "Room for improvement. Focus on the key areas below to boost your financial health and achieve better money management."
        } else {
            return "Needs attention. Your financial health requires immediate focus. Review the recommendations below to get back on track."
        }
    }
}


struct ScoreBreakdownSection: View {
    let healthScore: FinancialHealthScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailedScoreRow(
                    title: "Budget Adherence",
                    score: healthScore.budgetAdherenceScore,
                    description: "How well you stick to your planned budget amounts",
                    icon: "chart.pie.fill"
                )
                
                DetailedScoreRow(
                    title: "Spending Consistency",
                    score: healthScore.consistencyScore,
                    description: "How consistent your spending patterns are over time",
                    icon: "waveform.path.ecg"
                )
                
                DetailedScoreRow(
                    title: "Savings Rate",
                    score: healthScore.savingsRateScore,
                    description: "How much you're saving relative to your income",
                    icon: "banknote.fill"
                )
                
                DetailedScoreRow(
                    title: "Category Balance",
                    score: healthScore.categoryBalanceScore,
                    description: "How well you balance spending across categories",
                    icon: "scale.3d"
                )
                
                DetailedScoreRow(
                    title: "Spending Trend",
                    score: healthScore.trendScore,
                    description: "Whether your spending trends are improving",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

struct DetailedScoreRow: View {
    let title: String
    let score: Double
    let description: String
    let icon: String
    
    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(scoreColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    
                    Text("/ 100")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * (score / 100.0), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SpendingPatternSection: View {
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    
    private var categorySpending: [(String, Double)] {
        let spending = Dictionary(grouping: transactions) { transaction in
            transaction.category?.name ?? "Unknown"
        }.mapValues { transactions in
            transactions.reduce(0) { $0 + $1.amountInCurrency }
        }
        
        return spending.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !categorySpending.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(categorySpending.enumerated()), id: \.offset) { index, item in
                        CategorySpendingRow(
                            category: item.0,
                            amount: item.1,
                            rank: index + 1
                        )
                    }
                }
            } else {
                Text("No spending data available for the selected timeframe")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

struct CategorySpendingRow: View {
    let category: String
    let amount: Double
    let rank: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Text("$\(Int(amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct ImprovementRecommendationsSection: View {
    let healthScore: FinancialHealthScore
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    @Binding var showingTips: Bool
    
    @EnvironmentObject var analytics: SmartAnalyticsService
    @State private var dynamicRecommendations: [HealthRecommendation] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI-Powered Improvement Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        showingTips.toggle()
                    }
                }) {
                    Image(systemName: showingTips ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if showingTips {
                VStack(spacing: 12) {
                    if dynamicRecommendations.isEmpty {
                        // Fallback to basic recommendations if AI analysis not available
                        if healthScore.budgetAdherenceScore < 70 {
                            HealthRecommendationCard(
                                icon: "target",
                                title: "Improve Budget Adherence",
                                description: "Try to stick closer to your planned amounts. Consider setting up alerts when you're approaching budget limits.",
                                priority: .high
                            )
                        }
                        
                        if healthScore.consistencyScore < 70 {
                            HealthRecommendationCard(
                                icon: "calendar",
                                title: "Build Consistent Habits",
                                description: "Aim for more predictable spending patterns. Consider automating regular expenses and setting up recurring budget reviews.",
                                priority: .medium
                            )
                        }
                    } else {
                        // Show AI-generated dynamic recommendations
                        ForEach(Array(dynamicRecommendations.enumerated()), id: \.offset) { index, recommendation in
                            HealthRecommendationCard(
                                icon: recommendation.icon,
                                title: recommendation.title,
                                description: recommendation.description,
                                priority: recommendation.priority
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .onAppear {
            generateDynamicTips()
        }
        .onChange(of: showingTips) { _, newValue in
            if newValue {
                generateDynamicTips()
            }
        }
    }
    
    private func generateDynamicTips() {
        Task {
            let recommendations = analytics.generateDynamicImprovementTips(
                healthScore: healthScore,
                transactions: transactions,
                categories: categories
            )
            
            await MainActor.run {
                dynamicRecommendations = recommendations
            }
        }
    }
}

struct HealthRecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    let priority: HealthRecommendation.Priority
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(priority.color)
                .frame(width: 32, height: 32)
                .background(priority.color.opacity(0.15))
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


#Preview {
    FinancialHealthDetailView(
        healthScore: FinancialHealthScore(
            overallScore: 76.5,
            budgetAdherenceScore: 82.3,
            consistencyScore: 68.9,
            savingsRateScore: 75.0,
            categoryBalanceScore: 81.2,
            trendScore: 74.8,
            lastCalculated: Date()
        ),
        transactions: [],
        categories: []
    )
}