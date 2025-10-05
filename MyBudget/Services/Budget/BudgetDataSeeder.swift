import Foundation
import CoreData

enum BudgetDataSeederError: LocalizedError {
    case invalidBudgetPeriod
    case missingEntityID(entityType: String, entityName: String?)
    case categoryCreationFailed(categoryName: String)
    case planCreationFailed(categoryName: String)
    case transactionCreationFailed(categoryName: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidBudgetPeriod:
            return "Invalid budget period provided"
        case .missingEntityID(let entityType, let entityName):
            return "Missing ID for \(entityType): \(entityName ?? "unknown")"
        case .categoryCreationFailed(let categoryName):
            return "Failed to create category: \(categoryName)"
        case .planCreationFailed(let categoryName):
            return "Failed to create plan for category: \(categoryName)"
        case .transactionCreationFailed(let categoryName):
            return "Failed to create transaction for category: \(categoryName)"
        }
    }
}

@MainActor
class BudgetDataSeeder: ObservableObject {
    private let persistenceController = PersistenceController.shared
    private let categoryService: CategoryService
    private let budgetService: BudgetService
    
    init() {
        self.categoryService = CategoryService()
        self.budgetService = BudgetService()
    }
    
    // MARK: - Main Seeding Methods
    
    /// Seeds all necessary default data for budget system
    func seedDefaultBudgetData() async throws {
        print("🌱 Starting budget data seeding...")
        
        // 1. Seed system categories first
        try await seedSystemCategoriesInternal()
        
        // 2. Create default budget for demo purposes
        try await createDefaultBudget()
        
        print("✅ Budget data seeding completed successfully!")
    }
    
