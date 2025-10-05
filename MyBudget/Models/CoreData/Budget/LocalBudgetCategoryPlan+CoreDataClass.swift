import Foundation
import CoreData

@objc(LocalBudgetCategoryPlan)
public class LocalBudgetCategoryPlan: NSManagedObject {
    
    /// Creates a new budget category plan
    static func create(in context: NSManagedObjectContext) -> LocalBudgetCategoryPlan {
        let plan = LocalBudgetCategoryPlan(context: context)
        plan.id = "plan-\(UUID().uuidString.lowercased())"
        plan.updatedAt = Date()
        return plan
    }
    
    /// Creates or updates a plan for a category in a period
    static func createOrUpdate(periodId: String, categoryId: String, type: String, amountCents: Int64, notes: String?, in context: NSManagedObjectContext) -> LocalBudgetCategoryPlan {
        // Check if plan already exists
        let request: NSFetchRequest<LocalBudgetCategoryPlan> = LocalBudgetCategoryPlan.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@ AND category.id == %@", periodId, categoryId)
        request.fetchLimit = 1
        
        do {
            if let existingPlan = try context.fetch(request).first {
                // Update existing plan
                existingPlan.type = type
                existingPlan.amountCents = amountCents
                existingPlan.notes = notes
                existingPlan.updatedAt = Date()
                return existingPlan
            }
        } catch {
        }
        
        // Create new plan
        let newPlan = LocalBudgetCategoryPlan.create(in: context)
        newPlan.type = type
        newPlan.amountCents = amountCents
        newPlan.notes = notes
        return newPlan
    }
    
    /// Fetches all plans for a period
    static func fetchPlans(for periodId: String, in context: NSManagedObjectContext) -> [LocalBudgetCategoryPlan] {
        let request: NSFetchRequest<LocalBudgetCategoryPlan> = LocalBudgetCategoryPlan.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@", periodId)
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Converts amount from cents to currency value
    var amountInCurrency: Double {
        return Double(amountCents) / 100.0
    }
    
    /// Sets amount in currency (converts to cents)
    func setAmount(_ amount: Double) {
        self.amountCents = Int64(amount * 100)
    }
}