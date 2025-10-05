import Foundation
import CoreData

@objc(LocalBudget)
public class LocalBudget: NSManagedObject {
    
    /// Generates a unique identifier for a new budget
    static func generateId() -> String {
        return "bgt-\(UUID().uuidString.lowercased())"
    }
    
    /// Creates a new budget in the given context
    static func create(in context: NSManagedObjectContext) -> LocalBudget {
        let budget = LocalBudget(context: context)
        budget.id = generateId()
        budget.createdAt = Date()
        return budget
    }
    
    /// Fetches all budgets for a specific user
    static func fetchBudgets(for userId: String, in context: NSManagedObjectContext) -> [LocalBudget] {
        let request: NSFetchRequest<LocalBudget> = LocalBudget.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Gets the current active period for this budget
    func getCurrentPeriod() -> LocalBudgetPeriod? {
        guard let periods = self.periods as? Set<LocalBudgetPeriod> else { return nil }
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let nowString = dateFormatter.string(from: now)
        
        return periods.first { period in
            guard let startDate = period.startDate,
                  let endDate = period.endDate else { return false }
            return startDate <= nowString && nowString <= endDate && period.status == "OPEN"
        }
    }
    
    /// Creates a new period for this budget
    func createPeriod(type: String, startDate: Date, endDate: Date, in context: NSManagedObjectContext) throws -> LocalBudgetPeriod {
        let period = LocalBudgetPeriod(context: context)
        period.id = "prd-\(UUID().uuidString.lowercased())"
        
        // Ensure both objects are in the same context and budget still exists
        if self.managedObjectContext == context && !self.isDeleted {
            // Same context and object is valid, can use self directly
            period.budget = self
        } else {
            // Different context or object might be deleted, need to get the object from the target context
            do {
                // Check if the object still exists in the persistent store
                let budgetInContext = try context.existingObject(with: self.objectID) as? LocalBudget
                if let validBudget = budgetInContext, !validBudget.isDeleted {
                    period.budget = validBudget
                } else {
                    // Don't set the relationship if the budget is deleted
                    throw NSError(domain: "BudgetError", code: 1001, userInfo: [
                        NSLocalizedDescriptionKey: "Cannot create period: Budget object has been deleted"
                    ])
                }
            } catch {
                throw error
            }
        }
        period.periodType = type
        period.status = "OPEN"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        period.startDate = dateFormatter.string(from: startDate)
        period.endDate = dateFormatter.string(from: endDate)
        
        // Generate name based on type
        if type == "MONTHLY" {
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM yyyy"
            period.name = monthFormatter.string(from: startDate)
        } else if type == "QUARTERLY" {
            let quarter = Calendar.current.component(.quarter, from: startDate)
            let year = Calendar.current.component(.year, from: startDate)
            period.name = "Q\(quarter) \(year)"
        } else {
            period.name = "Custom Period"
        }
        
        // Calculate sequence
        let existingPeriods = (self.periods as? Set<LocalBudgetPeriod>) ?? []
        period.sequence = Int32(existingPeriods.count + 1)
        
        period.createdAt = Date()
        
        return period
    }
}