import SwiftUI

struct HealthScoreCard: View {
    let healthScore: FinancialHealthScore
    let transactions: [LocalTransaction]
    let categories: [LocalCategory]
    @State private var animateScore = false
    @State private var showingDetailView = false
    
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
            // Header
            HStack {
                Text("Financial Health Score")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(scoreColor)
            }
            
            // Main score display
            HStack(spacing: 24) {
                // Circular score indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: animateScore ? healthScore.overallScore / 100.0 : 0)
                        .stroke(
                            scoreColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5), value: animateScore)
                    
                    // Score text
                    VStack(spacing: 2) {
                        Text("\(Int(healthScore.overallScore))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        
                        Text("/ 100")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Score breakdown
                VStack(alignment: .leading, spacing: 8) {
                    ScoreComponentRow(
                        title: "Budget Adherence",
                        score: healthScore.budgetAdherenceScore,
                        icon: "chart.pie.fill"
                    )
                    
                    ScoreComponentRow(
                        title: "Consistency",
                        score: healthScore.consistencyScore,
                        icon: "waveform.path.ecg"
                    )
                    
                    ScoreComponentRow(
                        title: "Savings Rate",
                        score: healthScore.savingsRateScore,
                        icon: "banknote.fill"
                    )
                    
                    ScoreComponentRow(
                        title: "Category Balance",
                        score: healthScore.categoryBalanceScore,
                        icon: "scale.3d"
                    )
                }
            }
            
            // Grade and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Grade:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(scoreGrade)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(scoreColor.opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    Text(getStatusMessage())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: {
                    showingDetailView = true
                }) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(scoreColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                animateScore = true
            }
        }
        .sheet(isPresented: $showingDetailView) {
            FinancialHealthDetailView(
                healthScore: healthScore,
                transactions: transactions,
                categories: categories
            )
        }
    }
    
    private func getStatusMessage() -> String {
        let score = healthScore.overallScore
        if score >= 85 {
            return "Excellent financial health! Keep it up!"
        } else if score >= 70 {
            return "Good financial health with room for improvement"
        } else if score >= 50 {
            return "Fair financial health - focus on key areas"
        } else {
            return "Financial health needs attention"
        }
    }
}

struct ScoreComponentRow: View {
    let title: String
    let score: Double
    let icon: String
    
    private var componentColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(componentColor)
                .frame(width: 12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(Int(score))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(componentColor)
        }
    }
}

#Preview {
    HealthScoreCard(
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
    .padding()
    .background(Color(.systemGroupedBackground))
}