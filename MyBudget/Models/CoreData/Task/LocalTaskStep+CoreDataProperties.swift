import Foundation
import CoreData

extension LocalTaskStep {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalTaskStep> {
        return NSFetchRequest<LocalTaskStep>(entityName: "LocalTaskStep")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var order: Int16
    @NSManaged public var stepName: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var task: LocalTask?

}