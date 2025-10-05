import Foundation
import CoreData

@objc(LocalBudgetSectionCategory)
public class LocalBudgetSectionCategory: NSManagedObject {
    
    /// Creates a new section-category mapping
    static func create(in context: NSManagedObjectContext) -> LocalBudgetSectionCategory {
        let mapping = LocalBudgetSectionCategory(context: context)
        mapping.id = "map-\(UUID().uuidString.lowercased())"
        mapping.createdAt = Date()
        return mapping
    }
    
    /// Fetches mapping for a category in a budget
    static func fetchMapping(categoryId: String, budgetId: String, in context: NSManagedObjectContext) -> LocalBudgetSectionCategory? {
        let request: NSFetchRequest<LocalBudgetSectionCategory> = LocalBudgetSectionCategory.fetchRequest()
        request.predicate = NSPredicate(format: "category.id == %@ AND budget.id == %@", categoryId, budgetId)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            return nil
        }
    }
    
    /// Moves category to a different section
    func moveToSection(_ newSection: LocalBudgetSection) {
        self.section = newSection
    }
}