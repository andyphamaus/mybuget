import Foundation
import CoreData

extension LocalPeriodSection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalPeriodSection> {
        return NSFetchRequest<LocalPeriodSection>(entityName: "LocalPeriodSection")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var period: LocalBudgetPeriod?
    @NSManaged public var categoryMappings: NSSet?

}

// MARK: Generated accessors for categories
extension LocalPeriodSection {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: LocalPeriodSectionCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: LocalPeriodSectionCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

extension LocalPeriodSection : Identifiable {

}