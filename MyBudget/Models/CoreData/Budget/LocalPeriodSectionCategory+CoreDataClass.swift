import Foundation
import CoreData

@objc(LocalPeriodSectionCategory)
public class LocalPeriodSectionCategory: NSManagedObject {
    
    static func create(in context: NSManagedObjectContext) -> LocalPeriodSectionCategory {
        let mapping = LocalPeriodSectionCategory(context: context)
        mapping.id = "mapping-\(UUID().uuidString.lowercased())"
        mapping.createdAt = Date()
        return mapping
    }
}