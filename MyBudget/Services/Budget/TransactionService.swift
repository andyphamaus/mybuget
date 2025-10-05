import Foundation
import CoreData
import Combine

@MainActor
class TransactionService: ObservableObject {
    @Published var transactions: [LocalTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTransactions()
    }
    
    // MARK: - Data Loading
    
    func loadTransactions(for periodId: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        
        if let periodId = periodId {
            request.predicate = NSPredicate(format: "period.id == %@", periodId)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        
        do {
            let fetchedTransactions = try context.fetch(request)
            transactions = fetchedTransactions
            isLoading = false
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Transaction Operations
    
    func createTransaction(budgetId: String, periodId: String, categoryId: String, type: String, amount: Double, date: Date, notes: String? = nil) throws -> LocalTransaction {
        let context = persistenceController.viewContext
        
        // Validate budget exists
        let budgetRequest: NSFetchRequest<LocalBudget> = LocalBudget.fetchRequest()
        budgetRequest.predicate = NSPredicate(format: "id == %@", budgetId)
        guard let budget = try context.fetch(budgetRequest).first else {
            throw TransactionError.budgetNotFound
        }
        
        // Validate period exists
        let periodRequest: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        periodRequest.predicate = NSPredicate(format: "id == %@", periodId)
        guard let period = try context.fetch(periodRequest).first else {
            throw TransactionError.periodNotFound
        }
        
        // Validate category exists
        let categoryRequest: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId)
        guard let category = try context.fetch(categoryRequest).first else {
            throw TransactionError.categoryNotFound
        }
        
        // Create transaction
        let transaction = LocalTransaction.create(in: context)
        transaction.budget = budget
        transaction.period = period
        transaction.category = category
        transaction.type = type
        transaction.setAmount(amount)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        transaction.transactionDate = dateFormatter.string(from: date)
        transaction.notes = notes
        
        do {
            try context.save()
            
            // Log activity
            LocalActivity.logBudgetActivity(
                context: context,
                action: "transaction_added",
                title: "\(type == "income" ? "Income" : "Expense"): \(category.name ?? "")",
                description: notes,
                amount: String(format: "%.2f", amount)
            )
            
            loadTransactions(for: periodId)
            return transaction
        } catch {
            throw TransactionError.failedToCreate(error.localizedDescription)
        }
    }
    
    func getTransaction(id: String) -> LocalTransaction? {
        return transactions.first { $0.id == id }
    }
    
    func getTransactions(for periodId: String) -> [LocalTransaction] {
        return LocalTransaction.fetchTransactions(for: periodId, in: persistenceController.viewContext)
    }
    
    func getTransactions(categoryId: String, periodId: String) -> [LocalTransaction] {
        return LocalTransaction.fetchTransactions(categoryId: categoryId, periodId: periodId, in: persistenceController.viewContext)
    }
    
    func getTransactions(for budgetId: String, limit: Int? = nil) -> [LocalTransaction] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "budget.id == %@", budgetId)
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch transactions: \(error.localizedDescription)"
            return []
        }
    }
    
    func getTransactions(ofType type: String, for periodId: String) -> [LocalTransaction] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND period.id == %@", type, periodId)
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch transactions by type: \(error.localizedDescription)"
            return []
        }
    }
    
    func updateTransaction(_ transaction: LocalTransaction, amount: Double?, date: Date?, notes: String?, categoryId: String?) throws {
        let context = persistenceController.viewContext
        
        if let amount = amount {
            transaction.setAmount(amount)
        }
        
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            transaction.transactionDate = dateFormatter.string(from: date)
        }
        
        if let notes = notes {
            transaction.notes = notes
        }
        
        if let categoryId = categoryId {
            let categoryRequest: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId)
            if let category = try context.fetch(categoryRequest).first {
                transaction.category = category
            }
        }
        
        transaction.updatedAt = Date()
        
        do {
            try context.save()
            loadTransactions(for: transaction.period?.id)
        } catch {
            throw TransactionError.failedToUpdate(error.localizedDescription)
        }
    }
    
    func deleteTransaction(_ transaction: LocalTransaction) throws {
        let context = persistenceController.viewContext
        let periodId = transaction.period?.id
        
        context.delete(transaction)
        
        do {
            try context.save()
            loadTransactions(for: periodId)
        } catch {
            throw TransactionError.failedToDelete(error.localizedDescription)
        }
    }
    
    // MARK: - Analytics & Aggregation
    
    func getTotalAmount(transactions: [LocalTransaction]) -> Double {
        let totalCents = LocalTransaction.calculateTotal(transactions: transactions)
        return Double(totalCents) / 100.0
    }
    
    func groupTransactionsByType(transactions: [LocalTransaction]) -> (income: [LocalTransaction], expense: [LocalTransaction]) {
        return LocalTransaction.groupByType(transactions: transactions)
    }
    
    func getSpendingByCategory(for periodId: String) -> [CategorySpending] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@ AND type == %@", periodId, "EXPENSE")
        
        do {
            let transactions = try context.fetch(request)
            
            // Group by category
            let groupedTransactions = Dictionary(grouping: transactions) { transaction in
                transaction.category?.id ?? ""
            }
            
            var categorySpending: [CategorySpending] = []
            
            for (categoryId, categoryTransactions) in groupedTransactions {
                guard let category = categoryTransactions.first?.category else { continue }
                
                let totalAmount = getTotalAmount(transactions: categoryTransactions)
                let transactionCount = categoryTransactions.count
                
                categorySpending.append(CategorySpending(
                    categoryId: categoryId,
                    categoryName: category.name ?? "",
                    categoryIcon: category.icon,
                    categoryColor: category.color,
                    totalAmount: totalAmount,
                    transactionCount: transactionCount,
                    transactions: categoryTransactions
                ))
            }
            
            return categorySpending.sorted { $0.totalAmount > $1.totalAmount }
        } catch {
            errorMessage = "Failed to get spending by category: \(error.localizedDescription)"
            return []
        }
    }
    
    func getSpendingTrends(for budgetId: String, last numberOfPeriods: Int = 6) -> [PeriodSpending] {
        let context = persistenceController.viewContext
        let budgetRequest: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        budgetRequest.predicate = NSPredicate(format: "budget.id == %@", budgetId)
        budgetRequest.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: false)]
        budgetRequest.fetchLimit = numberOfPeriods
        
        do {
            let periods = try context.fetch(budgetRequest)
            var periodSpending: [PeriodSpending] = []
            
            for period in periods {
                let transactions = getTransactions(for: period.id!)
                let (income, expense) = groupTransactionsByType(transactions: transactions)
                
                periodSpending.append(PeriodSpending(
                    periodId: period.id!,
                    periodName: period.name ?? "",
                    startDate: period.startDate ?? "",
                    endDate: period.endDate ?? "",
                    totalIncome: getTotalAmount(transactions: income),
                    totalExpense: getTotalAmount(transactions: expense),
                    netAmount: getTotalAmount(transactions: income) - getTotalAmount(transactions: expense),
                    transactionCount: transactions.count
                ))
            }
            
            return periodSpending.reversed() // Return chronological order
        } catch {
            errorMessage = "Failed to get spending trends: \(error.localizedDescription)"
            return []
        }
    }
    
    func searchTransactions(query: String, budgetId: String, limit: Int = 50) -> [LocalTransaction] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "budget.id == %@ AND (notes CONTAINS[c] %@ OR category.name CONTAINS[c] %@)", budgetId, query, query)
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            errorMessage = "Failed to search transactions: \(error.localizedDescription)"
            return []
        }
    }
    
}

