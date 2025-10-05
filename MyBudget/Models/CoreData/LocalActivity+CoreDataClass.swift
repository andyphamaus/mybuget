import Foundation
import CoreData

@objc(LocalActivity)
public class LocalActivity: NSManagedObject, Identifiable {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalActivity.entity(), insertInto: context)
        self.id = UUID()
        self.timestamp = Date()
    }
    
    // Static method to create a new activity
    static func createActivity(
        context: NSManagedObjectContext,
        module: String,
        action: String,
        title: String,
        description: String? = nil,
        metadata: String? = nil
    ) -> LocalActivity {
        let activity = LocalActivity(context: context)
        activity.module = module
        activity.action = action
        activity.title = title
        activity.activityDescription = description
        activity.metadata = metadata
        
        do {
            try context.save()
        } catch {
        }
        
        return activity
    }
    
    // Helper method to log task activities
    static func logTaskActivity(
        context: NSManagedObjectContext,
        action: String,
        taskTitle: String,
        description: String? = nil
    ) {
        _ = createActivity(
            context: context,
            module: "Tasks",
            action: action,
            title: taskTitle,
            description: description
        )
    }
    
    // Helper method to log budget activities
    static func logBudgetActivity(
        context: NSManagedObjectContext,
        action: String,
        title: String,
        description: String? = nil,
        amount: String? = nil
    ) {
        let metadata = amount != nil ? "amount:\(amount!)" : nil
        createActivity(
            context: context,
            module: "Budget",
            action: action,
            title: title,
            description: description,
            metadata: metadata
        )
    }
    
    // Get formatted time string
    var timeAgo: String {
        guard let timestamp = timestamp else { return "" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    // Get icon for the activity based on module and action
    var icon: String {
        switch module {
        case "Tasks":
            switch action {
            case "created": return "plus.circle.fill"
            case "completed": return "checkmark.circle.fill"
            case "updated": return "pencil.circle.fill"
            case "deleted": return "trash.circle.fill"
            case "step_added": return "list.bullet.circle.fill"
            case "step_completed": return "checkmark.square.fill"
            default: return "list.bullet.circle.fill"
            }
        case "Budget":
            switch action {
            case "transaction_added": return "plus.circle.fill"
            case "transaction_updated": return "pencil.circle.fill"
            case "transaction_deleted": return "trash.circle.fill"
            case "budget_created": return "dollarsign.circle.fill"
            case "budget_updated": return "gear.circle.fill"
            case "category_added": return "folder.circle.fill"
            case "category_updated": return "folder.badge.gearshape.fill"
            default: return "dollarsign.circle.fill"
            }
        case "Notes":
            switch action {
            case "created": return "note.text.badge.plus"
            case "updated": return "pencil.and.outline"
            case "deleted": return "trash.circle.fill"
            case "pinned": return "pin.circle.fill"
            case "unpinned": return "pin.slash.circle.fill"
            default: return "note.text"
            }
        case "Profile":
            switch action {
            case "updated": return "person.circle.fill"
            case "settings_changed": return "gear.circle.fill"
            default: return "person.circle"
            }
        default:
            return "circle.fill"
        }
    }
    
    // Get color for the activity based on module
    var color: String {
        switch module {
        case "Tasks": return "blue"
        case "Budget": return "green"
        case "Notes": return "purple"
        case "Profile": return "orange"
        default: return "gray"
        }
    }
}