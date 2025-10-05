import Foundation
import CoreData

@objc(LocalPeriodSection)
public class LocalPeriodSection: NSManagedObject {
    
    static func create(in context: NSManagedObjectContext) -> LocalPeriodSection {
        let section = LocalPeriodSection(context: context)
        section.id = "section-\(UUID().uuidString.lowercased())"
        section.createdAt = Date()
        return section
    }
    
    /// Fetches sections for a specific period
    static func fetchSections(for periodId: String, in context: NSManagedObjectContext) -> [LocalPeriodSection] {
        let request: NSFetchRequest<LocalPeriodSection> = LocalPeriodSection.fetchRequest()
        request.predicate = NSPredicate(format: "period.id == %@", periodId)
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
}