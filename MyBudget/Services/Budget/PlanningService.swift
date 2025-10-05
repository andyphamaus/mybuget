import Foundation
import CoreData
import Combine

@MainActor
class PlanningService: ObservableObject {
    @Published var plans: [LocalBudgetPeriodPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPlans()
    }
    
    // MARK: - Data Loading
    
    func loadPlans(for periodId: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalBudgetPeriodPlan> = LocalBudgetPeriodPlan.fetchRequest()
        
        if let periodId = periodId {
            request.predicate = NSPredicate(format: "period.id == %@", periodId)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.headCategory.displayOrder", ascending: true),
            NSSortDescriptor(key: "category.displayOrder", ascending: true)
        ]
        
        do {
            let fetchedPlans = try context.fetch(request)
            _ = plans.count
            plans = fetchedPlans
            
            
            // Force UI update notification
            objectWillChange.send()
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load plans: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Planning Operations
    
    func createOrUpdatePlan(periodId: String, categoryId: String, type: String, amount: Double, notes: String? = nil) throws -> LocalBudgetPeriodPlan {
        let context = persistenceController.viewContext
        
        // Find existing plan
        let existingPlan = try getExistingPlan(periodId: periodId, categoryId: categoryId)
        
        if let existingPlan = existingPlan {
            // Update existing plan
            existingPlan.type = type
            existingPlan.setAmount(amount)
            existingPlan.notes = notes
            existingPlan.updatedAt = Date()
            
            do {
                try context.save()
                
                // Log activity
                LocalActivity.logBudgetActivity(
                    context: context,
                    action: "budget_updated",
                    title: "Updated plan for \(existingPlan.category?.name ?? "")",
                    description: "Plan amount updated",
                    amount: String(format: "%.2f", amount)
                )
                
                // Force UI update on main thread
                Task { @MainActor in
                    self.loadPlans(for: periodId)
                    // Force publish notification
                    self.objectWillChange.send()
                }
                
                return existingPlan
            } catch {
                throw PlanningError.failedToUpdate(error.localizedDescription)
            }
        } else {
            // Create new plan
            let plan = LocalBudgetPeriodPlan.create(in: context)
            
            // Set relationships
            let periodRequest: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
            periodRequest.predicate = NSPredicate(format: "id == %@", periodId)
            guard let period = try context.fetch(periodRequest).first else {
                throw PlanningError.periodNotFound
            }
            
            let categoryRequest: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId)
            guard let category = try context.fetch(categoryRequest).first else {
                throw PlanningError.categoryNotFound
            }
            
            plan.period = period
            plan.category = category
            plan.type = type
            plan.setAmount(amount)
            plan.notes = notes
            
            do {
                try context.save()
                
                // Log activity
                LocalActivity.logBudgetActivity(
                    context: context,
                    action: "budget_created",
                    title: "Created plan for \(category.name ?? "")",
                    description: "New budget plan created",
                    amount: String(format: "%.2f", amount)
                )
                
                // Force UI update on main thread
                Task { @MainActor in
                    self.loadPlans(for: periodId)
                    // Force publish notification
                    self.objectWillChange.send()
                }
                
                return plan
            } catch {
                throw PlanningError.failedToCreate(error.localizedDescription)
            }
        }
    }
    
    private func getExistingPlan(periodId: String, categoryId: String) throws -> LocalBudgetPeriodPlan? {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalBudgetPeriodPlan> = LocalBudgetPeriodPlan.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@ AND category.id == %@", periodId, categoryId)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    func getPlan(id: String) -> LocalBudgetPeriodPlan? {
        return plans.first { $0.id == id }
    }
    
    func getPlans(for periodId: String) -> [LocalBudgetPeriodPlan] {
        return LocalBudgetPeriodPlan.fetchPlans(for: periodId, in: persistenceController.viewContext)
    }
    
    func getPlans(ofType type: String, for periodId: String) -> [LocalBudgetPeriodPlan] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalBudgetPeriodPlan> = LocalBudgetPeriodPlan.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@ AND type == %@", periodId, type)
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.headCategory.displayOrder", ascending: true),
            NSSortDescriptor(key: "category.displayOrder", ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch plans by type: \(error.localizedDescription)"
            return []
        }
    }
    
    func deletePlan(_ plan: LocalBudgetPeriodPlan) throws {
        let context = persistenceController.viewContext
        let periodId = plan.period?.id
        
        context.delete(plan)
        
        do {
            try context.save()
            loadPlans(for: periodId)
        } catch {
            throw PlanningError.failedToDelete(error.localizedDescription)
        }
    }
    
    // MARK: - Planning Analysis
    