    /// Resets all budget data while preserving head categories and default categories
    func resetBudgetData() async throws {
        print("🗑️ Starting budget data reset (preserving categories)...")
        
        let context = persistenceController.viewContext
        
        try await context.perform {
            // 1. Delete all transactions
            let transactionFetch = NSFetchRequest<LocalTransaction>(entityName: "LocalTransaction")
            let transactions = try context.fetch(transactionFetch)
            print("🗑️ Deleting \(transactions.count) transactions...")
            for transaction in transactions {
                context.delete(transaction)
            }
            
            // 2. Delete all budget period plans
            let planFetch = NSFetchRequest<LocalBudgetPeriodPlan>(entityName: "LocalBudgetPeriodPlan")
            let plans = try context.fetch(planFetch)
            print("🗑️ Deleting \(plans.count) budget plans...")
            for plan in plans {
                context.delete(plan)
            }
            
            // 3. Delete all section category mappings
            let sectionCategoryFetch = NSFetchRequest<LocalPeriodSectionCategory>(entityName: "LocalPeriodSectionCategory")
            let sectionCategories = try context.fetch(sectionCategoryFetch)
            print("🗑️ Deleting \(sectionCategories.count) section-category mappings...")
            for sectionCategory in sectionCategories {
                context.delete(sectionCategory)
            }
            
            // 4. Delete all period sections
            let sectionFetch = NSFetchRequest<LocalPeriodSection>(entityName: "LocalPeriodSection")
            let sections = try context.fetch(sectionFetch)
            print("🗑️ Deleting \(sections.count) period sections...")
            for section in sections {
                context.delete(section)
            }
            
            // 5. Delete all budget periods
            let periodFetch = NSFetchRequest<LocalBudgetPeriod>(entityName: "LocalBudgetPeriod")
            let periods = try context.fetch(periodFetch)
            print("🗑️ Deleting \(periods.count) budget periods...")
            for period in periods {
                context.delete(period)
            }
            
            // 6. Delete all budgets
            let budgetFetch = NSFetchRequest<LocalBudget>(entityName: "LocalBudget")
            let budgets = try context.fetch(budgetFetch)
            print("🗑️ Deleting \(budgets.count) budgets...")
            for budget in budgets {
                context.delete(budget)
            }
            
            // 7. Delete all recurring transaction series
            let recurringFetch = NSFetchRequest<LocalRecurringTransactionSeries>(entityName: "LocalRecurringTransactionSeries")
            let recurringSeries = try context.fetch(recurringFetch)
            print("🗑️ Deleting \(recurringSeries.count) recurring transaction series...")
            for series in recurringSeries {
                context.delete(series)
            }
            
            // Save changes
            try context.save()
            print("💾 Budget reset completed successfully!")
        }
        
        // Create a default budget and current month period
        print("🏗️ Creating default budget and current month period...")
        try await createDefaultBudgetAfterReset()
        
        // Reload the services to reflect changes
        categoryService.loadCategories()
        budgetService.loadBudgets()
        
        print("✅ Budget data reset completed! Categories preserved, default budget and current month period created.")
        
        // Notify all BudgetViewModels to refresh their data
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("BudgetDataWasReset"), object: nil)
        }
    }
    
    /// Creates a minimal default budget with current month period after reset
    private func createDefaultBudgetAfterReset() async throws {
        // Create default budget
        let defaultBudget = try budgetService.createBudget(
            userId: "default-user",
            name: "My Budget",
            icon: "dollarsign.circle.fill",
            color: "#10B981",
            currencyCode: "USD"
        )
        
        // Create current month period
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let currentPeriod = try budgetService.createPeriod(
            for: defaultBudget,
            type: "MONTHLY",
            startDate: startOfMonth,
            endDate: endOfMonth
        )
        
        print("🏗️ Created default budget '\(defaultBudget.name ?? "Unknown")' with current month period")
    }
    
    // MARK: - System Categories Seeding
    
    /// Seeds system categories only (public method for onboarding integration)
    func seedSystemCategories() async throws {
        print("📋 Seeding system categories...")
        
        // Check if system categories already exist
        let existingSystemCategories = categoryService.headCategories.filter { $0.isSystem }
        if !existingSystemCategories.isEmpty {
            print("ℹ️ System categories already exist, skipping...")
            return
        }
        
        try await seedIncomeCategories()
        try await seedExpenseCategories()
        
        // Reload categories after seeding
        categoryService.loadCategories()
        
        print("✅ System categories seeded successfully")
    }
    
    private func seedSystemCategoriesInternal() async throws {
        print("📋 Seeding system categories...")
        
        // Check if system categories already exist
        let existingSystemCategories = categoryService.headCategories.filter { $0.isSystem }
        if !existingSystemCategories.isEmpty {
            print("ℹ️ System categories already exist, skipping...")
            return
        }
        
        try await seedIncomeCategories()
        try await seedExpenseCategories()
        
        // Reload categories after seeding
        categoryService.loadCategories()
        
        print("✅ System categories seeded successfully")
    }
    
    private func seedIncomeCategories() async throws {
        print("💰 Creating income categories...")
        
        // Income Head Category
        let incomeHead = try categoryService.createHeadCategory(
            name: "Income",
            preferType: "INCOME",
            icon: "dollarsign.circle.fill",
            color: "#10B981",
            displayOrder: 10,
            isSystem: true
        )
        
        // Income subcategories
        let incomeCategories = [
            ("Salary", "briefcase.fill", "#34D399", 1),
            ("Bonus", "star.fill", "#6EE7B7", 2),
            ("Freelance", "laptopcomputer", "#A7F3D0", 3),
            ("Investment", "chart.line.uptrend.xyaxis", "#D1FAE5", 4),
            ("Business", "building.2.fill", "#ECFDF5", 5)
        ]
        
        guard let incomeHeadId = incomeHead.id else {
            print("⚠️ Failed to create income subcategories: incomeHead.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (name, icon, color, order) in incomeCategories {
            _ = try categoryService.createCategory(
                headCategoryId: incomeHeadId,
                name: name,
                icon: icon,
                color: color,
                displayOrder: order,
                isSystem: true
            )
        }
    }
    
    private func seedExpenseCategories() async throws {
        print("💸 Creating expense categories...")
        
        // Food & Dining
        let foodHead = try categoryService.createHeadCategory(
            name: "Food & Dining",
            preferType: "EXPENSE",
            icon: "fork.knife",
            color: "#F59E0B",
            displayOrder: 20,
            isSystem: true
        )
        
        let foodCategories = [
            ("Groceries", "cart.fill", "#FBBF24", 1),
            ("Restaurant", "takeoutbag.and.cup.and.straw.fill", "#FCD34D", 2),
            ("Coffee", "cup.and.saucer.fill", "#FDE68A", 3),
            ("Fast Food", "hamburger", "#FEF3C7", 4)
        ]
        
        guard let foodHeadId = foodHead.id else {
            print("⚠️ Failed to create food subcategories: foodHead.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (name, icon, color, order) in foodCategories {
            _ = try categoryService.createCategory(
                headCategoryId: foodHeadId,
                name: name,
                icon: icon,
                color: color,
                displayOrder: order,
                isSystem: true
            )
        }
        
        // Transportation
        let transportHead = try categoryService.createHeadCategory(
            name: "Transportation",
            preferType: "EXPENSE",
            icon: "car.fill",
            color: "#3B82F6",
            displayOrder: 30,
            isSystem: true
        )
        
        let transportCategories = [
            ("Car Expense", "car.side", "#60A5FA", 1),
            ("Gas", "fuelpump.fill", "#93C5FD", 2),
            ("Public Transport", "tram.fill", "#BFDBFE", 3),
            ("Uber/Taxi", "car.circle", "#DBEAFE", 4)
        ]
        
        guard let transportHeadId = transportHead.id else {
            print("⚠️ Failed to create transport subcategories: transportHead.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (name, icon, color, order) in transportCategories {
            _ = try categoryService.createCategory(
                headCategoryId: transportHeadId,
                name: name,
                icon: icon,
                color: color,
                displayOrder: order,
                isSystem: true
            )
        }
        
        // Housing
        let housingHead = try categoryService.createHeadCategory(
            name: "Housing",
            preferType: "EXPENSE",
            icon: "house.fill",
            color: "#8B5CF6",
            displayOrder: 40,
            isSystem: true
        )
        
        let housingCategories = [
            ("Rent", "key.fill", "#A78BFA", 1),
            ("Utilities", "bolt.fill", "#C4B5FD", 2),
            ("Internet", "wifi", "#DDD6FE", 3),
            ("Insurance", "shield.fill", "#EDE9FE", 4)
        ]
        
        guard let housingHeadId = housingHead.id else {
            print("⚠️ Failed to create housing subcategories: housingHead.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (name, icon, color, order) in housingCategories {
            _ = try categoryService.createCategory(
                headCategoryId: housingHeadId,
                name: name,
                icon: icon,
                color: color,
                displayOrder: order,
                isSystem: true
            )
        }
        
        // Entertainment
        let entertainmentHead = try categoryService.createHeadCategory(
            name: "Entertainment",
            preferType: "EXPENSE",
            icon: "gamecontroller.fill",
            color: "#EC4899",
            displayOrder: 50,
            isSystem: true
        )
        
        let entertainmentCategories = [
            ("Movies", "tv.fill", "#F472B6", 1),
            ("Gaming", "gamecontroller", "#F9A8D4", 2),
            ("Sports", "sportscourt.fill", "#FBCFE8", 3),
            ("Books", "book.fill", "#FCE7F3", 4)
        ]
        
        guard let entertainmentHeadId = entertainmentHead.id else {
            print("⚠️ Failed to create entertainment subcategories: entertainmentHead.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (name, icon, color, order) in entertainmentCategories {
            _ = try categoryService.createCategory(
                headCategoryId: entertainmentHeadId,
                name: name,
                icon: icon,
                color: color,
                displayOrder: order,
                isSystem: true
            )
        }
        
        // Health & Fitness
        let healthHead = try categoryService.createHeadCategory(
            name: "Health & Fitness",
            preferType: "EXPENSE",
            icon: "heart.fill",
            color: "#EF4444",
            displayOrder: 60,
            isSystem: true
        )
        
        let healthCategories = [
            ("Medical", "cross.circle.fill", "#F87171", 1),
            ("Gym", "dumbbell.fill", "#FCA5A5", 2),
            ("Pharmacy", "pills.fill", "#FECACA", 3),
            ("Wellness", "leaf.fill", "#FEE2E2", 4)
        ]
        
        guard let healthHeadId = healthHead.id else {
            print("⚠️ Failed to create health subcategories: healthHead.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (name, icon, color, order) in healthCategories {
            _ = try categoryService.createCategory(
                headCategoryId: healthHeadId,
                name: name,
                icon: icon,
                color: color,
                displayOrder: order,
                isSystem: true
            )
        }
    }
    
    // MARK: - Default Budget Creation
    
    private func createDefaultBudget() async throws {
        print("🏦 Creating default budget...")
        
        // Check if any budgets already exist
        if !budgetService.budgets.isEmpty {
            print("ℹ️ Budgets already exist, skipping default budget creation...")
            return
        }
        
        // Create default budget
        let defaultBudget = try budgetService.createBudget(
            userId: "demo-user", // This will be replaced with actual user ID later
            name: "My Budget",
            icon: "dollarsign.circle.fill",
            color: "#10B981",
            currencyCode: "AUD"
        )
        
        print("💼 Default budget created: \(defaultBudget.name ?? "Unknown")")
        
        // Create current period for the budget
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let currentPeriod = try budgetService.createPeriod(
            for: defaultBudget,
            type: "MONTHLY",
            startDate: startOfMonth,
            endDate: endOfMonth
        )
        
        print("📅 Current period created: \(currentPeriod.name ?? "Current Month")")
        
        // Create demo sections with proper plan organization
        try await createDemoSectionsWithPlans(for: currentPeriod)
        
        print("✅ Default budget setup complete with demo sections and plans")
    }
    
    private func createDemoSectionsWithPlans(for period: LocalBudgetPeriod) async throws {
        print("📊 Creating demo sections with organized plans...")
        
        guard let budget = period.budget else {
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        let planningService = PlanningService()
        let budgetService = BudgetService()
        
        // Get categories
        let incomeCategories = categoryService.getCategories(ofType: "INCOME")
        let expenseCategories = categoryService.getCategories(ofType: "EXPENSE")
        
        // Section 1: Income
        let incomeSection = try budgetService.createPeriodSection(
            for: period,
            name: "💰 Income Sources",
            typeHint: "INCOME"
        )
        
        // Add income plans to income section
        if let salaryCategory = incomeCategories.first(where: { $0.name == "Salary" }) {
            guard let periodId = period.id,
                  let salaryCategoryId = salaryCategory.id,
                  let incomeSectionId = incomeSection.id else {
                print("⚠️ Missing IDs for salary category setup: period=\(period.id), salaryCategory=\(salaryCategory.id), incomeSection=\(incomeSection.id)")
                throw BudgetDataSeederError.invalidBudgetPeriod
            }
            
            let _ = try planningService.createOrUpdatePlan(
                periodId: periodId,
                categoryId: salaryCategoryId,
                type: "INCOME",
                amount: 5000.0,
                notes: "Monthly salary"
            )
            // Add to income section
            try budgetService.addCategoryToPeriodSection(
                sectionId: incomeSectionId,
                categoryId: salaryCategoryId,
                displayOrder: 0
            )
        }
        
        if let freelanceCategory = incomeCategories.first(where: { $0.name == "Freelance" }) {
            guard let periodId = period.id,
                  let freelanceCategoryId = freelanceCategory.id,
                  let incomeSectionId = incomeSection.id else {
                print("⚠️ Missing IDs for freelance category setup: period=\(period.id), freelanceCategory=\(freelanceCategory.id), incomeSection=\(incomeSection.id)")
                throw BudgetDataSeederError.invalidBudgetPeriod
            }
            
            let _ = try planningService.createOrUpdatePlan(
                periodId: periodId,
                categoryId: freelanceCategoryId,
                type: "INCOME",
                amount: 1500.0,
                notes: "Side projects"
            )
            // Add to income section
            try budgetService.addCategoryToPeriodSection(
                sectionId: incomeSectionId,
                categoryId: freelanceCategoryId,
                displayOrder: 1
            )
        }
        
        // Section 2: Essential Expenses
        let essentialsSection = try budgetService.createPeriodSection(
            for: period,
            name: "🏠 Essential Expenses",
            typeHint: "EXPENSE"
        )
        
        let essentialExpenses = [
            ("Rent", 1800.0, "Monthly rent payment"),
            ("Utilities", 200.0, "Electricity, water, internet"),
            ("Groceries", 600.0, "Food and household items")
        ]
        
        guard let periodId = period.id,
              let essentialsSectionId = essentialsSection.id else {
            print("⚠️ Missing IDs for essentials section: period=\(period.id), essentialsSection=\(essentialsSection.id)")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (index, (categoryName, amount, note)) in essentialExpenses.enumerated() {
            if let category = expenseCategories.first(where: { $0.name == categoryName }) {
                guard let categoryId = category.id else {
                    print("⚠️ Missing category ID for \(categoryName): category.id is nil")
                    continue
                }
                
                let _ = try planningService.createOrUpdatePlan(
                    periodId: periodId,
                    categoryId: categoryId,
                    type: "EXPENSE",
                    amount: amount,
                    notes: note
                )
                // Add to essentials section
                try budgetService.addCategoryToPeriodSection(
                    sectionId: essentialsSectionId,
                    categoryId: categoryId,
                    displayOrder: Int32(index)
                )
            }
        }
        
        // Section 3: Transportation
        let transportSection = try budgetService.createPeriodSection(
            for: period,
            name: "🚗 Transportation",
            typeHint: "EXPENSE"
        )
        
        if let carCategory = expenseCategories.first(where: { $0.name == "Car Expense" }) {
            guard let periodId = period.id,
                  let carCategoryId = carCategory.id,
                  let transportSectionId = transportSection.id else {
                print("⚠️ Missing IDs for car expense setup: period=\(period.id), carCategory=\(carCategory.id), transportSection=\(transportSection.id)")
                throw BudgetDataSeederError.invalidBudgetPeriod
            }
            
            let _ = try planningService.createOrUpdatePlan(
                periodId: periodId,
                categoryId: carCategoryId,
                type: "EXPENSE",
                amount: 400.0,
                notes: "Gas, maintenance, insurance"
            )
            // Add to transport section
            try budgetService.addCategoryToPeriodSection(
                sectionId: transportSectionId,
                categoryId: carCategoryId,
                displayOrder: 0
            )
        }
        
        // Section 4: Lifestyle & Entertainment
        let lifestyleSection = try budgetService.createPeriodSection(
            for: period,
            name: "🎯 Lifestyle",
            typeHint: "EXPENSE"
        )
        
        let lifestyleExpenses = [
            ("Entertainment", 300.0, "Movies, dining out, hobbies"),
            ("Health & Fitness", 150.0, "Gym membership, healthcare")
        ]
        
        guard let periodId = period.id,
              let lifestyleSectionId = lifestyleSection.id else {
            print("⚠️ Missing IDs for lifestyle section: period=\(period.id), lifestyleSection=\(lifestyleSection.id)")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (index, (categoryName, amount, note)) in lifestyleExpenses.enumerated() {
            if let category = expenseCategories.first(where: { $0.name == categoryName }) {
                guard let categoryId = category.id else {
                    print("⚠️ Missing category ID for \(categoryName): category.id is nil")
                    continue
                }
                
                let _ = try planningService.createOrUpdatePlan(
                    periodId: periodId,
                    categoryId: categoryId,
                    type: "EXPENSE",
                    amount: amount,
                    notes: note
                )
                // Add to lifestyle section
                try budgetService.addCategoryToPeriodSection(
                    sectionId: lifestyleSectionId,
                    categoryId: categoryId,
                    displayOrder: Int32(index)
                )
            }
        }
        
        print("✅ Created 4 demo sections with organized budget plans")
    }
    
    private func createDemoPlanningData(for period: LocalBudgetPeriod) async throws {
        print("📊 Creating demo planning data...")
        
        let planningService = PlanningService()
        
        // Get some categories to plan with
        let incomeCategories = categoryService.getCategories(ofType: "INCOME")
        let expenseCategories = categoryService.getCategories(ofType: "EXPENSE")
        
        // Plan some income
        if let salaryCategory = incomeCategories.first(where: { $0.name == "Salary" }) {
            guard let periodId = period.id,
                  let salaryCategoryId = salaryCategory.id else {
                print("⚠️ Missing IDs for salary planning: period=\(period.id), salaryCategory=\(salaryCategory.id)")
                throw BudgetDataSeederError.invalidBudgetPeriod
            }
            
            _ = try planningService.createOrUpdatePlan(
                periodId: periodId,
                categoryId: salaryCategoryId,
                type: "INCOME",
                amount: 5000.0,
                notes: "Monthly salary"
            )
        }
        
        // Plan some expenses
        let expensePlans = [
            ("Groceries", 800.0, "Weekly grocery shopping"),
            ("Rent", 1800.0, "Monthly rent payment"),
            ("Car Expense", 300.0, "Car maintenance and registration"),
            ("Utilities", 200.0, "Electricity, water, gas")
        ]
        
        guard let periodId = period.id else {
            print("⚠️ Missing period ID for expense planning: period.id is nil")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (categoryName, amount, notes) in expensePlans {
            if let category = expenseCategories.first(where: { $0.name == categoryName }) {
                guard let categoryId = category.id else {
                    print("⚠️ Missing category ID for \(categoryName): category.id is nil")
                    continue
                }
                
                _ = try planningService.createOrUpdatePlan(
                    periodId: periodId,
                    categoryId: categoryId,
                    type: "EXPENSE",
                    amount: amount,
                    notes: notes
                )
            }
        }
        
        print("✅ Demo planning data created")
    }
    
    private func createDemoTransactions(for budget: LocalBudget, period: LocalBudgetPeriod) async throws {
        print("💳 Creating demo transactions...")
        
        let transactionService = TransactionService()
        let calendar = Calendar.current
        
        // Get categories for transactions
        let categories = categoryService.categories
        
        // Create some income transactions
        if let salaryCategory = categories.first(where: { $0.name == "Salary" }) {
            guard let budgetId = budget.id,
                  let periodId = period.id,
                  let salaryCategoryId = salaryCategory.id else {
                print("⚠️ Missing IDs for salary transaction: budget=\(budget.id), period=\(period.id), salaryCategory=\(salaryCategory.id)")
                throw BudgetDataSeederError.invalidBudgetPeriod
            }
            
            _ = try transactionService.createTransaction(
                budgetId: budgetId,
                periodId: periodId,
                categoryId: salaryCategoryId,
                type: "INCOME",
                amount: 5000.0,
                date: calendar.date(byAdding: .day, value: -25, to: Date()) ?? Date(),
                notes: "Monthly salary payment"
            )
        }
        
        // Create some expense transactions
        let expenseTransactions = [
            ("Groceries", 85.50, -3, "Woolworths weekly shopping"),
            ("Groceries", 92.30, -10, "Coles grocery shopping"),
            ("Gas", 65.00, -5, "Shell fuel station"),
            ("Coffee", 4.50, -1, "Morning coffee"),
            ("Restaurant", 45.80, -7, "Dinner with friends"),
            ("Utilities", 180.25, -15, "Electricity bill")
        ]
        
        guard let budgetId = budget.id,
              let periodId = period.id else {
            print("⚠️ Missing IDs for expense transactions: budget=\(budget.id), period=\(period.id)")
            throw BudgetDataSeederError.invalidBudgetPeriod
        }
        
        for (categoryName, amount, daysAgo, notes) in expenseTransactions {
            if let category = categories.first(where: { $0.name == categoryName }) {
                guard let categoryId = category.id else {
                    print("⚠️ Missing category ID for \(categoryName): category.id is nil")
                    continue
                }
                
                let transactionDate = calendar.date(byAdding: .day, value: daysAgo, to: Date()) ?? Date()
                
                _ = try transactionService.createTransaction(
                    budgetId: budgetId,
                    periodId: periodId,
                    categoryId: categoryId,
                    type: "EXPENSE",
                    amount: amount,
                    date: transactionDate,
                    notes: notes
                )
            }
        }
        
        print("✅ Demo transactions created")
    }
    
    // MARK: - Re-seed Functionality
    
    /// Re-seeds all budget data with fresh demo data organized in sections
    func reseedAllBudgetData() async throws {
        print("🔄 Starting complete budget data re-seed...")
        
        // Step 1: Clear all existing data
        try await clearAllBudgetData()
        
        // Step 2: Seed system categories
        try await seedSystemCategoriesInternal()
        
        // Step 3: Create default budget with demo data
        try await createDefaultBudget()
        
        print("✅ Budget data re-seed completed successfully!")
    }
    
    // MARK: - Utility Methods
    
    /// Checks if system data has been seeded
    func isSystemDataSeeded() -> Bool {
        let systemCategories = categoryService.headCategories.filter { $0.isSystem }
        return !systemCategories.isEmpty
    }
    
    /// Clears all budget data (for testing purposes)
    func clearAllBudgetData() async throws {
        print("🗑️ Clearing all budget data...")
        
        let context = persistenceController.viewContext
        
        // Delete all budget-related entities
        let entityNames = [
            "LocalBudgetPeriodPlan",
            "LocalTransaction",
            "LocalPeriodSectionCategory", 
            "LocalPeriodSection",
            "LocalBudgetPeriod",
            "LocalCategory",
            "LocalHeadCategory",
            "LocalBudget",
            "LocalLiability",
            "LocalRecurringTransactionSeries"
        ]
        
        for entityName in entityNames {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
        }
        
        try context.save()
        
        // Reload services
        categoryService.loadCategories()
        budgetService.loadBudgets()
        
        print("✅ All budget data cleared")
    }
}