// MARK: - Supporting Models

struct CategorySpending {
    let categoryId: String
    let categoryName: String
    let categoryIcon: String?
    let categoryColor: String?
    let totalAmount: Double
    let transactionCount: Int
    let transactions: [LocalTransaction]
    
    var averageAmount: Double {
        return transactionCount > 0 ? totalAmount / Double(transactionCount) : 0
    }
}

struct PeriodSpending {
    let periodId: String
    let periodName: String
    let startDate: String
    let endDate: String
    let totalIncome: Double
    let totalExpense: Double
    let netAmount: Double
    let transactionCount: Int
    
    var isPositive: Bool {
        return netAmount >= 0
    }
}

// MARK: - Error Types

enum TransactionError: LocalizedError {
    case failedToCreate(String)
    case failedToUpdate(String)
    case failedToDelete(String)
    case budgetNotFound
    case periodNotFound
    case categoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedToCreate(let message):
            return "Failed to create transaction: \(message)"
        case .failedToUpdate(let message):
            return "Failed to update transaction: \(message)"
        case .failedToDelete(let message):
            return "Failed to delete transaction: \(message)"
        case .budgetNotFound:
            return "Budget not found"
        case .periodNotFound:
            return "Period not found"
        case .categoryNotFound:
            return "Category not found"
        }
    }
}