import Foundation
import CoreData

extension LocalNoteTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalNoteTag> {
        return NSFetchRequest<LocalNoteTag>(entityName: "LocalNoteTag")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var usageCount: Int32
    @NSManaged public var lastUsedAt: Date?
    @NSManaged public var notes: NSSet?

}

// MARK: Generated accessors for notes
extension LocalNoteTag {

    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: LocalNote)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: LocalNote)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)

}