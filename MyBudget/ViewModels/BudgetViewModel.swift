import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var budgets: [LocalBudget] = []
    @Published var currentBudget: LocalBudget?
    @Published var currentPeriod: LocalBudgetPeriod?
    @Published var allPeriods: [LocalBudgetPeriod] = []
    @Published var sections: [LocalPeriodSection] = []
    @Published var categories: [LocalCategory] = []
    @Published var plans: [LocalBudgetPeriodPlan] = []
    @Published var transactions: [LocalTransaction] = []
    @Published var budgetSummary: BudgetSummary?
    @Published var planningSummary: PlanningSummary?
    @Published var planningComparisons: [PlanningComparison] = []

    // UI State
    @Published var isLoading = false
    @Published var isCopyingPlans = false
    @Published var errorMessage: String?
    @Published var selectedTab = 0

    // Copy Plans functionality (properties already exist elsewhere, removing duplicates)

    // Computed Properties
    var currentPeriodName: String {
        guard let period = currentPeriod else { return "No Period" }
        return period.name ?? "Current Period"
    }

    var currentBudgetName: String {
        guard let budget = currentBudget else { return "Budget" }
        return budget.name ?? "Budget"
    }

    var currentBudgetColor: Color {
        guard let budget = currentBudget,
              let colorString = budget.color else {
            return .white
        }
        return Color(hex: colorString) ?? .white
    }

    var currentBudgetIcon: String {
        guard let budget = currentBudget else { return "💰" }
        return budget.icon ?? "💰"
    }

    // MARK: - Services

    private let budgetService: BudgetService
    private let categoryService: CategoryService
    private let transactionService: TransactionService
    private let planningService: PlanningService

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(budgetService: BudgetService? = nil,
         categoryService: CategoryService? = nil,
         transactionService: TransactionService? = nil,
         planningService: PlanningService? = nil) {

        self.budgetService = budgetService ?? BudgetService()
        self.categoryService = categoryService ?? CategoryService()
        self.transactionService = transactionService ?? TransactionService()
        self.planningService = planningService ?? PlanningService()

        setupBindings()

        // Listen for budget reset notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BudgetDataWasReset"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleBudgetDataReset()
            }
        }
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe budget service changes
        budgetService.$budgets
            .receive(on: DispatchQueue.main)
            .assign(to: \.budgets, on: self)
            .store(in: &cancellables)

        budgetService.$currentBudget
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentBudget, on: self)
            .store(in: &cancellables)

        budgetService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        budgetService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)

        // Observe category service changes
        categoryService.$categories
            .receive(on: DispatchQueue.main)
            .assign(to: \.categories, on: self)
            .store(in: &cancellables)

        // Observe planning service changes
        planningService.$plans
            .receive(on: DispatchQueue.main)
            .assign(to: \.plans, on: self)
            .store(in: &cancellables)

        // Observe transaction service changes
        transactionService.$transactions
            .receive(on: DispatchQueue.main)
            .assign(to: \.transactions, on: self)
            .store(in: &cancellables)

        // Auto-refresh when current budget changes
        $currentBudget
            .compactMap { $0 }
            .sink { [weak self] budget in
                Task { await self?.refreshBudgetData(for: budget) }
            }
            .store(in: &cancellables)
    }

    // MARK: - Budget Reset Handling

    private func handleBudgetDataReset() async {

        // Clear all current data to prevent accessing deleted objects
        currentBudget = nil
        currentPeriod = nil
        allPeriods = []
        sections = []
        categories = []
        plans = []
        transactions = []
        budgetSummary = nil
        planningSummary = nil
        planningComparisons = []

        // Reload fresh data
        await loadInitialData()

    }

    // MARK: - Data Loading

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Clean up any duplicate mappings first
            try budgetService.cleanupDuplicateSectionCategoryMappings()

            // Load budgets for default user (used after reset)
            budgetService.loadBudgets(for: "default-user")

            // Load categories
            categoryService.loadCategories()

            // Set current budget if not already set
            if currentBudget == nil, let firstBudget = budgets.first {
                setCurrentBudget(firstBudget)
            }

            await refreshCurrentBudgetData()

        } catch {
            errorMessage = "Failed to load budget data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshCurrentBudgetData() async {
        // Ensure this runs on main actor for thread safety
        await MainActor.run {
            // Ensure a default budget exists first
            Task {
                await ensureDefaultBudgetExists()

                guard let budget = currentBudget else { return }

                // Store the current period to maintain user's selection
                let selectedPeriod = currentPeriod

                await refreshBudgetData(for: budget)

                // Restore the selected period if it still exists
                if let selectedPeriod = selectedPeriod,
                   let periodId = selectedPeriod.id,
                   let restoredPeriod = allPeriods.first(where: { $0.id == periodId }) {
                    currentPeriod = restoredPeriod
                    await loadPeriodData(for: restoredPeriod)
                }
            }
        }
    }

    /// Ensures a default budget exists for the user, creates one if none exists
    private func ensureDefaultBudgetExists() async {
        // Prevent infinite loop by checking if we're already in the process of creating a budget
        guard budgets.isEmpty && !isLoading else { return }

        do {
            let defaultBudget = try budgetService.createBudget(
                userId: getCurrentUserId(),
                name: "My Budget",
                icon: "💰",
                color: "#10B981",
                currencyCode: "AUD"
            )
            // Don't use setCurrentBudget here to avoid triggering the observer loop
            // The budgetService.loadBudgets call will update currentBudget
            if currentBudget == nil {
                currentBudget = defaultBudget
            }
        } catch {
            errorMessage = "Failed to create default budget: \(error.localizedDescription)"
        }
    }

    private func refreshBudgetData(for budget: LocalBudget) async {
        do {
            // Load all periods for this budget
            loadAllPeriods()

            // Get current period
            currentPeriod = budgetService.getCurrentPeriod(for: budget)

            // If no period exists, create one
            if currentPeriod == nil {
                currentPeriod = try createCurrentPeriod(for: budget)
                loadAllPeriods() // Reload periods after creating a new one
            }

            guard let period = currentPeriod else { return }

            // Load data for current period
            await loadPeriodData(for: period)

        } catch {
            errorMessage = "Failed to refresh budget data: \(error.localizedDescription)"
        }
    }

    private func loadPeriodData(for period: LocalBudgetPeriod) async {
        do {
            // Refresh Core Data context to get latest data
            let context = PersistenceController.shared.viewContext
            context.refresh(period, mergeChanges: true)

            // Load sections for current budget
            if let budget = currentBudget {
                context.refresh(budget, mergeChanges: true)
                sections = budgetService.getSections(for: budget)
            }

            // Load plans with explicit UI update
            planningService.loadPlans(for: period.id)

            // Create new array reference and force update
            let newPlans = Array(planningService.plans)
            if plans != newPlans {
                plans = newPlans

                // Trigger UI update
                objectWillChange.send()
            }

            // Load transactions
            transactionService.loadTransactions(for: period.id)

            // Calculate summaries
            if let budgetId = period.budget?.id {
                budgetSummary = try budgetService.getBudgetSummary(budget: currentBudget!, period: period)
                planningSummary = try planningService.getPlanningSummary(for: period.id!)
                planningComparisons = try planningService.getPlanningComparison(for: period.id!)
            }

        } catch {
            errorMessage = "Failed to load period data: \(error.localizedDescription)"
        }
    }

    // MARK: - Budget Management

    func setCurrentBudget(_ budget: LocalBudget) {
        currentBudget = budget
        budgetService.setCurrentBudget(budget)
    }

    func createBudget(name: String, icon: String?, color: String?, currencyCode: String = "AUD") async throws -> LocalBudget {
        return try budgetService.createBudget(
            userId: getCurrentUserId(),
            name: name,
            icon: icon,
            color: color,
            currencyCode: currencyCode
        )
    }

    private func createCurrentPeriod(for budget: LocalBudget) throws -> LocalBudgetPeriod {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now

        return try budgetService.createPeriod(
            for: budget,
            type: "MONTHLY",
            startDate: startOfMonth,
            endDate: endOfMonth
        )
    }

    // MARK: - Planning Management

    func addOrUpdatePlan(categoryId: String, type: String, amount: Double, notes: String? = nil) async throws {
        guard let periodId = currentPeriod?.id else {
            throw BudgetViewModelError.noPeriodSelected
        }

        _ = try planningService.createOrUpdatePlan(
            periodId: periodId,
            categoryId: categoryId,
            type: type,
            amount: amount,
            notes: notes
        )

        await loadPeriodData(for: currentPeriod!)

        // Force UI refresh
        await MainActor.run {
            objectWillChange.send()
        }
    }

    func addOrUpdatePlanForSection(_ section: LocalPeriodSection, categoryId: String, type: String, amount: Double, notes: String? = nil) async throws {
        guard let periodId = currentPeriod?.id,
              let budgetId = currentBudget?.id else {
            throw BudgetViewModelError.noBudgetOrPeriodSelected
        }

        // Create/update the plan first
        _ = try planningService.createOrUpdatePlan(
            periodId: periodId,
            categoryId: categoryId,
            type: type,
            amount: amount,
            notes: notes
        )

        // Handle section-category mapping - ensure category only appears in one section
        let context = PersistenceController.shared.viewContext

        // Find ALL existing mappings for this category in this period
        let mappingRequest: NSFetchRequest<LocalPeriodSectionCategory> = LocalPeriodSectionCategory.fetchRequest()
        mappingRequest.predicate = NSPredicate(format: "category.id == %@ AND section.period.id == %@", categoryId, periodId)

        do {
            let existingMappings = try context.fetch(mappingRequest)

            // ENFORCE UNIQUE CONSTRAINT: Category can only be in ONE section at a time
            for existingMapping in existingMappings {
                if existingMapping.section?.id != section.id {
                    context.delete(existingMapping)
                }
            }

            // Additional validation: Ensure no duplicate plans for same category+period
            let planRequest: NSFetchRequest<LocalBudgetPeriodPlan> = LocalBudgetPeriodPlan.fetchRequest()
            planRequest.predicate = NSPredicate(format: "category.id == %@ AND period.id == %@", categoryId, currentPeriod!.id!)
            let existingPlans = try context.fetch(planRequest)

            if existingPlans.count > 1 {
                // Keep the latest plan, delete older duplicates
                let sortedPlans = existingPlans.sorted { $0.updatedAt ?? Date.distantPast > $1.updatedAt ?? Date.distantPast }
                for duplicatePlan in sortedPlans.dropFirst() {
                    context.delete(duplicatePlan)
                }
            }

            // Check if mapping already exists for this section
            let currentSectionMapping = existingMappings.first { $0.section?.id == section.id }

            if currentSectionMapping == nil {
                // Create new mapping for current section
                let mapping = LocalPeriodSectionCategory.create(in: context)
                mapping.section = section

                // Set displayOrder to be last in the section
                if let sectionMappings = section.categoryMappings as? Set<LocalPeriodSectionCategory> {
                    let maxOrder = sectionMappings.map { $0.displayOrder }.max() ?? -1
                    mapping.displayOrder = maxOrder + 1
                } else {
                    mapping.displayOrder = 0
                }

                // Find the category
                if let category = categories.first(where: { $0.id == categoryId }) {
                    mapping.category = category
                }

            }

            try context.save()

        } catch {
            throw BudgetViewModelError.invalidData
        }

        // Reload period data to refresh everything
        await loadPeriodData(for: currentPeriod!)

        // Additional explicit UI refresh for sections
        if let budget = currentBudget {
            let context = PersistenceController.shared.viewContext
            context.refresh(budget, mergeChanges: true)
            sections = budgetService.getSections(for: budget)
        }

        // Force comprehensive UI refresh
        await MainActor.run {
            objectWillChange.send()
        }
    }

    func deletePlan(_ plan: LocalBudgetPeriodPlan) async throws {
        try planningService.deletePlan(plan)
        await loadPeriodData(for: currentPeriod!)
    }

    // MARK: - Transaction Management

    func addTransaction(categoryId: String, type: String, amount: Double, date: Date, notes: String? = nil) async throws {
        guard let budget = currentBudget,
              let period = currentPeriod else {
            throw BudgetViewModelError.noBudgetOrPeriodSelected
        }

        _ = try transactionService.createTransaction(
            budgetId: budget.id!,
            periodId: period.id!,
            categoryId: categoryId,
            type: type,
            amount: amount,
            date: date,
            notes: notes
        )

        await loadPeriodData(for: period)
    }

    func deleteTransaction(_ transaction: LocalTransaction) async throws {
        try transactionService.deleteTransaction(transaction)
        await loadPeriodData(for: currentPeriod!)
    }

    func updateTransaction(_ transaction: LocalTransaction, amount: Double? = nil, date: Date? = nil, notes: String? = nil, categoryId: String? = nil) async throws {
        try transactionService.updateTransaction(transaction, amount: amount, date: date, notes: notes, categoryId: categoryId)
        await loadPeriodData(for: currentPeriod!)
    }

    // MARK: - Section Management

    func createSection(name: String, typeHint: String?) async throws -> LocalPeriodSection {
        guard let currentPeriod = currentPeriod else {
            throw BudgetViewModelError.noPeriodSelected
        }

        let section = try budgetService.createPeriodSection(
            for: currentPeriod,
            name: name,
            typeHint: typeHint,
            displayOrder: sections.count
        )

        // Reload sections and period data
        if let currentBudget = currentBudget {
            sections = budgetService.getSections(for: currentBudget)
        }

        // Reload current period data to show the new section
        await loadPeriodData(for: currentPeriod)

        return section
    }

    func updateSection(_ section: LocalPeriodSection, name: String) async throws {
        try budgetService.updatePeriodSection(section, name: name, displayOrder: nil)

        // Reload sections to refresh UI
        if let currentBudget = currentBudget {
            sections = budgetService.getSections(for: currentBudget)
        }

        // Force UI refresh
        await MainActor.run {
            objectWillChange.send()
        }
    }

    func deleteSection(_ section: LocalBudgetSection) async throws {
        try budgetService.deleteSection(section)

        // Reload sections
        if let budget = currentBudget {
            sections = budgetService.getSections(for: budget)
        }
    }

    // MARK: - Computed Properties

    var incomeCategories: [LocalCategory] {
        return categories.filter { $0.headCategory?.preferType == "INCOME" }
    }

    var expenseCategories: [LocalCategory] {
        return categories.filter { $0.headCategory?.preferType == "EXPENSE" }
    }

    var incomePlans: [LocalBudgetPeriodPlan] {
        return plans.filter { $0.type == "INCOME" }
    }

    var expensePlans: [LocalBudgetPeriodPlan] {
        return plans.filter { $0.type == "EXPENSE" }
    }

    var totalPlannedIncome: Double {
        return planningSummary?.totalPlannedIncome ?? 0.0
    }

    var totalPlannedExpenses: Double {
        return planningSummary?.totalPlannedExpense ?? 0.0
    }

    var totalActualIncome: Double {
        return budgetSummary?.actualIncomeAmount ?? 0.0
    }

    var totalActualExpenses: Double {
        return budgetSummary?.actualExpenseAmount ?? 0.0
    }

    var remainingBudget: Double {
        return totalActualIncome - totalActualExpenses
    }

    // MARK: - Period Management

    func loadAllPeriods() {
        guard let budget = currentBudget else { return }
        allPeriods = budgetService.getAllPeriods(for: budget)
    }

    func setCurrentPeriod(_ period: LocalBudgetPeriod) async {
        currentPeriod = period
        await loadPeriodData(for: period)
    }

    func navigateToNextPeriod() async {
        guard let current = currentPeriod,
              let budget = currentBudget else {
            return
        }


        // Check if next period already exists
        if let currentIndex = allPeriods.firstIndex(where: { $0.id == current.id }),
           currentIndex > 0 {
            // Navigate to existing next period
            let nextPeriod = allPeriods[currentIndex - 1]
            await setCurrentPeriod(nextPeriod)
        } else {
            // Create new period for next month
            await createNextPeriod(after: current, for: budget)
        }
    }

    func navigateToPreviousPeriod() async {
        guard let current = currentPeriod,
              let currentIndex = allPeriods.firstIndex(where: { $0.id == current.id }),
              currentIndex < allPeriods.count - 1 else { return }

        // Navigate to existing previous period (older periods have higher indices)
        let previousPeriod = allPeriods[currentIndex + 1]
        await setCurrentPeriod(previousPeriod)
    }

    // MARK: - Period Creation and Navigation
    // Copy Plans functionality
    @Published var showCopyPlansAlert = false
    @Published var periodToCopyFrom: LocalBudgetPeriod?

    private func createNextPeriod(after currentPeriod: LocalBudgetPeriod, for budget: LocalBudget) async {
        do {
            let calendar = Calendar.current
            guard let currentEndDateString = currentPeriod.endDate else {
                return
            }


            // Try multiple date formats
            var currentEndDate: Date?

            // Try ISO8601 format first
            let isoFormatter = ISO8601DateFormatter()
            currentEndDate = isoFormatter.date(from: currentEndDateString)

            // Try simple date format if ISO fails
            if currentEndDate == nil {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd"
                currentEndDate = simpleFormatter.date(from: currentEndDateString)
            }

            // Try with time component
            if currentEndDate == nil {
                let fullFormatter = DateFormatter()
                fullFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                currentEndDate = fullFormatter.date(from: currentEndDateString)
            }

            guard let endDate = currentEndDate else {
                return
            }


            // Calculate next period dates (next month)
            let nextStartDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? Date()

            // Get the month interval for the next start date
            guard let nextMonthInterval = calendar.dateInterval(of: .month, for: nextStartDate) else {
                return
            }
            let nextEndDate = calendar.date(byAdding: .day, value: -1, to: nextMonthInterval.end) ?? nextStartDate


            // Create the new period
            let newPeriod = try budgetService.createPeriod(
                for: budget,
                type: currentPeriod.periodType ?? "MONTHLY",
                startDate: nextStartDate,
                endDate: nextEndDate
            )


            // Reload periods
            loadAllPeriods()

            // Check if previous period has budget plans to copy
            if let previousPeriodId = currentPeriod.id {
                let previousPlans = planningService.getPlans(for: previousPeriodId)

                // Store the period to copy from BEFORE navigating
                let sourcePeriod = currentPeriod

                // Navigate to the new period
                await setCurrentPeriod(newPeriod)

                // Always show the copy dialog for testing
                await MainActor.run {
                    self.periodToCopyFrom = sourcePeriod
                    self.showCopyPlansAlert = true
                }
            } else {
                // Just navigate to the new period
                await setCurrentPeriod(newPeriod)
            }

        } catch {
            errorMessage = "Failed to create next period: \(error.localizedDescription)"
        }
    }

    func copyPlansFromPreviousPeriod() async {
        guard let currentPeriod = currentPeriod,
              let periodToCopyFrom = periodToCopyFrom,
              let budget = currentBudget else {
            return
        }

        // Set loading state
        await MainActor.run {
            isCopyingPlans = true
        }


        do {
            // Add delay to ensure Core Data context is synchronized
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

            // Refresh budget data to ensure everything is loaded
            budgetService.loadBudgets(for: "default-user")
            await refreshCurrentBudgetData()


            // First, copy sections from the previous period
            let previousSections = budgetService.getPeriodSections(for: periodToCopyFrom)

            var sectionMapping: [String: LocalPeriodSection] = [:]

            for oldSection in previousSections {
                // Create corresponding section in new period
                let newSection = try budgetService.createPeriodSection(
                    for: currentPeriod,
                    name: oldSection.name ?? "",
                    typeHint: nil,
                    displayOrder: Int(oldSection.displayOrder)
                )


                if let oldSectionId = oldSection.id {
                    sectionMapping[oldSectionId] = newSection
                }

                // Copy category mappings directly to period section
                if let oldMappings = oldSection.categoryMappings as? Set<LocalPeriodSectionCategory> {
                    let context = PersistenceController.shared.viewContext
                    var displayOrder: Int32 = 0

                    for mapping in oldMappings {
                        if let category = mapping.category,
                           let categoryId = category.id {
                            do {
                                // Create new period section category mapping
                                let newMapping = LocalPeriodSectionCategory(context: context)
                                newMapping.id = UUID().uuidString
                                newMapping.displayOrder = displayOrder
                                newMapping.createdAt = Date()
                                newMapping.section = newSection
                                newMapping.category = category

                                displayOrder += 1
                            } catch {
                            }
                        } else {
                        }
                    }

                    // Save the mappings
                    do {
                        try context.save()
                    } catch {
                    }
                } else {
                }
            }

            // Reload sections for the current budget
            sections = budgetService.getSections(for: budget)

            // Get all plans from the previous period

            // Use Core Data directly to get plans for the previous period
            let context = PersistenceController.shared.viewContext
            let planRequest: NSFetchRequest<LocalBudgetPeriodPlan> = LocalBudgetPeriodPlan.fetchRequest()
            planRequest.predicate = NSPredicate(format: "period.id == %@", periodToCopyFrom.id!)

            let previousPlans = try context.fetch(planRequest)

            // Copy each plan to the current period (excluding transactions)
            var copiedCount = 0
            if previousPlans.isEmpty {
            } else {
                for plan in previousPlans {
                    if let categoryId = plan.category?.id {
                        let newPlan = try planningService.createOrUpdatePlan(
                            periodId: currentPeriod.id!,
                            categoryId: categoryId,
                            type: plan.type ?? "EXPENSE",
                            amount: Double(plan.amountCents) / 100.0,
                            notes: plan.notes
                        )
                        copiedCount += 1
                    } else {
                    }
                }
            }

            // Reload current period data to show the copied plans
            await loadPeriodData(for: currentPeriod)

            // Clear the period to copy from and loading state
            await MainActor.run {
                self.periodToCopyFrom = nil
                self.isCopyingPlans = false
            }


        } catch {
            await MainActor.run {
                errorMessage = "Failed to copy budget plans: \(error.localizedDescription)"
                self.isCopyingPlans = false
            }
        }
    }


    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    // MARK: - Section-based Filtering

    func plansForSection(_ section: LocalPeriodSection) -> [LocalBudgetPeriodPlan] {
        guard let sectionMappings = section.categoryMappings as? Set<LocalPeriodSectionCategory> else {
            return []
        }

        // Create a mapping from categoryId to displayOrder
        // Use reduce to handle potential duplicates by keeping the first occurrence
        let categoryOrderMap: [String: Int32] = sectionMappings.reduce(into: [:]) { result, mapping in
            guard let categoryId = mapping.category?.id, result[categoryId] == nil else { return }
            result[categoryId] = mapping.displayOrder
        }

        let sectionPlans = plans.filter { plan in
            guard let categoryId = plan.category?.id else { return false }
            return categoryOrderMap.keys.contains(categoryId)
        }

        // Sort by displayOrder from the section mapping
        return sectionPlans.sorted { plan1, plan2 in
            let order1 = categoryOrderMap[plan1.category?.id ?? ""] ?? 0
            let order2 = categoryOrderMap[plan2.category?.id ?? ""] ?? 0
            return order1 < order2
        }
    }

    func categoriesForSection(_ section: LocalPeriodSection) -> [LocalCategory] {
        guard let sectionMappings = section.categoryMappings as? Set<LocalPeriodSectionCategory> else {
            return []
        }

        return sectionMappings.compactMap { $0.category }
    }

    // MARK: - Drag and Drop Reordering

    func reorderPlansInSection(_ section: LocalPeriodSection, from source: IndexSet, to destination: Int) async {
        let currentPlans = plansForSection(section)
        guard let sectionMappings = section.categoryMappings as? Set<LocalPeriodSectionCategory> else { return }

        // Create a mutable copy of the plans for reordering
        var reorderedPlans = currentPlans
        reorderedPlans.move(fromOffsets: source, toOffset: destination)

        // Update displayOrder in Core Data
        let context = PersistenceController.shared.viewContext

        await MainActor.run {
            for (index, plan) in reorderedPlans.enumerated() {
                guard let categoryId = plan.category?.id,
                      let mapping = sectionMappings.first(where: { $0.category?.id == categoryId }) else {
                    continue
                }

                mapping.displayOrder = Int32(index)
            }

            do {
                try context.save()
                // Don't reload all data - just trigger UI update
                self.objectWillChange.send()
            } catch {
                self.errorMessage = "Failed to reorder categories: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Cross-Section Plan Management

    func movePlan(_ plan: LocalBudgetPeriodPlan, to targetSection: LocalPeriodSection, at position: Int = 0) async throws {
        guard let categoryId = plan.category?.id,
              let _ = currentPeriod?.id else {
            throw BudgetViewModelError.invalidData
        }

        let context = PersistenceController.shared.viewContext

        // Find the current section mapping for this plan
        let allSections = sections
        var currentMapping: LocalPeriodSectionCategory?
        var currentSection: LocalPeriodSection?

        for section in allSections {
            if let sectionMappings = section.categoryMappings as? Set<LocalPeriodSectionCategory>,
               let mapping = sectionMappings.first(where: { $0.category?.id == categoryId }) {
                currentMapping = mapping
                currentSection = section
                break
            }
        }

        guard let mapping = currentMapping,
              let fromSection = currentSection,
              fromSection.id != targetSection.id else {
            return // Already in target section
        }

        // Remove from current section's category mappings
        if let currentMappings = fromSection.categoryMappings?.mutableCopy() as? NSMutableSet {
            currentMappings.remove(mapping)
            fromSection.categoryMappings = currentMappings
        }

        // Update target section mappings display orders to make room
        if let targetMappings = targetSection.categoryMappings as? Set<LocalPeriodSectionCategory> {
            let sortedTargetMappings = targetMappings.sorted { $0.displayOrder < $1.displayOrder }

            // Update display orders for existing mappings at and after the insertion position
            for (index, targetMapping) in sortedTargetMappings.enumerated() {
                if index >= position {
                    targetMapping.displayOrder = Int32(index + 1)
                }
            }
        }

        // Set new display order for the moved mapping
        mapping.displayOrder = Int32(position)

        // Add to target section's category mappings
        if let targetMappings = targetSection.categoryMappings?.mutableCopy() as? NSMutableSet {
            targetMappings.add(mapping)
            targetSection.categoryMappings = targetMappings
        } else {
            targetSection.categoryMappings = NSSet(object: mapping)
        }

        // Save changes
        do {
            try context.save()
            await loadPeriodData(for: currentPeriod!)
        } catch {
            throw error
        }
    }

    // MARK: - Budget Management

    func updateBudget(name: String?, icon: String?, color: String?, currencyCode: String?) async throws {
        guard let currentBudget = currentBudget else {
            throw BudgetViewModelError.noBudgetOrPeriodSelected
        }

        try budgetService.updateBudget(currentBudget, name: name, icon: icon, color: color, currencyCode: currencyCode)

        // Reload budget data to reflect changes
        budgetService.loadBudgets(for: "default-user")
        await refreshCurrentBudgetData()

        await MainActor.run {
            objectWillChange.send()
        }
    }

    // MARK: - Helper Methods

    private func getCurrentUserId() -> String {
        // This should come from authentication service
        return "demo-user" // Placeholder
    }

}

// MARK: - Error Types

enum BudgetViewModelError: LocalizedError {
    case noBudgetOrPeriodSelected
    case noPeriodSelected
    case invalidData

    var errorDescription: String? {
        switch self {
        case .noBudgetOrPeriodSelected:
            return "No budget or period selected"
        case .noPeriodSelected:
            return "No period selected"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - View Data Models

struct BudgetCategoryDisplayData {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let plannedAmount: Double
    let actualAmount: Double
    let type: String
    let remainingAmount: Double
    let percentageUsed: Double
    let isOverBudget: Bool

    init(from comparison: PlanningComparison) {
        self.id = comparison.categoryId
        self.name = comparison.categoryName
        self.icon = comparison.categoryIcon ?? "circle.fill"
        self.color = Color(hex: comparison.categoryColor) ?? .gray
        self.plannedAmount = comparison.plannedAmount
        self.actualAmount = comparison.actualAmount
        self.type = comparison.type
        self.remainingAmount = comparison.remainingAmount
        self.percentageUsed = comparison.percentageUsed
        self.isOverBudget = comparison.isOverBudget
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String?) {
        guard let hex = hex else { return nil }

        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexColor = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        guard hexColor.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        guard Scanner(string: hexColor).scanHexInt64(&rgbValue) else { return nil }

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}