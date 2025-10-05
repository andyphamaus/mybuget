import Foundation
import CoreData

extension LocalActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalActivity> {
        return NSFetchRequest<LocalActivity>(entityName: "LocalActivity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var module: String?
    @NSManaged public var action: String?
    @NSManaged public var title: String?
    @NSManaged public var activityDescription: String?
    @NSManaged public var metadata: String?
    @NSManaged public var timestamp: Date?

}