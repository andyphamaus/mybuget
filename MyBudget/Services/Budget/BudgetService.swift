import Foundation
import CoreData
import Combine

@MainActor
class BudgetService: ObservableObject {
    @Published var budgets: [LocalBudget] = []
    @Published var currentBudget: LocalBudget?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadBudgets()
    }
    
    // MARK: - Data Loading
    
    func loadBudgets(for userId: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalBudget> = LocalBudget.fetchRequest()
        
        if let userId = userId {
            request.predicate = NSPredicate(format: "userId == %@", userId)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let fetchedBudgets = try context.fetch(request)
            budgets = fetchedBudgets
            
            // Set current budget to the first active one
            if currentBudget == nil {
                currentBudget = fetchedBudgets.first
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load budgets: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Budget Operations
    
    func createBudget(userId: String, name: String, icon: String? = nil, color: String? = nil, currencyCode: String = "AUD") throws -> LocalBudget {
        let context = persistenceController.viewContext
        let budget = LocalBudget.create(in: context)
        
        budget.userId = userId
        budget.name = name
        budget.icon = icon
        budget.color = color
        budget.currencyCode = currencyCode
        
        do {
            try context.save()
            
            // Set as current budget if it's the first one
            if currentBudget == nil {
                currentBudget = budget
            }
            
            loadBudgets(for: userId)
            return budget
        } catch {
            throw BudgetError.failedToCreate(error.localizedDescription)
        }
    }
    
    func updateBudget(_ budget: LocalBudget, name: String?, icon: String?, color: String?, currencyCode: String?) throws {
        let context = persistenceController.viewContext
        
        if let name = name { budget.name = name }
        if let icon = icon { budget.icon = icon }
        if let color = color { budget.color = color }
        if let currencyCode = currencyCode { budget.currencyCode = currencyCode }
        
        do {
            try context.save()
            loadBudgets(for: budget.userId)
        } catch {
            throw BudgetError.failedToUpdate(error.localizedDescription)
        }
    }
    
    func deleteBudget(_ budget: LocalBudget) throws {
        let context = persistenceController.viewContext
        let userId = budget.userId
        
        // Clear current budget if this is the one being deleted
        if currentBudget?.id == budget.id {
            currentBudget = nil
        }
        
        context.delete(budget)
        
        do {
            try context.save()
            loadBudgets(for: userId)
        } catch {
            throw BudgetError.failedToDelete(error.localizedDescription)
        }
    }
    
    // MARK: - Period Operations
    
    func createPeriod(for budget: LocalBudget, type: String, startDate: Date, endDate: Date) throws -> LocalBudgetPeriod {
        let context = persistenceController.viewContext
        
        do {
            let period = try budget.createPeriod(type: type, startDate: startDate, endDate: endDate, in: context)
            try context.save()
            loadBudgets(for: budget.userId)
            return period
        } catch {
            throw BudgetError.failedToCreatePeriod(error.localizedDescription)
        }
    }
    
    func getCurrentPeriod(for budget: LocalBudget) -> LocalBudgetPeriod? {
        guard let budgetId = budget.id else {
            return nil
        }
        return LocalBudgetPeriod.fetchCurrentPeriod(for: budgetId, in: persistenceController.viewContext)
    }
    
    func getAllPeriods(for budget: LocalBudget) -> [LocalBudgetPeriod] {
        guard let budgetId = budget.id else {
            return []
        }
        return LocalBudgetPeriod.fetchAllPeriods(for: budgetId, in: persistenceController.viewContext)
    }
    
    func updatePeriodStatus(_ period: LocalBudgetPeriod, status: String) throws {
        let context = persistenceController.viewContext
        period.status = status
        
        do {
            try context.save()
            if let budgetUserId = period.budget?.userId {
                loadBudgets(for: budgetUserId)
            }
        } catch {
            throw BudgetError.failedToUpdatePeriod(error.localizedDescription)
        }
    }
    
    // MARK: - Period Section Operations (New Structure)
    
    func createPeriodSection(for period: LocalBudgetPeriod, name: String, typeHint: String?, displayOrder: Int = 0) throws -> LocalPeriodSection {
        let context = persistenceController.viewContext
        let section = LocalPeriodSection.create(in: context)
        
        section.period = period
        section.name = name
        section.displayOrder = Int32(displayOrder)
        
        do {
            try context.save()
            if let budgetUserId = period.budget?.userId {
                loadBudgets(for: budgetUserId)
            }
            return section
        } catch {
            throw BudgetError.failedToCreateSection(error.localizedDescription)
        }
    }
    
    func getPeriodSections(for period: LocalBudgetPeriod) -> [LocalPeriodSection] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalPeriodSection> = LocalPeriodSection.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@", period.id!)
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            // Failed to fetch period sections
            return []
        }
    }
    
    func updatePeriodSection(_ section: LocalPeriodSection, name: String?, displayOrder: Int?) throws {
        let context = persistenceController.viewContext
        
        if let name = name { section.name = name }
        if let displayOrder = displayOrder { section.displayOrder = Int32(displayOrder) }
        
        do {
            try context.save()
            if let budgetUserId = section.period?.budget?.userId {
                loadBudgets(for: budgetUserId)
            }
        } catch {
            throw BudgetError.failedToUpdateSection(error.localizedDescription)
        }
    }
    
    func addCategoryToPeriodSection(sectionId: String, categoryId: String, displayOrder: Int32) throws {
        let context = persistenceController.viewContext
        
        // Find section
        let sectionRequest: NSFetchRequest<LocalPeriodSection> = LocalPeriodSection.fetchRequest()
        sectionRequest.predicate = NSPredicate(format: "id == %@", sectionId)
        guard let section = try context.fetch(sectionRequest).first else {
            throw BudgetError.sectionNotFound
        }
        
        // Find category
        let categoryRequest: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId)
        guard let category = try context.fetch(categoryRequest).first else {
            throw BudgetError.categoryNotFound
        }
        
        // Remove category from other sections in this period first (ensure uniqueness)
        let otherMappingRequest: NSFetchRequest<LocalPeriodSectionCategory> = LocalPeriodSectionCategory.fetchRequest()
        otherMappingRequest.predicate = NSPredicate(format: "section.period.id == %@ AND category.id == %@", section.period!.id!, categoryId)
        let existingMappings = try context.fetch(otherMappingRequest)
        
        for existingMapping in existingMappings {
            context.delete(existingMapping)
        }
        
        // Create new mapping
        let mapping = LocalPeriodSectionCategory.create(in: context)
        mapping.section = section
        mapping.category = category
        mapping.displayOrder = displayOrder
        
        do {
            try context.save()
        } catch {
            throw BudgetError.failedToAddCategoryToSection(error.localizedDescription)
        }
    }
    
    // MARK: - Legacy Section Operations (Old Structure - Deprecated)
    
    func createSection(for budget: LocalBudget, name: String, typeHint: String?, displayOrder: Int = 0) throws -> LocalBudgetSection {
        let context = persistenceController.viewContext
        let section = LocalBudgetSection.create(in: context)
        
        section.budget = budget
        section.name = name
        section.typeHint = typeHint
        section.displayOrder = Int32(displayOrder)
        
        do {
            try context.save()
            loadBudgets(for: budget.userId)
            return section
        } catch {
            throw BudgetError.failedToCreateSection(error.localizedDescription)
        }
    }
    
    func getSections(for budget: LocalBudget) -> [LocalPeriodSection] {
        // Get current period for the budget
        guard let currentPeriod = getCurrentPeriod(for: budget) else { return [] }
        return LocalPeriodSection.fetchSections(for: currentPeriod.id!, in: persistenceController.viewContext)
    }
    
    func updateSection(_ section: LocalBudgetSection, name: String?, displayOrder: Int?, typeHint: String?) throws {
        let context = persistenceController.viewContext
        
        if let name = name { section.name = name }
        if let displayOrder = displayOrder { section.displayOrder = Int32(displayOrder) }
        if let typeHint = typeHint { section.typeHint = typeHint }
        
        do {
            try context.save()
            if let budgetUserId = section.budget?.userId {
                loadBudgets(for: budgetUserId)
            }
        } catch {
            throw BudgetError.failedToUpdateSection(error.localizedDescription)
        }
    }
    
    func deleteSection(_ section: LocalBudgetSection) throws {
        let context = persistenceController.viewContext
        let budgetUserId = section.budget?.userId
        
        context.delete(section)
        
        do {
            try context.save()
            if let userId = budgetUserId {
                loadBudgets(for: userId)
            }
        } catch {
            throw BudgetError.failedToDeleteSection(error.localizedDescription)
        }
    }
    
    func addCategoryToSection(sectionId: String, categoryId: String, displayOrder: Int32) throws {
        let context = persistenceController.viewContext
        
        // Find section
        let sectionRequest: NSFetchRequest<LocalBudgetSection> = LocalBudgetSection.fetchRequest()
        sectionRequest.predicate = NSPredicate(format: "id == %@", sectionId)
        guard let section = try context.fetch(sectionRequest).first else {
            throw BudgetError.sectionNotFound
        }
        
        // Find category
        let categoryRequest: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId)
        guard let category = try context.fetch(categoryRequest).first else {
            throw BudgetError.categoryNotFound
        }
        
        // Check if mapping already exists and clean up any duplicates
        let mappingRequest: NSFetchRequest<LocalBudgetSectionCategory> = LocalBudgetSectionCategory.fetchRequest()
        mappingRequest.predicate = NSPredicate(format: "section.id == %@ AND category.id == %@", sectionId, categoryId)
        let existingMappings = try context.fetch(mappingRequest)
        
        if let firstMapping = existingMappings.first {
            // Update the first mapping
            firstMapping.displayOrder = displayOrder
            
            // Delete any duplicate mappings
            for duplicateMapping in existingMappings.dropFirst() {
                context.delete(duplicateMapping)
            }
        } else {
            // Create new mapping
            let mapping = LocalBudgetSectionCategory.create(in: context)
            mapping.section = section
            mapping.category = category
            mapping.displayOrder = displayOrder
        }
        
        do {
            try context.save()
        } catch {
            throw BudgetError.failedToAddCategoryToSection(error.localizedDescription)
        }
    }
    
    func cleanupDuplicateSectionCategoryMappings() throws {
        let context = persistenceController.viewContext
        var deletedCount = 0
        
        // Clean up old structure mappings
        let oldRequest: NSFetchRequest<LocalBudgetSectionCategory> = LocalBudgetSectionCategory.fetchRequest()
        let oldMappings = try context.fetch(oldRequest)
        
        let oldGroupedMappings = Dictionary(grouping: oldMappings) { mapping in
            return "\(mapping.section?.id ?? "")_\(mapping.category?.id ?? "")"
        }
        
        for (_, mappings) in oldGroupedMappings {
            if mappings.count > 1 {
                for duplicateMapping in mappings.dropFirst() {
                    context.delete(duplicateMapping)
                    deletedCount += 1
                }
            }
        }
        
        // Clean up new structure mappings
        let newRequest: NSFetchRequest<LocalPeriodSectionCategory> = LocalPeriodSectionCategory.fetchRequest()
        let newMappings = try context.fetch(newRequest)
        
        let newGroupedMappings = Dictionary(grouping: newMappings) { mapping in
            let sectionId = mapping.section?.id ?? ""
            let categoryId = mapping.category?.id ?? ""
            return "\(sectionId)_\(categoryId)"
        }
        
        for (_, mappings) in newGroupedMappings {
            if mappings.count > 1 {
                for duplicateMapping in mappings.dropFirst() {
                    context.delete(duplicateMapping)
                    deletedCount += 1
                }
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            // Cleaned up duplicate section-category mappings
        }
    }
    
    // MARK: - Analytics & Reporting
    
    func getBudgetSummary(budget: LocalBudget, period: LocalBudgetPeriod? = nil) throws -> BudgetSummary {
        let targetPeriod: LocalBudgetPeriod?
        
        if let period = period {
            targetPeriod = period
        } else {
            targetPeriod = getCurrentPeriod(for: budget)
        }
        
        guard let period = targetPeriod else {
            throw BudgetError.noPeriodFound
        }
        
        // Calculate totals
        let plans = period.getPlans()
        let transactions = period.getTransactions()
        
        let plannedIncome = plans.filter { $0.type == "INCOME" }.reduce(0) { $0 + $1.amountCents }
        let plannedExpense = plans.filter { $0.type == "EXPENSE" }.reduce(0) { $0 + $1.amountCents }
        let actualIncome = transactions.filter { $0.type == "INCOME" }.reduce(0) { $0 + $1.amountCents }
        let actualExpense = transactions.filter { $0.type == "EXPENSE" }.reduce(0) { $0 + $1.amountCents }
        
        return BudgetSummary(
            budgetId: budget.id!,
            periodId: period.id!,
            plannedIncomeAmount: Double(plannedIncome) / 100.0,
            plannedExpenseAmount: Double(plannedExpense) / 100.0,
            actualIncomeAmount: Double(actualIncome) / 100.0,
            actualExpenseAmount: Double(actualExpense) / 100.0,
            incomeRemaining: Double(plannedIncome - actualIncome) / 100.0,
            expenseRemaining: Double(plannedExpense - actualExpense) / 100.0
        )
    }
    
    // MARK: - Helper Methods
    
    func getBudget(id: String) -> LocalBudget? {
        return budgets.first { $0.id == id }
    }
    
    func setCurrentBudget(_ budget: LocalBudget) {
        currentBudget = budget
    }
}

