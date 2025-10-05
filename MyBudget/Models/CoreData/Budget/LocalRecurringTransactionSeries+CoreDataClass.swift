import Foundation
import CoreData

@objc(LocalRecurringTransactionSeries)
public class LocalRecurringTransactionSeries: NSManagedObject {
    
    /// Creates a new recurring transaction series
    static func create(in context: NSManagedObjectContext) -> LocalRecurringTransactionSeries {
        let series = LocalRecurringTransactionSeries(context: context)
        series.id = "rts-\(UUID().uuidString.lowercased())"
        series.isPaused = false
        series.createdAt = Date()
        series.updatedAt = Date()
        return series
    }
}