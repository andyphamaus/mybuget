import SwiftUI
import Charts

enum PredictiveTimeframeFilter: CaseIterable {
    case threeMonths, sixMonths, oneYear
    
    var title: String {
        switch self {
        case .threeMonths: return "3M"
        case .sixMonths: return "6M" 
        case .oneYear: return "1Y"
        }
    }
    
    var monthsBack: Int {
        switch self {
        case .threeMonths: return -3
        case .sixMonths: return -6
        case .oneYear: return -12
        }
    }
}

struct PredictiveChartView: View {
    let forecasts: [String: BudgetForecast] // categoryId -> forecast
    let categories: [LocalCategory]
    let historicalData: [LocalTransaction]
    
    @State private var selectedCategory: String = ""
    @State private var showingConfidenceInterval = true
    @State private var selectedTimeframe: PredictiveTimeframeFilter = .sixMonths
    @State private var selectedDataPoint: PredictiveDataPoint?
    @State private var showingDataDetails = false
    
    private var selectedForecast: BudgetForecast? {
        return forecasts[selectedCategory]
    }
    
    private var chartData: [PredictiveDataPoint] {
        guard let forecast = selectedForecast else { return [] }
        
        // Get historical data for the selected category
        let categoryTransactions = historicalData.filter { $0.category?.id == selectedCategory }
        let sortedTransactions = categoryTransactions.sorted { transaction1, transaction2 in
            let dateFormatter = ISO8601DateFormatter()
            let date1 = transaction1.transactionDate.flatMap { dateString in dateFormatter.date(from: dateString) } ?? Date.distantPast
            let date2 = transaction2.transactionDate.flatMap { dateString in dateFormatter.date(from: dateString) } ?? Date.distantPast
            return date1 < date2
        }
        
        var dataPoints: [PredictiveDataPoint] = []
        
        // Add historical points based on selected timeframe
        let calendar = Calendar.current
        let now = Date()
        let monthsBack = selectedTimeframe.monthsBack
        
        for monthOffset in monthsBack..<0 {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: now) else { continue }
            let monthStart = calendar.startOfMonth(for: monthDate)
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            
            let monthTransactions = sortedTransactions.filter { transaction in
                guard let dateString = transaction.transactionDate,
                      let transactionDate = ISO8601DateFormatter().date(from: dateString) else { return false }
                return transactionDate >= monthStart && transactionDate < monthEnd
            }
            
            let monthTotal = monthTransactions.reduce(0) { $0 + $1.amountInCurrency }
            
            dataPoints.append(PredictiveDataPoint(
                date: monthStart,
                actualAmount: monthTotal,
                forecastAmount: nil,
                lowerBound: nil,
                upperBound: nil,
                isHistorical: true
            ))
        }
        
        // Add forecast point
        dataPoints.append(PredictiveDataPoint(
            date: forecast.forecastDate,
            actualAmount: nil,
            forecastAmount: forecast.forecastAmount,
            lowerBound: forecast.confidenceInterval.lower,
            upperBound: forecast.confidenceInterval.upper,
            isHistorical: false
        ))
        
        return dataPoints
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spending Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let category = categories.first(where: { $0.id == selectedCategory }) {
                    Text("\(category.name ?? "Unknown Category") - Next Month Prediction")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "crystal.ball")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
    
