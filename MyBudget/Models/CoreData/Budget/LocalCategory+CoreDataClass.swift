import Foundation
import CoreData

@objc(LocalCategory)
public class LocalCategory: NSManagedObject {
    
    /// Creates a new category
    static func create(in context: NSManagedObjectContext, isSystem: Bool = false) -> LocalCategory {
        let category = LocalCategory(context: context)
        category.id = "cat-\(UUID().uuidString.lowercased())"
        category.isSystem = isSystem
        category.isArchived = false
        category.createdAt = Date()
        return category
    }
    
    /// Fetches all active categories
    static func fetchActive(in context: NSManagedObjectContext) -> [LocalCategory] {
        let request: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        request.sortDescriptors = [
            NSSortDescriptor(key: "headCategory.displayOrder", ascending: true),
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Fetches categories for a specific head category
    static func fetchCategories(for headCategoryId: String, in context: NSManagedObjectContext) -> [LocalCategory] {
        let request: NSFetchRequest<LocalCategory> = LocalCategory.fetchRequest()
        request.predicate = NSPredicate(format: "headCategory.id == %@ AND isArchived == %@", 
                                       headCategoryId, NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Gets the preferred type from the head category
    var preferredType: String {
        return headCategory?.preferType ?? "EXPENSE"
    }
}