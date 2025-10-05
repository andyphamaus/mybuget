import Foundation
import CoreData

extension LocalHeadCategory {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalHeadCategory> {
        return NSFetchRequest<LocalHeadCategory>(entityName: "LocalHeadCategory")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var preferType: String?
    @NSManaged public var icon: String?
    @NSManaged public var color: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var isSystem: Bool
    @NSManaged public var ownerUserId: String?
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var categories: NSSet?
}