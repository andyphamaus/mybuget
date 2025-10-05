import Foundation
import CoreData

@objc(LocalBudgetPeriod)
public class LocalBudgetPeriod: NSManagedObject {
    
    /// Creates a new budget period
    static func create(in context: NSManagedObjectContext) -> LocalBudgetPeriod {
        let period = LocalBudgetPeriod(context: context)
        period.id = "prd-\(UUID().uuidString.lowercased())"
        period.status = "OPEN"
        period.createdAt = Date()
        return period
    }
    
    /// Fetches the current open period for a budget
    static func fetchCurrentPeriod(for budgetId: String, in context: NSManagedObjectContext) -> LocalBudgetPeriod? {
        let request: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        request.predicate = NSPredicate(format: "budget.id == %@ AND status == %@ AND startDate <= %@ AND endDate >= %@",
                                       budgetId, "OPEN", today, today)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            return nil
        }
    }
    
    /// Fetches all periods for a budget, sorted by start date descending
    static func fetchAllPeriods(for budgetId: String, in context: NSManagedObjectContext) -> [LocalBudgetPeriod] {
        let request: NSFetchRequest<LocalBudgetPeriod> = LocalBudgetPeriod.fetchRequest()
        
        request.predicate = NSPredicate(format: "budget.id == %@", budgetId)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Checks if a date falls within this period
    func contains(date: Date) -> Bool {
        guard let startDate = self.startDate,
              let endDate = self.endDate else { return false }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return dateString >= startDate && dateString <= endDate
    }
    
    /// Gets all transactions for this period
    func getTransactions() -> [LocalTransaction] {
        guard let transactions = self.transactions as? Set<LocalTransaction> else { return [] }
        return Array(transactions).sorted { t1, t2 in
            guard let d1 = t1.transactionDate, let d2 = t2.transactionDate else { return false }
            return d1 > d2
        }
    }
    
    /// Gets all plans for this period
    func getPlans() -> [LocalBudgetCategoryPlan] {
        guard let plans = self.plans as? Set<LocalBudgetCategoryPlan> else { return [] }
        return Array(plans)
    }
}