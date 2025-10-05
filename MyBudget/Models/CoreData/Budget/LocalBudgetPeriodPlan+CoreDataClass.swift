import Foundation
import CoreData

@objc(LocalBudgetPeriodPlan)
public class LocalBudgetPeriodPlan: NSManagedObject {
    
    static func create(in context: NSManagedObjectContext) -> LocalBudgetPeriodPlan {
        let plan = LocalBudgetPeriodPlan(context: context)
        plan.id = "plan-\(UUID().uuidString.lowercased())"
        plan.updatedAt = Date()
        return plan
    }
    
    /// Fetches all plans for a period
    static func fetchPlans(for periodId: String, in context: NSManagedObjectContext) -> [LocalBudgetPeriodPlan] {
        let request: NSFetchRequest<LocalBudgetPeriodPlan> = LocalBudgetPeriodPlan.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@", periodId)
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.headCategory.displayOrder", ascending: true),
            NSSortDescriptor(key: "category.displayOrder", ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Currency amount (convert from cents)
    var amountInCurrency: Double {
        return Double(amountCents) / 100.0
    }
    
    /// Sets the planned amount (convert to cents)
    func setAmount(_ amount: Double) {
        self.amountCents = Int64(amount * 100.0)
        self.updatedAt = Date()
    }
}