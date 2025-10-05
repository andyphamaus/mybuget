import Foundation
import CoreData

extension LocalTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalTask> {
        return NSFetchRequest<LocalTask>(entityName: "LocalTask")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var detail: String?
    @NSManaged public var status: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var category: String?
    @NSManaged public var priority: Int16
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedDate: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var remindMeOn: Date?
    @NSManaged public var notes: String?
    @NSManaged public var pointEarned: Int32
    @NSManaged public var sourceType: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
    @NSManaged public var steps: NSSet?
    @NSManaged public var attachments: NSSet?

}

// MARK: Generated accessors for steps
extension LocalTask {

    @objc(addStepsObject:)
    @NSManaged public func addToSteps(_ value: LocalTaskStep)

    @objc(removeStepsObject:)
    @NSManaged public func removeFromSteps(_ value: LocalTaskStep)

    @objc(addSteps:)
    @NSManaged public func addToSteps(_ values: NSSet)

    @objc(removeSteps:)
    @NSManaged public func removeFromSteps(_ values: NSSet)

}

// MARK: Generated accessors for attachments
extension LocalTask {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: LocalTaskAttachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: LocalTaskAttachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}