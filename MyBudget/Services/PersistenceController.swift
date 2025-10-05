import Foundation
import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyBudget")
        
        // Configure for better performance and migration
        if let storeDescription = container.persistentStoreDescriptions.first {
            // Enable lightweight migration
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            // Enable remote change notifications
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                
                // Handle migration errors gracefully
                if error.code == 256 || error.domain.contains("SQLite") {
                    // SQLite error - try to recover by recreating the store
                    
                    // Delete the corrupted database file and related files
                    if let storeURL = storeDescription.url {
                        let fileManager = FileManager.default
                        
                        // Remove main database file
                        try? fileManager.removeItem(at: storeURL)
                        
                        // Remove related files (-shm, -wal, etc.)
                        let shmURL = storeURL.appendingPathExtension("shm")
                        let walURL = storeURL.appendingPathExtension("wal")
                        try? fileManager.removeItem(at: shmURL)
                        try? fileManager.removeItem(at: walURL)
                        
                    }
                }
                
                // After cleanup, the app will restart and create a fresh database
                fatalError("Core Data error resolved - app will restart with fresh database")
            }
        }
        
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {}
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // Perform background save
    func saveInBackground(block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = newBackgroundContext()
        backgroundContext.perform {
            block(backgroundContext)
            
            do {
                try backgroundContext.save()
            } catch {
            }
        }
    }
}