// MARK: - Supporting Models

struct BudgetSummary {
    let budgetId: String
    let periodId: String
    let plannedIncomeAmount: Double
    let plannedExpenseAmount: Double
    let actualIncomeAmount: Double
    let actualExpenseAmount: Double
    let incomeRemaining: Double
    let expenseRemaining: Double
    
    var netPlanned: Double {
        return plannedIncomeAmount - plannedExpenseAmount
    }
    
    var netActual: Double {
        return actualIncomeAmount - actualExpenseAmount
    }
    
    var isOverBudget: Bool {
        return actualExpenseAmount > plannedExpenseAmount
    }
}

// MARK: - Error Types

enum BudgetError: LocalizedError {
    case failedToCreate(String)
    case failedToUpdate(String)
    case failedToDelete(String)
    case failedToCreatePeriod(String)
    case failedToUpdatePeriod(String)
    case failedToCreateSection(String)
    case failedToUpdateSection(String)
    case failedToDeleteSection(String)
    case failedToAddCategoryToSection(String)
    case sectionNotFound
    case categoryNotFound
    case noPeriodFound
    
    var errorDescription: String? {
        switch self {
        case .failedToCreate(let message):
            return "Failed to create budget: \(message)"
        case .failedToUpdate(let message):
            return "Failed to update budget: \(message)"
        case .failedToDelete(let message):
            return "Failed to delete budget: \(message)"
        case .failedToCreatePeriod(let message):
            return "Failed to create period: \(message)"
        case .failedToUpdatePeriod(let message):
            return "Failed to update period: \(message)"
        case .failedToCreateSection(let message):
            return "Failed to create section: \(message)"
        case .failedToUpdateSection(let message):
            return "Failed to update section: \(message)"
        case .failedToDeleteSection(let message):
            return "Failed to delete section: \(message)"
        case .failedToAddCategoryToSection(let message):
            return "Failed to add category to section: \(message)"
        case .sectionNotFound:
            return "Section not found"
        case .categoryNotFound:
            return "Category not found"
        case .noPeriodFound:
            return "No active period found for this budget"
        }
    }
}