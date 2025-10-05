import Foundation
import CoreData

extension LocalBudgetPeriod {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalBudgetPeriod> {
        return NSFetchRequest<LocalBudgetPeriod>(entityName: "LocalBudgetPeriod")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var periodType: String?
    @NSManaged public var name: String?
    @NSManaged public var startDate: String?
    @NSManaged public var endDate: String?
    @NSManaged public var status: String?
    @NSManaged public var sequence: Int32
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var budget: LocalBudget?
    @NSManaged public var plans: NSSet?
    @NSManaged public var transactions: NSSet?
}