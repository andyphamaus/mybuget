import Foundation
import CoreData

extension LocalBudgetSection {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalBudgetSection> {
        return NSFetchRequest<LocalBudgetSection>(entityName: "LocalBudgetSection")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var typeHint: String?
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var budget: LocalBudget?
    @NSManaged public var categoryMappings: NSSet?
}

extension LocalBudgetSectionCategory {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalBudgetSectionCategory> {
        return NSFetchRequest<LocalBudgetSectionCategory>(entityName: "LocalBudgetSectionCategory")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var budget: LocalBudget?
    @NSManaged public var section: LocalBudgetSection?
    @NSManaged public var category: LocalCategory?
}

extension LocalBudgetCategoryPlan {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalBudgetCategoryPlan> {
        return NSFetchRequest<LocalBudgetCategoryPlan>(entityName: "LocalBudgetCategoryPlan")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var amountCents: Int64
    @NSManaged public var notes: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var period: LocalBudgetPeriod?
    @NSManaged public var category: LocalCategory?
}

extension LocalRecurringTransactionSeries {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalRecurringTransactionSeries> {
        return NSFetchRequest<LocalRecurringTransactionSeries>(entityName: "LocalRecurringTransactionSeries")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var amountCents: Int64
    @NSManaged public var startDate: String?
    @NSManaged public var endCondition: String?
    @NSManaged public var untilDate: String?
    @NSManaged public var count: Int32
    @NSManaged public var frequency: String?
    @NSManaged public var interval: Int32
    @NSManaged public var isPaused: Bool
    @NSManaged public var nextRunDate: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var budget: LocalBudget?
    @NSManaged public var category: LocalCategory?
    @NSManaged public var transactions: NSSet?
}

extension LocalLiability {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalLiability> {
        return NSFetchRequest<LocalLiability>(entityName: "LocalLiability")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var lender: String?
    @NSManaged public var principalCents: Int64
    @NSManaged public var currencyCode: String?
    @NSManaged public var interestRateBps: Int32
    @NSManaged public var compounding: String?
    @NSManaged public var startDate: String?
    @NSManaged public var endDate: String?
    @NSManaged public var paymentDayOfMonth: Int32
    @NSManaged public var status: String?
    @NSManaged public var currentBalanceCents: Int64
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var budget: LocalBudget?
    @NSManaged public var payments: NSSet?
}