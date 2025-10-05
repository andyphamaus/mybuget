import SwiftUI

// MARK: - Budget Remaining View (Tab 2: Remaining/Tracking)

struct BudgetRemainingView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showingAddTransaction = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Sections with Tracking
                if !viewModel.sections.isEmpty {
                    ForEach(viewModel.sections.sorted { $0.displayOrder < $1.displayOrder }, id: \.id) { section in
                        BudgetRemainingSectionView(
                            section: section,
                            viewModel: viewModel,
                            showingAddTransaction: $showingAddTransaction
                        )
                        .padding(.horizontal)
                    }
                } else {
                    // Empty state
                    EmptyRemainingState()
                        .padding(.horizontal)
                }
                
                // Bottom padding for better scroll experience
                Spacer(minLength: 100)
            }
            .padding(.top, 10)
        }
        .refreshable {
            await viewModel.refreshCurrentBudgetData()
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionAmountSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Budget Summary Card

struct BudgetSummaryCard: View {
    let summary: BudgetSummary
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Budget Overview")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
            }
            
            // Main stats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                // Total Planned
                VStack(spacing: 8) {
                    Text("Total Planned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("$\(summary.plannedIncomeAmount + summary.plannedExpenseAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // Total Spent
                VStack(spacing: 8) {
                    Text("Total Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("$\(summary.actualIncomeAmount + summary.actualExpenseAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor((summary.actualIncomeAmount + summary.actualExpenseAmount) > (summary.plannedIncomeAmount + summary.plannedExpenseAmount) ? .red : .green)
                }
            }
            
            // Remaining amount
            VStack(spacing: 8) {
                Text("Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                let remaining = (summary.plannedIncomeAmount + summary.plannedExpenseAmount) - (summary.actualIncomeAmount + summary.actualExpenseAmount)
                Text("$\(remaining, specifier: "%.0f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(remaining >= 0 ? .green : .red)
            }
            .padding(.top, 8)
            
            // Progress bar
            if (summary.plannedIncomeAmount + summary.plannedExpenseAmount) > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Overall Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(((summary.actualIncomeAmount + summary.actualExpenseAmount) / (summary.plannedIncomeAmount + summary.plannedExpenseAmount)) * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: min((summary.actualIncomeAmount + summary.actualExpenseAmount) / (summary.plannedIncomeAmount + summary.plannedExpenseAmount), 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: (summary.actualIncomeAmount + summary.actualExpenseAmount) > (summary.plannedIncomeAmount + summary.plannedExpenseAmount) ? .red : .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Category Progress Card

struct CategoryProgressCard: View {
    let category: LocalCategory
    let viewModel: BudgetViewModel
    
    private var progressPercentage: Double {
        let planned = plannedAmount
        let actual = actualAmount
        guard planned > 0 else { return 0 }
        return min(actual / planned, 1.0)
    }
    
    private var plannedAmount: Double {
        return viewModel.plans.filter { $0.category?.id == category.id }.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    private var actualAmount: Double {
        return viewModel.transactions.filter { $0.category?.id == category.id }.reduce(0) { total, transaction in
            // If transaction type matches category type, add as positive
            // If transaction type doesn't match (e.g., expense in income category), subtract
            let categoryType = category.headCategory?.preferType ?? "EXPENSE"
            let transactionType = transaction.type ?? "EXPENSE"
            
            if categoryType == transactionType {
                return total + transaction.amountInCurrency
            } else {
                // Opposite type - subtract the amount
                return total - transaction.amountInCurrency
            }
        }
    }
    
    private var isOverBudget: Bool {
        actualAmount > plannedAmount
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Category header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name ?? "Unknown Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(category.headCategory?.preferType?.capitalized ?? "EXPENSE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Status indicator
                if isOverBudget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                } else if actualAmount == 0 {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title3)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            // Amount details
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent: $\(actualAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Planned: $\(plannedAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    let remaining = plannedAmount - actualAmount
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(remaining, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                }
            }
            
            // Progress bar
            if plannedAmount > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Spacer()
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(isOverBudget ? .red : .blue)
                    }
                    
                    ProgressView(value: progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: isOverBudget ? .red : .blue))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOverBudget ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Budget Remaining Section View

struct TransactionSheetData: Identifiable, Equatable {
    let id = UUID()
    let category: LocalCategory
    
    static func == (lhs: TransactionSheetData, rhs: TransactionSheetData) -> Bool {
        lhs.id == rhs.id && lhs.category.id == rhs.category.id
    }
}

struct TransactionListSheetData: Identifiable, Equatable {
    let id = UUID()
    let category: LocalCategory
    
    static func == (lhs: TransactionListSheetData, rhs: TransactionListSheetData) -> Bool {
        lhs.id == rhs.id && lhs.category.id == rhs.category.id
    }
}

struct BudgetRemainingSectionView: View {
    let section: LocalPeriodSection
    @ObservedObject var viewModel: BudgetViewModel
    @Binding var showingAddTransaction: Bool
    @State private var transactionSheetData: TransactionSheetData?
    @State private var transactionListSheetData: TransactionListSheetData?
    
    private var sectionPlans: [LocalBudgetPeriodPlan] {
        viewModel.plansForSection(section)
    }
    
    private var sectionCategories: [LocalCategory] {
        guard let mappings = section.categoryMappings as? Set<LocalPeriodSectionCategory> else { return [] }
        
        // Sort categories by displayOrder to match the planning view
        return mappings
            .compactMap { mapping -> (LocalCategory, Int32)? in
                guard let category = mapping.category else { return nil }
                return (category, mapping.displayOrder)
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
    
    private var sectionIncomeTotal: Double {
        return sectionPlans.filter { $0.category?.headCategory?.preferType == "INCOME" }.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    private var sectionExpenseTotal: Double {
        return sectionPlans.filter { $0.category?.headCategory?.preferType == "EXPENSE" }.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    private var sectionIncomeActual: Double {
        return sectionCategories.filter { $0.headCategory?.preferType == "INCOME" }.reduce(0) { total, category in
            let categoryTransactions = viewModel.transactions.filter { $0.category?.id == category.id }
            return total + categoryTransactions.reduce(0) { subtotal, transaction in
                // For income categories, add income transactions and subtract expense transactions
                let transactionType = transaction.type ?? "EXPENSE"
                if transactionType == "INCOME" {
                    return subtotal + transaction.amountInCurrency
                } else {
                    return subtotal - transaction.amountInCurrency
                }
            }
        }
    }
    
    private var sectionExpenseActual: Double {
        return sectionCategories.filter { $0.headCategory?.preferType == "EXPENSE" }.reduce(0) { total, category in
            let categoryTransactions = viewModel.transactions.filter { $0.category?.id == category.id }
            return total + categoryTransactions.reduce(0) { subtotal, transaction in
                // For expense categories, add expense transactions and subtract income transactions
                let transactionType = transaction.type ?? "EXPENSE"
                if transactionType == "EXPENSE" {
                    return subtotal + transaction.amountInCurrency
                } else {
                    return subtotal - transaction.amountInCurrency
                }
            }
        }
    }
    
    private var hasIncomeCategories: Bool {
        return sectionCategories.contains { $0.headCategory?.preferType == "INCOME" }
    }
    
    private var hasExpenseCategories: Bool {
        return sectionCategories.contains { $0.headCategory?.preferType == "EXPENSE" }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Header with Progress
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.name ?? "Unknown Section")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Income line (if section has income categories)
                            if hasIncomeCategories {
                                HStack(spacing: 12) {
                                    Text("💰 Income:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("$\(sectionIncomeActual, specifier: "%.0f") / $\(sectionIncomeTotal, specifier: "%.0f")")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    let incomeRemaining = sectionIncomeTotal - sectionIncomeActual
                                    if incomeRemaining < 0 {
                                        Text("Extra: $\(abs(incomeRemaining), specifier: "%.0f")")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else if incomeRemaining > 0 {
                                        Text("Left: $\(incomeRemaining, specifier: "%.0f")")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            
                            // Expense line (if section has expense categories)
                            if hasExpenseCategories {
                                HStack(spacing: 12) {
                                    Text("💸 Expense:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("$\(sectionExpenseActual, specifier: "%.0f") / $\(sectionExpenseTotal, specifier: "%.0f")")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    let expenseRemaining = sectionExpenseTotal - sectionExpenseActual
                                    Text("Remaining: $\(expenseRemaining, specifier: "%.0f")")
                                        .font(.caption)
                                        .foregroundColor(expenseRemaining >= 0 ? .green : .red)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Categories with Progress
            VStack(spacing: 8) {
                ForEach(sectionCategories, id: \.id) { category in
                    let capturedCategory = category // Capture category in local scope
                    CategoryRemainingCard(
                        category: capturedCategory,
                        viewModel: viewModel,
                        onAddTransaction: {
                            transactionSheetData = TransactionSheetData(category: capturedCategory)
                        },
                        onCategoryTapped: {
                            transactionListSheetData = TransactionListSheetData(category: capturedCategory)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(item: $transactionSheetData) { data in
            AddTransactionAmountSheet(
                viewModel: viewModel, 
                prefilledCategory: data.category
            )
        }
        .sheet(item: $transactionListSheetData) { data in
            CategoryTransactionListView(
                category: data.category,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Category Remaining Card

struct CategoryRemainingCard: View {
    let category: LocalCategory
    @ObservedObject var viewModel: BudgetViewModel
    let onAddTransaction: () -> Void
    let onCategoryTapped: () -> Void
    
    private var plannedAmount: Double {
        return viewModel.plans.filter { $0.category?.id == category.id }.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    private var actualAmount: Double {
        return viewModel.transactions.filter { $0.category?.id == category.id }.reduce(0) { total, transaction in
            // If transaction type matches category type, add as positive
            // If transaction type doesn't match (e.g., expense in income category), subtract
            let categoryType = category.headCategory?.preferType ?? "EXPENSE"
            let transactionType = transaction.type ?? "EXPENSE"
            
            if categoryType == transactionType {
                return total + transaction.amountInCurrency
            } else {
                // Opposite type - subtract the amount
                return total - transaction.amountInCurrency
            }
        }
    }
    
    private var isIncomeCategory: Bool {
        return category.headCategory?.preferType == "INCOME"
    }
    
    private var remainingAmount: Double {
        if isIncomeCategory {
            // For income: remaining = planned - earned (how much more income target to reach)
            return plannedAmount - actualAmount
        } else {
            // For expense: remaining = planned - spent (how much budget left)
            return plannedAmount - actualAmount
        }
    }
    
    
    private var progressPercentage: Double {
        guard plannedAmount > 0 else { return 0 }
        return min(actualAmount / plannedAmount, 1.0)
    }
    
    private var isOverBudget: Bool {
        if isIncomeCategory {
            // For income: "over budget" means earning LESS than planned (bad)
            return actualAmount < plannedAmount
        } else {
            // For expense: "over budget" means spending MORE than planned (bad)
            return actualAmount > plannedAmount
        }
    }
    
    private var isPerformingWell: Bool {
        if isIncomeCategory {
            // For income: performing well means earning MORE than planned
            return actualAmount >= plannedAmount
        } else {
            // For expense: performing well means spending LESS than planned
            return actualAmount <= plannedAmount
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon and info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color) ?? .gray)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: category.icon ?? "circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: onCategoryTapped) {
                        Text(category.name ?? "Unknown Category")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Progress info
                    HStack(spacing: 8) {
                        if isIncomeCategory {
                            Text("$\(actualAmount, specifier: "%.0f") / $\(plannedAmount, specifier: "%.0f") earned")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("$\(actualAmount, specifier: "%.0f") / $\(plannedAmount, specifier: "%.0f") spent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if plannedAmount > 0 {
                            Text("\(Int(progressPercentage * 100))%")
                                .font(.caption)
                                .foregroundColor(isPerformingWell ? .green : (isIncomeCategory ? .orange : .red))
                        }
                    }
                    
                    // Progress bar
                    if plannedAmount > 0 {
                        let progressColor: Color = {
                            if isIncomeCategory {
                                // Income: Green if earned >= planned, Orange if under target
                                return actualAmount >= plannedAmount ? .green : .orange
                            } else {
                                // Expense: Green if spent <= planned, Red if over budget
                                return actualAmount <= plannedAmount ? .green : .red
                            }
                        }()
                        
                        ProgressView(value: progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                            .scaleEffect(x: 1, y: 1.2, anchor: .center)
                    }
                }
            }
            
            Spacer()
            
            // Add transaction button
            Button(action: onAddTransaction) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke({
                    if isIncomeCategory {
                        // For income: Orange border if earning less than planned (underperforming)
                        return actualAmount < plannedAmount ? Color.orange.opacity(0.3) : Color.clear
                    } else {
                        // For expense: Red border if spending more than planned (over budget)
                        return actualAmount > plannedAmount ? Color.red.opacity(0.3) : Color.clear
                    }
                }(), lineWidth: 1)
        )
    }
}

// MARK: - Empty Remaining State

struct EmptyRemainingState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Budget Sections")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create sections in the Planning tab to start tracking your spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Category Transaction List View

struct CategoryTransactionListView: View {
    let category: LocalCategory
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingTransaction: LocalTransaction?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: LocalTransaction?
    
    private var categoryTransactions: [LocalTransaction] {
        viewModel.transactions
            .filter { $0.category?.id == category.id }
            .sorted { 
                // Sort by date (newest first)
                guard let date1 = $0.transactionDate, let date2 = $1.transactionDate else { return false }
                return date1 > date2
            }
    }
    
    private var isIncomeCategory: Bool {
        return category.headCategory?.preferType == "INCOME"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Summary Card
                VStack(spacing: 16) {
                    // Budget and Period Info
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(viewModel.currentBudget?.name ?? "Budget")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                            if let period = viewModel.currentPeriod {
                                Label(period.name ?? "Period", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Category Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: category.color) ?? .gray,
                                        (Color(hex: category.color) ?? .gray).opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                                .shadow(color: (Color(hex: category.color) ?? .gray).opacity(0.3), radius: 5, x: 0, y: 2)
                            
                            Image(systemName: category.icon ?? "circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category.name ?? "Unknown Category")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Label(
                                    isIncomeCategory ? "Income" : "Expense",
                                    systemImage: isIncomeCategory ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
                                )
                                .font(.caption)
                                .foregroundColor(isIncomeCategory ? .green : .orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isIncomeCategory ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                
                                if let headCategory = category.headCategory?.name {
                                    Text(headCategory)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Statistics Cards
                    HStack(spacing: 12) {
                        // Transaction Count Card
                        VStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("\(categoryTransactions.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Transactions")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Total Amount Card
                        VStack(spacing: 8) {
                            Image(systemName: isIncomeCategory ? "dollarsign.circle.fill" : "creditcard.fill")
                                .font(.title3)
                                .foregroundColor(isIncomeCategory ? .green : .blue)
                            let totalAmount = categoryTransactions.reduce(0) { total, transaction in
                                // Calculate net amount considering transaction type vs category type
                                let categoryType = category.headCategory?.preferType ?? "EXPENSE"
                                let transactionType = transaction.type ?? "EXPENSE"
                                
                                if categoryType == transactionType {
                                    return total + transaction.amountInCurrency
                                } else {
                                    return total - transaction.amountInCurrency
                                }
                            }
                            Text("$\(totalAmount, specifier: "%.0f")")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(isIncomeCategory ? .green : .blue)
                            Text(isIncomeCategory ? "Net Earned" : "Net Spent")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Average Card
                        if categoryTransactions.count > 0 {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                let netTotal = categoryTransactions.reduce(0) { total, transaction in
                                    let categoryType = category.headCategory?.preferType ?? "EXPENSE"
                                    let transactionType = transaction.type ?? "EXPENSE"
                                    
                                    if categoryType == transactionType {
                                        return total + transaction.amountInCurrency
                                    } else {
                                        return total - transaction.amountInCurrency
                                    }
                                }
                                let avgAmount = netTotal / Double(categoryTransactions.count)
                                Text("$\(avgAmount, specifier: "%.0f")")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Text("Average")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6).opacity(0.3),
                            Color(.systemGray6).opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Transaction List
                if categoryTransactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("No Transactions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("No transactions found for this category in the current period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                } else {
                    List {
                        ForEach(categoryTransactions, id: \.id) { transaction in
                            TransactionRowView(
                                transaction: transaction,
                                isIncomeCategory: isIncomeCategory,
                                onEdit: {
                                    editingTransaction = transaction
                                    showingEditSheet = true
                                },
                                onDelete: {
                                    transactionToDelete = transaction
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let transaction = editingTransaction {
                EditTransactionSheet(
                    transaction: transaction,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    deleteTransaction(transaction)
                }
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
    }
    
    private func deleteTransaction(_ transaction: LocalTransaction) {
        Task {
            do {
                try await viewModel.deleteTransaction(transaction)
            } catch {
            }
        }
    }
}

// MARK: - Transaction Row View

struct TransactionRowView: View {
    let transaction: LocalTransaction
    let isIncomeCategory: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var transactionDate: Date {
        guard let dateString = transaction.transactionDate else { return Date() }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
    
    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: transactionDate)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Date and amount
            VStack(alignment: .leading, spacing: 4) {
                Text(displayDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                // Check if transaction type matches category type
                let categoryType = isIncomeCategory ? "INCOME" : "EXPENSE"
                let transactionType = transaction.type ?? "EXPENSE"
                let isOppositeType = categoryType != transactionType
                
                HStack(spacing: 4) {
                    if isOppositeType {
                        Image(systemName: "minus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Text("$\(transaction.amountInCurrency, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isOppositeType ? .red : (isIncomeCategory ? .green : .primary))
                        .strikethrough(isOppositeType, color: .red.opacity(0.5))
                }
                
                // Edit and Delete buttons with better tap areas
                HStack(spacing: 16) {
                    Button(action: {
                        onEdit()
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Edit Transaction Sheet

struct EditTransactionSheet: View {
    let transaction: LocalTransaction
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: LocalCategory?
    @State private var amount: String = ""
    @State private var selectedType: String = "EXPENSE"
    @State private var transactionDate = Date()
    @State private var notes: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCategoryPicker = false
    @FocusState private var isAmountFieldFocused: Bool
    
    private var availableCategories: [LocalCategory] {
        // Show all categories regardless of type - user can choose any category with any type
        return viewModel.incomeCategories + viewModel.expenseCategories
    }
    
    private var groupedCategories: [LocalHeadCategory: [LocalCategory]] {
        let categories = availableCategories
        let validCategories = categories.compactMap { category -> (LocalHeadCategory, LocalCategory)? in
            guard let headCategory = category.headCategory else { return nil }
            return (headCategory, category)
        }
        return Dictionary(grouping: validCategories) { $0.0 }
            .mapValues { $0.map { $0.1 } }
    }
    
    private var isValidInput: Bool {
        guard let category = selectedCategory, !amount.isEmpty else { return false }
        guard let amountDouble = Double(amount), amountDouble > 0 else { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Amount at top - big, no label, centered
                VStack(spacing: 8) {
                    TextField("0", text: $amount)
                        .font(.system(size: 48, weight: .light))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                Form {
                    // Category section
                    Section {
                        Button(action: {
                            showingCategoryPicker = true
                        }) {
                            HStack {
                                if let category = selectedCategory {
                                    Image(systemName: category.icon ?? "circle.fill")
                                        .foregroundColor(Color(hex: category.color) ?? .gray)
                                        .frame(width: 30)
                                    
                                    Text(category.name ?? "Unknown")
                                        .foregroundColor(.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                        .frame(width: 30)
                                    
                                    Text("Select Category")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("Category")
                    }
                    
                    // Date section
                    Section {
                        DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                    } header: {
                        Text("Date")
                    }
                    
                    // Notes section
                    Section {
                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes (Optional)")
                    }
                    
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        await saveTransaction()
                    }
                }
                .disabled(!isValidInput || isLoading)
            )
        }
        .onAppear {
            // Pre-fill all the fields with existing transaction data
            selectedCategory = transaction.category
            amount = String(format: "%.0f", transaction.amountInCurrency)
            selectedType = transaction.type ?? "EXPENSE"
            notes = transaction.notes ?? ""
            
            if let dateString = transaction.transactionDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                transactionDate = formatter.date(from: dateString) ?? Date()
            }
            
            isAmountFieldFocused = true
        }
        .sheet(isPresented: $showingCategoryPicker) {
            TransactionCategoryPickerView(
                categories: groupedCategories,
                selectedCategory: $selectedCategory,
                isPresented: $showingCategoryPicker
            )
        }
    }
    
    private func saveTransaction() async {
        guard let category = selectedCategory,
              let amountDouble = Double(amount), amountDouble > 0 else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Update the transaction with new values
            guard let categoryId = category.id else {
                errorMessage = "Invalid category selected"
                isLoading = false
                return
            }
            
            try await viewModel.updateTransaction(
                transaction,
                amount: amountDouble,
                date: transactionDate,
                notes: notes.isEmpty ? nil : notes,
                categoryId: categoryId
            )
            dismiss()
        } catch {
            errorMessage = "Failed to update transaction: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