    func getPlanningSummary(for periodId: String) throws -> PlanningSummary {
        let plans = getPlans(for: periodId)
        
        let incomePlans = plans.filter { $0.type == "INCOME" }
        let expensePlans = plans.filter { $0.type == "EXPENSE" }
        
        let totalPlannedIncome = incomePlans.reduce(0.0) { $0 + $1.amountInCurrency }
        let totalPlannedExpense = expensePlans.reduce(0.0) { $0 + $1.amountInCurrency }
        
        return PlanningSummary(
            periodId: periodId,
            totalPlannedIncome: totalPlannedIncome,
            totalPlannedExpense: totalPlannedExpense,
            netPlannedAmount: totalPlannedIncome - totalPlannedExpense,
            incomeCategoriesCount: incomePlans.count,
            expenseCategoriesCount: expensePlans.count,
            totalCategoriesPlanned: plans.count
        )
    }
    
    func getPlanningComparison(for periodId: String) throws -> [PlanningComparison] {
        let plans = getPlans(for: periodId)
        let transactionService = TransactionService()
        
        var comparisons: [PlanningComparison] = []
        
        for plan in plans {
            guard let categoryId = plan.category?.id else { continue }
            
            // Get actual transactions for this category
            let transactions = transactionService.getTransactions(categoryId: categoryId, periodId: periodId)
            let actualAmount = transactionService.getTotalAmount(transactions: transactions)
            
            let plannedAmount = plan.amountInCurrency
            let difference = plannedAmount - actualAmount
            let percentageUsed: Double
            if plannedAmount > 0 && !actualAmount.isNaN && !plannedAmount.isNaN {
                percentageUsed = (actualAmount / plannedAmount) * 100
            } else {
                percentageUsed = 0
            }
            
            // FIXED: Handle income vs expense logic properly
            var isOverBudget: Bool
            let type = plan.type ?? ""
            if type == "INCOME" {
                // For income: actualAmount < plannedAmount = under target (bad)
                isOverBudget = actualAmount < plannedAmount
            } else {
                // For expense: actualAmount > plannedAmount = over budget (bad)  
                isOverBudget = actualAmount > plannedAmount
            }
            
            comparisons.append(PlanningComparison(
                categoryId: categoryId,
                categoryName: plan.category?.name ?? "",
                categoryIcon: plan.category?.icon,
                categoryColor: plan.category?.color,
                type: plan.type ?? "",
                plannedAmount: plannedAmount,
                actualAmount: actualAmount,
                remainingAmount: difference,
                percentageUsed: percentageUsed,
                isOverBudget: isOverBudget,
                transactionCount: transactions.count
            ))
        }
        
        return comparisons.sorted { $0.categoryName < $1.categoryName }
    }
    
