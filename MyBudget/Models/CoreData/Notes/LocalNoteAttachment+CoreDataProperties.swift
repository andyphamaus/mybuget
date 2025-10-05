import Foundation
import CoreData

extension LocalNoteAttachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalNoteAttachment> {
        return NSFetchRequest<LocalNoteAttachment>(entityName: "LocalNoteAttachment")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var filename: String?
    @NSManaged public var fileData: Data?
    @NSManaged public var fileSize: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var note: LocalNote?

}