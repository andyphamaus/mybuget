import Foundation
import CoreData

extension LocalSmartInsight {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalSmartInsight> {
        return NSFetchRequest<LocalSmartInsight>(entityName: "LocalSmartInsight")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var title: String?
    @NSManaged public var insightDescription: String?
    @NSManaged public var priority: Int16
    @NSManaged public var isActionable: Bool
    @NSManaged public var relatedCategoryId: String?
    @NSManaged public var relatedPeriodId: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var isRead: Bool
    @NSManaged public var isDismissed: Bool
    @NSManaged public var uniqueKey: String?

}

extension LocalSmartInsight : Identifiable {

}