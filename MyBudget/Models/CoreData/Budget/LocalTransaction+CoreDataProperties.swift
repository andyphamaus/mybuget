import Foundation
import CoreData

extension LocalTransaction {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalTransaction> {
        return NSFetchRequest<LocalTransaction>(entityName: "LocalTransaction")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var amountCents: Int64
    @NSManaged public var transactionDate: String?
    @NSManaged public var notes: String?
    @NSManaged public var attachmentPath: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships
    @NSManaged public var budget: LocalBudget?
    @NSManaged public var period: LocalBudgetPeriod?
    @NSManaged public var category: LocalCategory?
    @NSManaged public var recurringSeries: LocalRecurringTransactionSeries?
    @NSManaged public var liability: LocalLiability?
}