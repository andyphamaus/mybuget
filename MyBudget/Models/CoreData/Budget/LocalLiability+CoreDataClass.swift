import Foundation
import CoreData

@objc(LocalLiability)
public class LocalLiability: NSManagedObject {
    
    /// Creates a new liability
    static func create(in context: NSManagedObjectContext) -> LocalLiability {
        let liability = LocalLiability(context: context)
        liability.id = "liab-\(UUID().uuidString.lowercased())"
        liability.status = "OPEN"
        liability.createdAt = Date()
        liability.updatedAt = Date()
        return liability
    }
}