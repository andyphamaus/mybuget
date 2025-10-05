import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let categories: [CategoryData]
    let chartType: CategoryChartType
    @State private var selectedCategory: CategoryData?
    @State private var isAnimating = false
    @State private var animationProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category Breakdown")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let selected = selectedCategory {
                        Text(selected.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(categories.count) categories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedCategory {
                    VStack(alignment: .trailing) {
                        Text("$\(Int(selected.amount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.1f", selected.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Total: $\(Int(totalAmount))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Group {
                switch chartType {
                case .pie:
                    PieChartView(categories: categories, selectedCategory: $selectedCategory, animationProgress: animationProgress)
                case .donut:
                    DonutChartView(categories: categories, selectedCategory: $selectedCategory, animationProgress: animationProgress)
                case .bar:
                    BarChartView(categories: categories, selectedCategory: $selectedCategory, isAnimating: isAnimating)
                case .horizontalBar:
                    HorizontalBarChartView(categories: categories, selectedCategory: $selectedCategory, isAnimating: isAnimating)
                }
            }
            .frame(height: chartType == .pie || chartType == .donut ? 250 : 200)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            
            // Category Legend
            CategoryLegendView(categories: categories, selectedCategory: $selectedCategory)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var totalAmount: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
}

struct PieChartView: View {
    let categories: [CategoryData]
    @Binding var selectedCategory: CategoryData?
    let animationProgress: Double
    
    var body: some View {
        Chart(categories) { category in
            SectorMark(
                angle: .value("Amount", category.amount * animationProgress)
            )
            .foregroundStyle(Color(hex: category.color))
            .opacity(selectedCategory == nil || selectedCategory?.id == category.id ? 1.0 : 0.6)
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotAreaFrame]
                VStack {
                    if let selected = selectedCategory {
                        Text(selected.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("$\(Int(selected.amount))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: selected.color))
                        Text("\(String(format: "%.1f", selected.percentage))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Touch to explore")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .position(x: frame.midX, y: frame.midY)
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
                                updateSelectedCategory(at: value.location, geometry: geometry, chartProxy: chartProxy)
                            }
                            .onEnded { _ in
                                selectedCategory = nil
                            }
                    )
            }
        }
    }
    
    private func updateSelectedCategory(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        let plotAreaFrame = chartProxy.plotAreaFrame
        let center = CGPoint(
            x: geometry[plotAreaFrame].midX,
            y: geometry[plotAreaFrame].midY
        )
        
        let angle = atan2(location.y - center.y, location.x - center.x)
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        
        var cumulativeAngle: Double = 0
        let total = categories.reduce(0) { $0 + $1.amount }
        
        for category in categories {
            let categoryAngle = (category.amount / total) * 2 * .pi
            if normalizedAngle >= cumulativeAngle && normalizedAngle <= cumulativeAngle + categoryAngle {
                selectedCategory = category
                return
            }
            cumulativeAngle += categoryAngle
        }
    }
}

struct DonutChartView: View {
    let categories: [CategoryData]
    @Binding var selectedCategory: CategoryData?
    let animationProgress: Double
    
    var body: some View {
        Chart(categories) { category in
            SectorMark(
                angle: .value("Amount", category.amount * animationProgress),
                innerRadius: .ratio(0.4)
            )
            .foregroundStyle(Color(hex: category.color))
            .opacity(selectedCategory == nil || selectedCategory?.id == category.id ? 1.0 : 0.6)
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotAreaFrame]
                VStack {
                    if let selected = selectedCategory {
                        Text(selected.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("$\(Int(selected.amount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: selected.color))
                        Text("\(String(format: "%.1f", selected.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Total Spending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(Int(categories.reduce(0) { $0 + $1.amount }))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }
}

struct BarChartView: View {
    let categories: [CategoryData]
    @Binding var selectedCategory: CategoryData?
    let isAnimating: Bool
    
    var body: some View {
        Chart(categories) { category in
            BarMark(
                x: .value("Category", category.name),
                y: .value("Amount", isAnimating ? category.amount : 0)
            )
            .foregroundStyle(Color(hex: category.color))
            .opacity(selectedCategory == nil || selectedCategory?.id == category.id ? 1.0 : 0.6)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("$\(Int(doubleValue))")
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.caption2)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
        }
        .animation(.easeOut(duration: 1.0), value: isAnimating)
    }
}

struct HorizontalBarChartView: View {
    let categories: [CategoryData]
    @Binding var selectedCategory: CategoryData?
    let isAnimating: Bool
    
    var body: some View {
        Chart(categories.sorted { $0.amount > $1.amount }) { category in
            BarMark(
                x: .value("Amount", isAnimating ? category.amount : 0),
                y: .value("Category", category.name)
            )
            .foregroundStyle(Color(hex: category.color))
            .opacity(selectedCategory == nil || selectedCategory?.id == category.id ? 1.0 : 0.6)
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("$\(Int(doubleValue))")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.caption)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 1.0), value: isAnimating)
    }
}

struct CategoryLegendView: View {
    let categories: [CategoryData]
    @Binding var selectedCategory: CategoryData?
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(categories.prefix(6)) { category in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = selectedCategory?.id == category.id ? nil : category
                    }
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: category.color))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text("$\(Int(category.amount))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.secondarySystemBackground))
                            .opacity(selectedCategory?.id == category.id ? 1.0 : 0.3)
                    )
                    .scaleEffect(selectedCategory?.id == category.id ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.easeInOut(duration: 0.2), value: selectedCategory?.id)
            }
        }
    }
}

struct CategoryData: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: String
    let percentage: Double
    let transactionCount: Int
    let budget: Double?
    
    var isOverBudget: Bool {
        guard let budget = budget else { return false }
        return amount > budget
    }
    
    var budgetUsagePercentage: Double {
        guard let budget = budget, budget > 0 else { return 0 }
        return (amount / budget) * 100
    }
}

enum CategoryChartType: String, CaseIterable {
    case pie = "Pie"
    case donut = "Donut"
    case bar = "Bar"
    case horizontalBar = "Horizontal Bar"
    
    var iconName: String {
        switch self {
        case .pie: return "chart.pie.fill"
        case .donut: return "chart.donut.fill"
        case .bar: return "chart.bar.fill"
        case .horizontalBar: return "chart.bar.fill"
        }
    }
}

// Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview
struct CategoryBreakdownChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                CategoryBreakdownChart(categories: sampleCategories, chartType: .donut)
                CategoryBreakdownChart(categories: sampleCategories, chartType: .horizontalBar)
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleCategories: [CategoryData] {
        [
            CategoryData(name: "Groceries", amount: 450, color: "#FF6B6B", percentage: 30, transactionCount: 15, budget: 500),
            CategoryData(name: "Transportation", amount: 320, color: "#4ECDC4", percentage: 21, transactionCount: 8, budget: 400),
            CategoryData(name: "Dining", amount: 280, color: "#45B7D1", percentage: 18, transactionCount: 12, budget: 250),
            CategoryData(name: "Entertainment", amount: 200, color: "#96CEB4", percentage: 13, transactionCount: 6, budget: 200),
            CategoryData(name: "Shopping", amount: 150, color: "#FFEAA7", percentage: 10, transactionCount: 4, budget: 300),
            CategoryData(name: "Utilities", amount: 120, color: "#DDA0DD", percentage: 8, transactionCount: 3, budget: 150)
        ]
    }
}