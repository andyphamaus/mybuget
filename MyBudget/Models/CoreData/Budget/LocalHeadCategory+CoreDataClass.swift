import Foundation
import CoreData

@objc(LocalHeadCategory)
public class LocalHeadCategory: NSManagedObject {
    
    /// Creates a new head category
    static func create(in context: NSManagedObjectContext, isSystem: Bool = false) -> LocalHeadCategory {
        let headCategory = LocalHeadCategory(context: context)
        headCategory.id = "hc-\(UUID().uuidString.lowercased())"
        headCategory.isSystem = isSystem
        headCategory.isArchived = false
        headCategory.createdAt = Date()
        return headCategory
    }
    
    /// Fetches all active head categories
    static func fetchActive(in context: NSManagedObjectContext) -> [LocalHeadCategory] {
        let request: NSFetchRequest<LocalHeadCategory> = LocalHeadCategory.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Fetches system head categories
    static func fetchSystemCategories(in context: NSManagedObjectContext) -> [LocalHeadCategory] {
        let request: NSFetchRequest<LocalHeadCategory> = LocalHeadCategory.fetchRequest()
        request.predicate = NSPredicate(format: "isSystem == %@ AND isArchived == %@", 
                                       NSNumber(value: true), NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
}