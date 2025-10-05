import Foundation
import CoreData

extension LocalNote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalNote> {
        return NSFetchRequest<LocalNote>(entityName: "LocalNote")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var isPinned: Bool
    @NSManaged public var isLocked: Bool
    @NSManaged public var colorTheme: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var reminderAt: Date?
    @NSManaged public var tags: NSSet?
    @NSManaged public var attachments: NSSet?

}

// MARK: Generated accessors for tags
extension LocalNote {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: LocalNoteTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: LocalNoteTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

// MARK: Generated accessors for attachments
extension LocalNote {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: LocalNoteAttachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: LocalNoteAttachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}