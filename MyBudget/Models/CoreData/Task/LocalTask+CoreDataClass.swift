import Foundation
import CoreData

@objc(LocalTask)
public class LocalTask: NSManagedObject, Identifiable {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalTask.entity(), insertInto: context)
        self.id = UUID()
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.status = "pending"
        self.priority = 1
        self.isCompleted = false
        self.isFavorite = false
        self.pointEarned = 0
        self.sourceType = "custom"
    }
    
    var stepsArray: [LocalTaskStep] {
        let set = steps as? Set<LocalTaskStep> ?? []
        return set.sorted { $0.order < $1.order }
    }
    
    var completedStepsCount: Int {
        return stepsArray.filter { $0.isCompleted }.count
    }
    
    var totalStepsCount: Int {
        return stepsArray.count
    }
    
    var progressPercentage: Double {
        guard totalStepsCount > 0 else { return 0.0 }
        return Double(completedStepsCount) / Double(totalStepsCount)
    }
    
    func markAsCompleted() {
        isCompleted = true
        status = "done"
        completedDate = Date()
        modifiedDate = Date()
        
        // Calculate points earned
        pointEarned = calculatePointsEarned()
        
        // Add points to user
        if let user = getCurrentUser() {
            user.addPoints(pointEarned)
        }
    }
    
    func markAsIncomplete() {
        isCompleted = false
        status = "pending"
        completedDate = nil
        modifiedDate = Date()
        
        // Remove points from user
        if pointEarned > 0, let user = getCurrentUser() {
            user.totalPoints -= pointEarned
            user.currentLevel = user.calculateCurrentLevel()
            pointEarned = 0
        }
    }
    
    private func calculatePointsEarned() -> Int32 {
        // Base points by priority
        var points: Int32 = 10
        switch priority {
        case 1: points = 10  // Low
        case 2: points = 20  // Medium
        case 3: points = 30  // High
        default: points = 10
        }
        
        // Bonus for completing all steps
        if totalStepsCount > 0 && completedStepsCount == totalStepsCount {
            points += 10
        }
        
        // Bonus for completing before due date
        if let dueDate = dueDate, Date() < dueDate {
            points += 5
        }
        
        return points
    }
    
    private func getCurrentUser() -> LocalUser? {
        let context = managedObjectContext ?? PersistenceController.shared.viewContext
        let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            return nil
        }
    }
    
    func addStep(name: String) {
        guard let context = managedObjectContext else {
            print("❌ Error: Task has no managedObjectContext")
            return
        }
        let step = LocalTaskStep(context: context)
        step.stepName = name
        step.order = Int16(stepsArray.count)
        step.task = self
        modifiedDate = Date()
    }
    
    func removeStep(_ step: LocalTaskStep) {
        let context = managedObjectContext ?? PersistenceController.shared.viewContext
        context.delete(step)
        
        // Reorder remaining steps
        let remainingSteps = stepsArray.filter { $0 != step }
        for (index, step) in remainingSteps.enumerated() {
            step.order = Int16(index)
        }
        
        modifiedDate = Date()
    }
}