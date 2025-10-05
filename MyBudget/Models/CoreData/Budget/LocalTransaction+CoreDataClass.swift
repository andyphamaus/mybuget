import Foundation
import CoreData

@objc(LocalTransaction)
public class LocalTransaction: NSManagedObject {
    
    /// Creates a new transaction
    static func create(in context: NSManagedObjectContext) -> LocalTransaction {
        let transaction = LocalTransaction(context: context)
        transaction.id = "txn-\(UUID().uuidString.lowercased())"
        transaction.createdAt = Date()
        transaction.updatedAt = Date()
        return transaction
    }
    
    /// Fetches transactions for a specific period
    static func fetchTransactions(for periodId: String, in context: NSManagedObjectContext) -> [LocalTransaction] {
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@", periodId)
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Fetches transactions for a specific category in a period
    static func fetchTransactions(categoryId: String, periodId: String, in context: NSManagedObjectContext) -> [LocalTransaction] {
        let request: NSFetchRequest<LocalTransaction> = LocalTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "category.id == %@ AND period.id == %@", categoryId, periodId)
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Calculates total amount for transactions
    static func calculateTotal(transactions: [LocalTransaction]) -> Int64 {
        return transactions.reduce(0) { $0 + $1.amountCents }
    }
    
    /// Groups transactions by type
    static func groupByType(transactions: [LocalTransaction]) -> (income: [LocalTransaction], expense: [LocalTransaction]) {
        let income = transactions.filter { $0.type == "INCOME" }
        let expense = transactions.filter { $0.type == "EXPENSE" }
        return (income, expense)
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