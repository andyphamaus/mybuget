import Foundation
import CoreData

extension LocalTaskAttachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalTaskAttachment> {
        return NSFetchRequest<LocalTaskAttachment>(entityName: "LocalTaskAttachment")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var fileName: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var size: Int64
    @NSManaged public var fileData: Data?
    @NSManaged public var createdDate: Date?
    @NSManaged public var task: LocalTask?

}