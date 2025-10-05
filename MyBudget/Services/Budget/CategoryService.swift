import Foundation
import CoreData
import Combine

@MainActor
class CategoryService: ObservableObject {
    @Published var headCategories: [LocalHeadCategory] = []
    @Published var categories: [LocalCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCategories()
    }
    
    // MARK: - Data Loading
    
    func loadCategories() {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceController.viewContext
        
        // Load head categories
        let headCategoriesRequest: NSFetchRequest<LocalHeadCategory> = LocalHeadCategory.fetchRequest()
        headCategoriesRequest.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        headCategoriesRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        // Load categories
        let categoriesRequest: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
        categoriesRequest.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        categoriesRequest.sortDescriptors = [
            NSSortDescriptor(key: "headCategory.displayOrder", ascending: true),
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        
        do {
            let fetchedHeadCategories = try context.fetch(headCategoriesRequest)
            let fetchedCategories = try context.fetch(categoriesRequest)
            
            headCategories = fetchedHeadCategories
            categories = fetchedCategories
            isLoading = false
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Head Category Operations
    
    func createHeadCategory(name: String, preferType: String, icon: String? = nil, color: String? = nil, displayOrder: Int = 0, isSystem: Bool = false, ownerUserId: String? = nil) throws -> LocalHeadCategory {
        let context = persistenceController.viewContext
        let headCategory = LocalHeadCategory.create(in: context, isSystem: isSystem)
        
        headCategory.name = name
        headCategory.preferType = preferType
        headCategory.icon = icon
        headCategory.color = color
        headCategory.displayOrder = Int32(displayOrder)
        headCategory.ownerUserId = ownerUserId
        
        do {
            try context.save()
            loadCategories()
            return headCategory
        } catch {
            throw CategoryError.failedToCreateHeadCategory(error.localizedDescription)
        }
    }
    
    func getHeadCategory(id: String) -> LocalHeadCategory? {
        return headCategories.first { $0.id == id }
    }
    
    func updateHeadCategory(_ headCategory: LocalHeadCategory, name: String?, preferType: String?, icon: String?, color: String?, displayOrder: Int?) throws {
        let context = persistenceController.viewContext
        
        if let name = name { headCategory.name = name }
        if let preferType = preferType { headCategory.preferType = preferType }
        if let icon = icon { headCategory.icon = icon }
        if let color = color { headCategory.color = color }
        if let displayOrder = displayOrder { headCategory.displayOrder = Int32(displayOrder) }
        
        do {
            try context.save()
            loadCategories()
        } catch {
            throw CategoryError.failedToUpdateHeadCategory(error.localizedDescription)
        }
    }
    
    func archiveHeadCategory(_ headCategory: LocalHeadCategory) throws {
        let context = persistenceController.viewContext
        
        headCategory.isArchived = true
        
        do {
            try context.save()
            loadCategories()
        } catch {
            throw CategoryError.failedToArchiveHeadCategory(error.localizedDescription)
        }
    }
    
    // MARK: - Category Operations
    
    func createCategory(headCategoryId: String, name: String, icon: String? = nil, color: String? = nil, displayOrder: Int = 0, isSystem: Bool = false, ownerUserId: String? = nil) throws -> LocalCategory {
        guard let headCategory = getHeadCategory(id: headCategoryId) else {
            throw CategoryError.headCategoryNotFound
        }
        
        let context = persistenceController.viewContext
        let category = LocalCategory.create(in: context, isSystem: isSystem)
        
        category.headCategory = headCategory
        category.name = name
        category.icon = icon
        category.color = color
        category.displayOrder = Int32(displayOrder)
        category.ownerUserId = ownerUserId
        
        do {
            try context.save()
            loadCategories()
            return category
        } catch {
            throw CategoryError.failedToCreateCategory(error.localizedDescription)
        }
    }
    
    func getCategory(id: String) -> LocalCategory? {
        return categories.first { $0.id == id }
    }
    
    func getCategories(for headCategoryId: String) -> [LocalCategory] {
        return categories.filter { $0.headCategory?.id == headCategoryId }
    }
    
    func getCategories(ofType type: String) -> [LocalCategory] {
        return categories.filter { $0.headCategory?.preferType == type }
    }
    
    func getUserCategories(for userId: String) -> [LocalCategory] {
        return categories.filter { $0.ownerUserId == userId }
    }
    
    func searchCategories(query: String) -> [LocalCategory] {
        if query.isEmpty {
            return categories
        }
        
        return categories.filter { category in
            category.name?.localizedCaseInsensitiveContains(query) ?? false
        }
    }
    
    func updateCategory(_ category: LocalCategory, name: String?, icon: String?, color: String?, displayOrder: Int?) throws {
        let context = persistenceController.viewContext
        
        if let name = name { category.name = name }
        if let icon = icon { category.icon = icon }
        if let color = color { category.color = color }
        if let displayOrder = displayOrder { category.displayOrder = Int32(displayOrder) }
        
        do {
            try context.save()
            loadCategories()
        } catch {
            throw CategoryError.failedToUpdateCategory(error.localizedDescription)
        }
    }
    
    func archiveCategory(_ category: LocalCategory) throws {
        let context = persistenceController.viewContext
        
        category.isArchived = true
        
        do {
            try context.save()
            loadCategories()
        } catch {
            throw CategoryError.failedToArchiveCategory(error.localizedDescription)
        }
    }
    
    // MARK: - System Data Seeding
    
    func seedSystemCategories() throws {
        // Only seed if no system categories exist
        let existingSystemCategories = headCategories.filter { $0.isSystem }
        if !existingSystemCategories.isEmpty {
            return
        }
        
        let context = persistenceController.viewContext
        
        // Transportation (EXPENSE)
        let transportation = try createHeadCategory(
            name: "Transportation",
            preferType: "EXPENSE",
            icon: "car.fill",
            color: "#3B82F6",
            displayOrder: 10,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: transportation.id!,
            name: "Car Expense",
            icon: "car.side",
            color: "#60A5FA",
            displayOrder: 1,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: transportation.id!,
            name: "Train Fare",
            icon: "tram.fill",
            color: "#93C5FD",
            displayOrder: 2,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: transportation.id!,
            name: "Uber/Taxi",
            icon: "car.circle",
            color: "#DBEAFE",
            displayOrder: 3,
            isSystem: true
        )
        
        // Income (INCOME)
        let income = try createHeadCategory(
            name: "Income",
            preferType: "INCOME",
            icon: "dollarsign.circle.fill",
            color: "#10B981",
            displayOrder: 20,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: income.id!,
            name: "Salary",
            icon: "briefcase.fill",
            color: "#34D399",
            displayOrder: 1,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: income.id!,
            name: "Bonus",
            icon: "star.fill",
            color: "#6EE7B7",
            displayOrder: 2,
            isSystem: true
        )
        
        // Food & Dining (EXPENSE)
        let food = try createHeadCategory(
            name: "Food & Dining",
            preferType: "EXPENSE",
            icon: "fork.knife",
            color: "#F59E0B",
            displayOrder: 30,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: food.id!,
            name: "Groceries",
            icon: "cart.fill",
            color: "#FBBF24",
            displayOrder: 1,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: food.id!,
            name: "Restaurant",
            icon: "takeoutbag.and.cup.and.straw.fill",
            color: "#FCD34D",
            displayOrder: 2,
            isSystem: true
        )
        
        // Housing (EXPENSE)
        let housing = try createHeadCategory(
            name: "Housing",
            preferType: "EXPENSE",
            icon: "house.fill",
            color: "#8B5CF6",
            displayOrder: 40,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: housing.id!,
            name: "Rent",
            icon: "key.fill",
            color: "#A78BFA",
            displayOrder: 1,
            isSystem: true
        )
        
        _ = try createCategory(
            headCategoryId: housing.id!,
            name: "Utilities",
            icon: "bolt.fill",
            color: "#C4B5FD",
            displayOrder: 2,
            isSystem: true
        )
    }
}

// MARK: - Error Types

enum CategoryError: LocalizedError {
    case failedToCreateHeadCategory(String)
    case failedToUpdateHeadCategory(String)
    case failedToArchiveHeadCategory(String)
    case failedToCreateCategory(String)
    case failedToUpdateCategory(String)
    case failedToArchiveCategory(String)
    case headCategoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateHeadCategory(let message):
            return "Failed to create head category: \(message)"
        case .failedToUpdateHeadCategory(let message):
            return "Failed to update head category: \(message)"
        case .failedToArchiveHeadCategory(let message):
            return "Failed to archive head category: \(message)"
        case .failedToCreateCategory(let message):
            return "Failed to create category: \(message)"
        case .failedToUpdateCategory(let message):
            return "Failed to update category: \(message)"
        case .failedToArchiveCategory(let message):
            return "Failed to archive category: \(message)"
        case .headCategoryNotFound:
            return "Head category not found"
        }
    }
}