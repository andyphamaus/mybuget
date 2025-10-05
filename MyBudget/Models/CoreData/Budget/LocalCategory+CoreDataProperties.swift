import Foundation
import CoreData

extension LocalCategory {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalCategory> {
        return NSFetchRequest<LocalCategory>(entityName: "LocalCategory")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var color: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var isSystem: Bool
    @NSManaged public var ownerUserId: String?
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var headCategory: LocalHeadCategory?
    @NSManaged public var sectionMappings: NSSet?
    @NSManaged public var budgetSectionMappings: NSSet?
    @NSManaged public var plans: NSSet?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var recurringSeries: NSSet?
}