    func getPlanningTrends(for budgetId: String, last numberOfPeriods: Int = 6) throws -> [PlanningTrend] {
        let context = persistenceController.viewContext
        let budgetRequest: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        budgetRequest.predicate = NSPredicate(format: "budget.id == %@", budgetId)
        budgetRequest.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: false)]
        budgetRequest.fetchLimit = numberOfPeriods
        
        let periods = try context.fetch(budgetRequest).reversed() // Chronological order
        var trends: [PlanningTrend] = []
        
        for period in periods {
            let summary = try getPlanningSummary(for: period.id!)
            
            trends.append(PlanningTrend(
                periodId: period.id!,
                periodName: period.name ?? "",
                startDate: period.startDate ?? "",
                endDate: period.endDate ?? "",
                plannedIncome: summary.totalPlannedIncome,
                plannedExpense: summary.totalPlannedExpense,
                netPlanned: summary.netPlannedAmount,
                categoriesPlanned: summary.totalCategoriesPlanned
            ))
        }
        
        return trends
    }
    
    func copyPlanning(from sourcePeriodId: String, to targetPeriodId: String) throws -> Int {
        let sourcePlans = getPlans(for: sourcePeriodId)
        var copiedCount = 0
        
        for sourcePlan in sourcePlans {
            guard let categoryId = sourcePlan.category?.id else { continue }
            
            // Check if plan already exists for target period
            if try getExistingPlan(periodId: targetPeriodId, categoryId: categoryId) != nil {
                continue // Skip if already exists
            }
            
            // Copy plan
            _ = try createOrUpdatePlan(
                periodId: targetPeriodId,
                categoryId: categoryId,
                type: sourcePlan.type ?? "EXPENSE",
                amount: sourcePlan.amountInCurrency,
                notes: sourcePlan.notes
            )
            
            copiedCount += 1
        }
        
        return copiedCount
    }
    
    func getPlanningSuggestions(for periodId: String, basedOnLast numberOfPeriods: Int = 3) throws -> [PlanningSuggestion] {
        let context = persistenceController.viewContext
        
        // Get budget for this period
        let periodRequest: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        periodRequest.predicate = NSPredicate(format: "id == %@", periodId)
        guard let period = try context.fetch(periodRequest).first,
              let budgetId = period.budget?.id else {
            return []
        }
        
        // Get recent periods
        let recentPeriodsRequest: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        recentPeriodsRequest.predicate = NSPredicate(format: "budget.id == %@ AND id != %@ AND status != %@", budgetId, periodId, "ARCHIVED")
        recentPeriodsRequest.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: false)]
        recentPeriodsRequest.fetchLimit = numberOfPeriods
        
        let recentPeriods = try context.fetch(recentPeriodsRequest)
        if recentPeriods.isEmpty { return [] }
        
        let transactionService = TransactionService()
        var suggestions: [PlanningSuggestion] = []
        
        // Group all transactions by category across recent periods
        var categoryTransactions: [String: [LocalTransaction]] = [:]
        
        for recentPeriod in recentPeriods {
            let transactions = transactionService.getTransactions(for: recentPeriod.id!)
            
            for transaction in transactions {
                guard let categoryId = transaction.category?.id else { continue }
                
                if categoryTransactions[categoryId] == nil {
                    categoryTransactions[categoryId] = []
                }
                categoryTransactions[categoryId]?.append(transaction)
            }
        }
        
        // Generate suggestions
        for (categoryId, transactions) in categoryTransactions {
            guard let firstTransaction = transactions.first,
                  let category = firstTransaction.category else { continue }
            
            let totalAmount = transactionService.getTotalAmount(transactions: transactions)
            let periodCount = Double(recentPeriods.count)
            let averageAmount = periodCount > 0 ? totalAmount / periodCount : 0
            let frequency = periodCount > 0 ? Double(transactions.count) / periodCount : 0
            
            // Only suggest if there's consistent usage
            if frequency >= 0.5 && averageAmount > 0 {
                suggestions.append(PlanningSuggestion(
                    categoryId: categoryId,
                    categoryName: category.name ?? "",
                    categoryIcon: category.icon,
                    categoryColor: category.color,
                    suggestedType: category.preferredType,
                    suggestedAmount: averageAmount,
                    confidence: min(frequency, 1.0),
                    basedOnTransactions: transactions.count,
                    historicalAverage: averageAmount
                ))
            }
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
}

// MARK: - Supporting Models

struct PlanningSummary {
    let periodId: String
    let totalPlannedIncome: Double
    let totalPlannedExpense: Double
    let netPlannedAmount: Double
    let incomeCategoriesCount: Int
    let expenseCategoriesCount: Int
    let totalCategoriesPlanned: Int
    
    var plannedSavingsRate: Double {
        guard totalPlannedIncome > 0 && !netPlannedAmount.isNaN && !totalPlannedIncome.isNaN else {
            return 0
        }
        return (netPlannedAmount / totalPlannedIncome) * 100
    }
}

struct PlanningComparison {
    let categoryId: String
    let categoryName: String
    let categoryIcon: String?
    let categoryColor: String?
    let type: String
    let plannedAmount: Double
    let actualAmount: Double
    let remainingAmount: Double
    let percentageUsed: Double
    let isOverBudget: Bool
    let transactionCount: Int
    
    var status: PlanningStatus {
        if isOverBudget {
            return .overBudget
        } else if percentageUsed < 50 {
            return .underUsed
        } else if percentageUsed >= 90 {
            return .nearBudget
        } else {
            return .onTrack
        }
    }
}

enum PlanningStatus {
    case onTrack
    case underUsed
    case nearBudget
    case overBudget
}

struct PlanningTrend {
    let periodId: String
    let periodName: String
    let startDate: String
    let endDate: String
    let plannedIncome: Double
    let plannedExpense: Double
    let netPlanned: Double
    let categoriesPlanned: Int
}

struct PlanningSuggestion {
    let categoryId: String
    let categoryName: String
    let categoryIcon: String?
    let categoryColor: String?
    let suggestedType: String
    let suggestedAmount: Double
    let confidence: Double // 0.0 to 1.0
    let basedOnTransactions: Int
    let historicalAverage: Double
}

// MARK: - Error Types

enum PlanningError: LocalizedError {
    case failedToCreate(String)
    case failedToUpdate(String)
    case failedToDelete(String)
    case periodNotFound
    case categoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedToCreate(let message):
            return "Failed to create plan: \(message)"
        case .failedToUpdate(let message):
            return "Failed to update plan: \(message)"
        case .failedToDelete(let message):
            return "Failed to delete plan: \(message)"
        case .periodNotFound:
            return "Period not found"
        case .categoryNotFound:
            return "Category not found"
        }
    }
}