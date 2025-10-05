import Foundation
import CoreData

extension LocalBudgetPeriodPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalBudgetPeriodPlan> {
        return NSFetchRequest<LocalBudgetPeriodPlan>(entityName: "LocalBudgetPeriodPlan")
    }

    @NSManaged public var id: String?
    @NSManaged public var amountCents: Int64
    @NSManaged public var type: String?
    @NSManaged public var notes: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var period: LocalBudgetPeriod?
    @NSManaged public var category: LocalCategory?

}

extension LocalBudgetPeriodPlan : Identifiable {

}