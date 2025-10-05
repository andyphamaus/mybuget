import SwiftUI
import Charts

struct BudgetForecastChart: View {
    let historicalData: [ForecastDataPoint]
    let predictedData: [ForecastDataPoint]
    let confidenceIntervals: [ConfidenceInterval]
    @State private var selectedPoint: ForecastDataPoint?
    @State private var isAnimating = false
    @State private var showConfidenceInterval = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Forecast")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Next 30 days prediction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let selected = selectedPoint {
                    VStack(alignment: .trailing) {
                        Text("$\(Int(selected.amount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(selected.isHistorical ? .primary : .blue)
                        
                        Text(selected.isHistorical ? "Actual" : "Predicted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showConfidenceInterval.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showConfidenceInterval ? "eye.fill" : "eye.slash")
                                .font(.caption)
                            Text("Confidence")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Chart {
                // Confidence interval (if enabled)
                if showConfidenceInterval {
                    ForEach(confidenceIntervals) { interval in
                        AreaMark(
                            x: .value("Date", interval.date),
                            yStart: .value("Lower", interval.lowerBound),
                            yEnd: .value("Upper", interval.upperBound)
                        )
                        .foregroundStyle(Color.blue.opacity(0.1))
                    }
                }
                
                // Historical data
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(Color.primary.gradient)
                    .lineStyle(.init(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(Color.primary)
                    .symbolSize(selectedPoint?.id == point.id ? 60 : 30)
                }
                
                // Predicted data
                ForEach(predictedData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .lineStyle(.init(lineWidth: 3, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(selectedPoint?.id == point.id ? 60 : 30)
                }
                
                // Today marker
                RuleMark(x: .value("Today", Date()))
                    .foregroundStyle(Color.orange)
                    .lineStyle(.init(lineWidth: 2))
                    .annotation(position: .top, alignment: .center) {
                        Text("Today")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                
                // Budget limit line
                if let budgetLimit = budgetLimit {
                    RuleMark(y: .value("Budget", budgetLimit))
                        .foregroundStyle(Color.red.opacity(0.7))
                        .lineStyle(.init(lineWidth: 2, dash: [8, 4]))
                        .annotation(position: .trailing, alignment: .center) {
                            Text("Budget Limit")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSelectedPoint(at: value.location, geometry: geometry, chartProxy: chartProxy)
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 220)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isAnimating)
            
            // Forecast insights
            ForecastInsightsView(
                historicalData: historicalData,
                predictedData: predictedData,
                budgetLimit: budgetLimit
            )
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .primary, title: "Historical", showLine: true)
                LegendItem(color: .blue, title: "Predicted", showDash: true)
                if showConfidenceInterval {
                    LegendItem(color: .blue.opacity(0.3), title: "Confidence Range")
                }
                LegendItem(color: .red, title: "Budget Limit", showDash: true)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    private var allDataPoints: [ForecastDataPoint] {
        historicalData + predictedData
    }
    
    private var budgetLimit: Double? {
        // Calculate from historical data - could be passed as parameter
        let averageSpending = historicalData.map { $0.amount }.reduce(0, +) / Double(historicalData.count)
        return averageSpending * 1.2 // 20% buffer
    }
    
    private func updateSelectedPoint(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        let plotAreaSize = chartProxy.plotAreaSize
        let origin = geometry[chartProxy.plotAreaFrame].origin
        
        let relativeXPosition = location.x - origin.x
        let allPoints = allDataPoints
        guard let firstDate = allPoints.first?.date,
              let lastDate = allPoints.last?.date else { return }
        
        let dateRange = lastDate.timeIntervalSince(firstDate)
        let relativeDate = (relativeXPosition / plotAreaSize.width) * dateRange
        let targetDate = firstDate.addingTimeInterval(relativeDate)
        
        // Find closest data point
        let closest = allPoints.min { point1, point2 in
            abs(point1.date.timeIntervalSince(targetDate)) < abs(point2.date.timeIntervalSince(targetDate))
        }
        
        selectedPoint = closest
    }
}

struct ForecastDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let amount: Double
    let isHistorical: Bool
    let confidence: Double? // 0.0 to 1.0 for predicted points
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct ConfidenceInterval: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let lowerBound: Double
    let upperBound: Double
    let confidence: Double // e.g., 0.95 for 95% confidence
}

struct ForecastInsightsView: View {
    let historicalData: [ForecastDataPoint]
    let predictedData: [ForecastDataPoint]
    let budgetLimit: Double?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Forecast Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                InsightCard(
                    title: "Trend",
                    value: trendDirection,
                    color: trendColor,
                    icon: trendIcon
                )
                
                InsightCard(
                    title: "Risk Level",
                    value: riskLevel,
                    color: riskColor,
                    icon: riskIcon
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var trendDirection: String {
        guard let lastHistorical = historicalData.last?.amount,
              let firstPredicted = predictedData.first?.amount else {
            return "Unknown"
        }
        
        let change = ((firstPredicted - lastHistorical) / lastHistorical) * 100
        
        if change > 5 {
            return "Increasing"
        } else if change < -5 {
            return "Decreasing"
        } else {
            return "Stable"
        }
    }
    
    private var trendColor: Color {
        switch trendDirection {
        case "Increasing": return .red
        case "Decreasing": return .green
        default: return .blue
        }
    }
    
    private var trendIcon: String {
        switch trendDirection {
        case "Increasing": return "arrow.up.right"
        case "Decreasing": return "arrow.down.right"
        default: return "arrow.right"
        }
    }
    
    private var riskLevel: String {
        guard let budgetLimit = budgetLimit else { return "Unknown" }
        
        let maxPredicted = predictedData.map { $0.amount }.max() ?? 0
        let riskPercentage = (maxPredicted / budgetLimit) * 100
        
        if riskPercentage > 100 {
            return "High Risk"
        } else if riskPercentage > 80 {
            return "Medium Risk"
        } else {
            return "Low Risk"
        }
    }
    
    private var riskColor: Color {
        switch riskLevel {
        case "High Risk": return .red
        case "Medium Risk": return .orange
        default: return .green
        }
    }
    
    private var riskIcon: String {
        switch riskLevel {
        case "High Risk": return "exclamationmark.triangle.fill"
        case "Medium Risk": return "exclamationmark.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(6)
    }
}

// Preview
struct BudgetForecastChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            BudgetForecastChart(
                historicalData: sampleHistoricalData,
                predictedData: samplePredictedData,
                confidenceIntervals: sampleConfidenceIntervals
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleHistoricalData: [ForecastDataPoint] {
        let calendar = Calendar.current
        var data: [ForecastDataPoint] = []
        
        for i in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let amount = Double.random(in: 100...250) + Double(i) * 2 // Slight upward trend
            
            data.append(ForecastDataPoint(
                date: date,
                amount: amount,
                isHistorical: true,
                confidence: nil
            ))
        }
        
        return data.reversed()
    }
    
    static var samplePredictedData: [ForecastDataPoint] {
        let calendar = Calendar.current
        var data: [ForecastDataPoint] = []
        
        for i in 1...14 {
            let date = calendar.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let amount = Double.random(in: 180...320) + Double(i) * 3 // Continued upward trend
            let confidence = max(0.5, 1.0 - Double(i) * 0.05) // Decreasing confidence over time
            
            data.append(ForecastDataPoint(
                date: date,
                amount: amount,
                isHistorical: false,
                confidence: confidence
            ))
        }
        
        return data
    }
    
    static var sampleConfidenceIntervals: [ConfidenceInterval] {
        let calendar = Calendar.current
        var intervals: [ConfidenceInterval] = []
        
        for i in 1...14 {
            let date = calendar.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let centerAmount = Double.random(in: 180...320)
            let margin = Double(i) * 10 // Increasing uncertainty
            
            intervals.append(ConfidenceInterval(
                date: date,
                lowerBound: centerAmount - margin,
                upperBound: centerAmount + margin,
                confidence: 0.95
            ))
        }
        
        return intervals
    }
}