    private var timeframeSelectorSection: some View {
        HStack {
            Text("Timeframe:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(PredictiveTimeframeFilter.allCases, id: \.self) { timeframe in
                    Button(timeframe.title) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTimeframe = timeframe
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray5))
                    .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Category selector
            if !forecasts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories.filter { forecasts[$0.id ?? ""] != nil }, id: \.id) { category in
                            CategoryChipView(
                                category: category,
                                isSelected: selectedCategory == (category.id ?? ""),
                                onTap: {
                                    selectedCategory = category.id ?? ""
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Timeframe selector
            timeframeSelectorSection
            
            // Chart
            if !chartData.isEmpty {
                PredictiveChart(
                    chartData: chartData,
                    selectedDataPoint: $selectedDataPoint,
                    showingConfidenceInterval: showingConfidenceInterval,
                    showingDataDetails: $showingDataDetails
                )
            } else {
                Text("Select a category to view forecast")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
            
            // Forecast details
            if let forecast = selectedForecast,
               let category = categories.first(where: { $0.id == selectedCategory }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Forecast Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(category.name ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Predicted Amount")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(Int(forecast.forecastAmount))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Confidence Range")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(Int(forecast.confidenceInterval.lower)) - $\(Int(forecast.confidenceInterval.upper))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let pattern = forecast.basedOnPattern {
                        Text("Based on \(pattern.frequency) transactions with \(Int(pattern.confidenceScore * 100))% confidence")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            if selectedCategory.isEmpty, let firstForecast = forecasts.keys.first {
                selectedCategory = firstForecast
            }
        }
        .sheet(isPresented: $showingDataDetails) {
            ChartDataDetailView(
                chartData: chartData,
                selectedCategory: selectedCategory,
                categoryName: categories.first(where: { $0.id == selectedCategory })?.name ?? "Unknown",
                selectedTimeframe: selectedTimeframe
            )
        }
    }
}

struct PredictiveDataPoint {
    let date: Date
    let actualAmount: Double?
    let forecastAmount: Double?
    let lowerBound: Double?
    let upperBound: Double?
    let isHistorical: Bool
}

struct CategoryChipView: View {
    let category: LocalCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category.name ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct ChartLegendItem: View {
    let color: Color
    let symbol: SymbolShape
    let text: String
    
    enum SymbolShape {
        case circle, diamond, rectangle
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Group {
                switch symbol {
                case .circle:
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                case .diamond:
                    Diamond()
                        .fill(color)
                        .frame(width: 8, height: 8)
                case .rectangle:
                    Rectangle()
                        .fill(color)
                        .frame(width: 12, height: 6)
                }
            }
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width/2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height/2))
        path.addLine(to: CGPoint(x: width/2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height/2))
        path.closeSubpath()
        
        return path
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

// MARK: - Chart Data Detail View

struct ChartDataDetailView: View {
    let chartData: [PredictiveDataPoint]
    let selectedCategory: String
    let categoryName: String
    let selectedTimeframe: PredictiveTimeframeFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category: \(categoryName)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Timeframe: \(selectedTimeframe.title)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Data Points: \(chartData.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Overview")
                }
                
                Section {
                    ForEach(chartData.sorted(by: { $0.date < $1.date }), id: \.date) { dataPoint in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dataPoint.date, style: .date)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Text(dataPoint.isHistorical ? "Historical Data" : "Forecast")
                                        .font(.caption2)
                                        .foregroundColor(dataPoint.isHistorical ? .blue : .orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(dataPoint.isHistorical ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    if let actualAmount = dataPoint.actualAmount {
                                        HStack(spacing: 4) {
                                            Text("Actual:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("$\(Int(actualAmount))")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    if let forecastAmount = dataPoint.forecastAmount {
                                        HStack(spacing: 4) {
                                            Text("Forecast:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("$\(Int(forecastAmount))")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    
                                    if let lowerBound = dataPoint.lowerBound,
                                       let upperBound = dataPoint.upperBound {
                                        Text("Range: $\(Int(lowerBound)) - $\(Int(upperBound))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Data Points (\(chartData.count))")
                } footer: {
                    if !chartData.isEmpty {
                        let historicalCount = chartData.filter { $0.isHistorical }.count
                        let forecastCount = chartData.filter { !$0.isHistorical }.count
                        Text("\(historicalCount) historical • \(forecastCount) forecast")
                    }
                }
                
                if !chartData.isEmpty {
                    Section {
                        let historicalData = chartData.compactMap { $0.actualAmount }
                        let forecastData = chartData.compactMap { $0.forecastAmount }
                        
                        if !historicalData.isEmpty {
                            StatRow(title: "Historical Average", value: "$\(Int(historicalData.reduce(0, +) / Double(historicalData.count)))")
                            StatRow(title: "Historical Max", value: "$\(Int(historicalData.max() ?? 0))")
                            StatRow(title: "Historical Min", value: "$\(Int(historicalData.min() ?? 0))")
                        }
                        
                        if !forecastData.isEmpty {
                            StatRow(title: "Forecast Amount", value: "$\(Int(forecastData.first ?? 0))")
                        }
                    } header: {
                        Text("Statistics")
                    }
                }
            }
            .navigationTitle("Chart Data")
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

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct PredictiveChart: View {
    let chartData: [PredictiveDataPoint]
    @Binding var selectedDataPoint: PredictiveDataPoint?
    let showingConfidenceInterval: Bool
    @Binding var showingDataDetails: Bool
    
    // Simplify to just basic chart
    private var basicChart: some View {
        Chart {
            ForEach(chartData, id: \.date) { dataPoint in
                if let actualAmount = dataPoint.actualAmount {
                    LineMark(
                        x: .value("Month", dataPoint.date),
                        y: .value("Amount", actualAmount)
                    )
                    .foregroundStyle(.blue)
                    
                    PointMark(
                        x: .value("Month", dataPoint.date),
                        y: .value("Amount", actualAmount)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                }
                
                if let forecastAmount = dataPoint.forecastAmount {
                    PointMark(
                        x: .value("Month", dataPoint.date),
                        y: .value("Amount", forecastAmount)
                    )
                    .foregroundStyle(.orange)
                    .symbol(.diamond)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            basicChart
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.month(.abbreviated))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                        }
                    }
                }
            }
            
            // Selected data point details
            if let dataPoint = selectedDataPoint {
                VStack(spacing: 8) {
                    Text("Data Point Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dataPoint.date, style: .date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        if let actualAmount = dataPoint.actualAmount {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Actual")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(Int(actualAmount))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let forecastAmount = dataPoint.forecastAmount {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Forecast")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(Int(forecastAmount))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            
                            if let lower = dataPoint.lowerBound, let upper = dataPoint.upperBound {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Range")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(Int(lower)) - $\(Int(upper))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3), value: selectedDataPoint?.date)
            }
            
            // Chart legend
            HStack(spacing: 16) {
                ChartLegendItem(color: .blue, symbol: .circle, text: "Historical")
                ChartLegendItem(color: .orange, symbol: .diamond, text: "Forecast")
                
                if showingConfidenceInterval {
                    ChartLegendItem(color: .orange.opacity(0.3), symbol: .rectangle, text: "95% Confidence")
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        showingDataDetails = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                            Text("Data")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ScrollView {
        PredictiveChartView(
            forecasts: [
                "category1": BudgetForecast(
                    categoryId: "category1",
                    forecastAmount: 450.0,
                    confidenceInterval: (lower: 380.0, upper: 520.0),
                    forecastDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                    basedOnPattern: SpendingPattern(
                        categoryId: "category1",
                        averageAmount: 420.0,
                        frequency: 12,
                        dayOfWeekPattern: [0.1, 0.15, 0.15, 0.15, 0.15, 0.2, 0.1],
                        monthlyTrend: Array(repeating: 400.0, count: 12),
                        seasonalFactor: 1.1,
                        confidenceScore: 0.85
                    )
                )
            ],
            categories: [
                LocalCategory()
            ],
            historicalData: []
        )
    }
    .background(Color(.systemGroupedBackground))
}