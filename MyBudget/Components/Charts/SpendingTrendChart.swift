import SwiftUI
import Charts

struct SpendingTrendChart: View {
    let trendData: [SpendingTrendDataPoint]
    let timeRange: TrendTimeRange
    @State private var selectedDataPoint: SpendingTrendDataPoint?
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending Trends")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let selected = selectedDataPoint {
                        Text(selected.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(timeRange.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing) {
                        Text("$\(Int(selected.amount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: selected.changeFromPrevious >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                                .foregroundColor(selected.changeFromPrevious >= 0 ? .red : .green)
                            
                            Text("\(Int(abs(selected.changeFromPrevious)))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selected.changeFromPrevious >= 0 ? .red : .green)
                        }
                    }
                }
            }
            
            Chart(trendData) { dataPoint in
                // Main spending line
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.amount)
                )
                .foregroundStyle(Color.red.gradient)
                .lineStyle(.init(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                
                // Trend area
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Data points
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.amount)
                )
                .foregroundStyle(Color.red)
                .symbolSize(selectedDataPoint?.id == dataPoint.id ? 80 : 40)
                
                // Budget limit line (if available)
                if let budgetLimit = dataPoint.budgetLimit {
                    RuleMark(y: .value("Budget", budgetLimit))
                        .foregroundStyle(Color.orange.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                
                // Average line
                if let avgAmount = averageSpending {
                    RuleMark(y: .value("Average", avgAmount))
                        .foregroundStyle(Color.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
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
                                    selectedDataPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            .animation(.easeInOut(duration: 0.3), value: selectedDataPoint)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isAnimating)
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .red, title: "Spending", showLine: true)
                
                if trendData.contains(where: { $0.budgetLimit != nil }) {
                    LegendItem(color: .orange, title: "Budget Limit", showDash: true)
                }
                
                if averageSpending != nil {
                    LegendItem(color: .blue, title: "Average", showDash: true)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
    
    private var averageSpending: Double? {
        guard !trendData.isEmpty else { return nil }
        let total = trendData.reduce(0) { $0 + $1.amount }
        return total / Double(trendData.count)
    }
    
    private func updateSelectedPoint(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        let plotAreaSize = chartProxy.plotAreaSize
        let origin = geometry[chartProxy.plotAreaFrame].origin
        
        let relativeXPosition = location.x - origin.x
        let dateRange = trendData.last!.date.timeIntervalSince(trendData.first!.date)
        let relativeDate = (relativeXPosition / plotAreaSize.width) * dateRange
        let targetDate = trendData.first!.date.addingTimeInterval(relativeDate)
        
        // Find closest data point
        let closest = trendData.min { point1, point2 in
            abs(point1.date.timeIntervalSince(targetDate)) < abs(point2.date.timeIntervalSince(targetDate))
        }
        
        selectedDataPoint = closest
    }
}

struct SpendingTrendDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let amount: Double
    let budgetLimit: Double?
    let changeFromPrevious: Double
    let categoryBreakdown: [CategorySpendingPoint]?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CategorySpendingPoint: Identifiable, Hashable {
    let id = UUID()
    let categoryName: String
    let amount: Double
    let color: Color
}

enum TrendTimeRange: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "Past Week"
        case .month: return "Past Month"
        case .quarter: return "Past Quarter"
        case .year: return "Past Year"
        }
    }
    
    var dateInterval: TimeInterval {
        switch self {
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        case .quarter: return 90 * 24 * 60 * 60
        case .year: return 365 * 24 * 60 * 60
        }
    }
}

struct LegendItem: View {
    let color: Color
    let title: String
    var showLine: Bool = false
    var showDash: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if showLine {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
                    .cornerRadius(1)
            } else if showDash {
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: 3, height: 2)
                    }
                }
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Preview
struct SpendingTrendChart_Previews: PreviewProvider {
    static var previews: some View {
        SpendingTrendChart(
            trendData: sampleTrendData,
            timeRange: .month
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleTrendData: [SpendingTrendDataPoint] {
        let calendar = Calendar.current
        var data: [SpendingTrendDataPoint] = []
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let baseAmount = Double.random(in: 50...300)
            let change = Double.random(in: -20...20)
            
            data.append(SpendingTrendDataPoint(
                date: date,
                amount: baseAmount,
                budgetLimit: 250,
                changeFromPrevious: change,
                categoryBreakdown: nil
            ))
        }
        
        return data.reversed()
    }
}