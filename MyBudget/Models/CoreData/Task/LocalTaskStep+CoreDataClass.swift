import Foundation
import CoreData

@objc(LocalTaskStep)
public class LocalTaskStep: NSManagedObject, Identifiable {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalTaskStep.entity(), insertInto: context)
        self.id = UUID()
        self.isCompleted = false
    }
    
    func toggleCompletion() {
        isCompleted.toggle()
        task?.modifiedDate = Date()
        
        // Check if all steps are completed and mark task as completed
        if let task = task {
            let allStepsCompleted = task.stepsArray.allSatisfy { $0.isCompleted }
            if allStepsCompleted && !task.isCompleted {
                task.markAsCompleted()
            } else if !allStepsCompleted && task.isCompleted {
                // If task was completed but now has incomplete steps, mark as incomplete
                task.markAsIncomplete()
            }
        }
    }
}