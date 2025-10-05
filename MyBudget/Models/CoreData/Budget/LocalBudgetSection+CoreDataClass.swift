import Foundation
import CoreData

@objc(LocalBudgetSection)
public class LocalBudgetSection: NSManagedObject {
    
    /// Creates a new budget section
    static func create(in context: NSManagedObjectContext) -> LocalBudgetSection {
        let section = LocalBudgetSection(context: context)
        section.id = "sec-\(UUID().uuidString.lowercased())"
        section.isArchived = false
        section.createdAt = Date()
        return section
    }
    
    /// Fetches active sections for a budget
    static func fetchSections(for budgetId: String, in context: NSManagedObjectContext) -> [LocalBudgetSection] {
        let request: NSFetchRequest<LocalBudgetSection> = LocalBudgetSection.fetchRequest()
        request.predicate = NSPredicate(format: "budget.id == %@ AND isArchived == %@", 
                                       budgetId, NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Gets all category mappings for this section
    func getCategoryMappings() -> [LocalBudgetSectionCategory] {
        guard let mappings = self.categoryMappings as? Set<LocalBudgetSectionCategory> else { return [] }
        return Array(mappings).sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Adds a category to this section
    func addCategory(_ category: LocalCategory, in context: NSManagedObjectContext) -> LocalBudgetSectionCategory {
        let mapping = LocalBudgetSectionCategory(context: context)
        mapping.id = "map-\(UUID().uuidString.lowercased())"
        mapping.budget = self.budget
        mapping.section = self
        mapping.category = category
        mapping.displayOrder = Int32((self.categoryMappings?.count ?? 0))
        mapping.createdAt = Date()
        return mapping
    }
}