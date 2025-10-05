import Foundation
import CoreData

extension LocalBudget {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalBudget> {
        return NSFetchRequest<LocalBudget>(entityName: "LocalBudget")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var userId: String?
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var color: String?
    @NSManaged public var currencyCode: String?
    @NSManaged public var createdAt: Date?
    
    // Relationships
    @NSManaged public var periods: NSSet?
    @NSManaged public var sections: NSSet?
    @NSManaged public var sectionCategoryMappings: NSSet?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var liabilities: NSSet?
    @NSManaged public var recurringSeries: NSSet?
}

// MARK: Generated accessors for relationships
extension LocalBudget {
    
    @objc(addPeriodsObject:)
    @NSManaged public func addToPeriods(_ value: LocalBudgetPeriod)
    
    @objc(removePeriodsObject:)
    @NSManaged public func removeFromPeriods(_ value: LocalBudgetPeriod)
    
    @objc(addPeriods:)
    @NSManaged public func addToPeriods(_ values: NSSet)
    
    @objc(removePeriods:)
    @NSManaged public func removeFromPeriods(_ values: NSSet)
    
    @objc(addSectionsObject:)
    @NSManaged public func addToSections(_ value: LocalBudgetSection)
    
    @objc(removeSectionsObject:)
    @NSManaged public func removeFromSections(_ value: LocalBudgetSection)
    
    @objc(addSections:)
    @NSManaged public func addToSections(_ values: NSSet)
    
    @objc(removeSections:)
    @NSManaged public func removeFromSections(_ values: NSSet)
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: LocalTransaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: LocalTransaction)
    
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
    
    @objc(addLiabilitiesObject:)
    @NSManaged public func addToLiabilities(_ value: LocalLiability)
    
    @objc(removeLiabilitiesObject:)
    @NSManaged public func removeFromLiabilities(_ value: LocalLiability)
    
    @objc(addLiabilities:)
    @NSManaged public func addToLiabilities(_ values: NSSet)
    
    @objc(removeLiabilities:)
    @NSManaged public func removeFromLiabilities(_ values: NSSet)
    
    @objc(addSectionCategoryMappingsObject:)
    @NSManaged public func addToSectionCategoryMappings(_ value: LocalBudgetSectionCategory)
    
    @objc(removeSectionCategoryMappingsObject:)
    @NSManaged public func removeFromSectionCategoryMappings(_ value: LocalBudgetSectionCategory)
    
    @objc(addSectionCategoryMappings:)
    @NSManaged public func addToSectionCategoryMappings(_ values: NSSet)
    
    @objc(removeSectionCategoryMappings:)
    @NSManaged public func removeFromSectionCategoryMappings(_ values: NSSet)
    
    @objc(addRecurringSeriesObject:)
    @NSManaged public func addToRecurringSeries(_ value: LocalRecurringTransactionSeries)
    
    @objc(removeRecurringSeriesObject:)
    @NSManaged public func removeFromRecurringSeries(_ value: LocalRecurringTransactionSeries)
    
    @objc(addRecurringSeries:)
    @NSManaged public func addToRecurringSeries(_ values: NSSet)
    
    @objc(removeRecurringSeries:)
    @NSManaged public func removeFromRecurringSeries(_ values: NSSet)
}