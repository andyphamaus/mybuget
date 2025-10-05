import Foundation
import CoreData

extension LocalPeriodSectionCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalPeriodSectionCategory> {
        return NSFetchRequest<LocalPeriodSectionCategory>(entityName: "LocalPeriodSectionCategory")
    }

    @NSManaged public var id: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var section: LocalPeriodSection?
    @NSManaged public var category: LocalCategory?

}

extension LocalPeriodSectionCategory : Identifiable {

}