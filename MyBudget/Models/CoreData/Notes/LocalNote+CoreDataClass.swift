import Foundation
import CoreData

@objc(LocalNote)
public class LocalNote: NSManagedObject, Identifiable {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalNote.entity(), insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = false
        self.isLocked = false
        self.colorTheme = "default"
        self.title = ""
        self.content = ""
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    var isEmpty: Bool {
        return (title ?? "").isEmpty && (content ?? "").isEmpty
    }
    
    var previewContent: String {
        let text = content ?? ""
        return String(text.prefix(100))
    }
    
    var hasReminder: Bool {
        guard let reminder = reminderAt else { return false }
        return reminder > Date()
    }
    
    // Helper to get sorted tags
    var sortedTags: [LocalNoteTag] {
        let tagsSet = tags as? Set<LocalNoteTag> ?? []
        return tagsSet.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    // Helper to get sorted attachments
    var sortedAttachments: [LocalNoteAttachment] {
        let attachmentsSet = attachments as? Set<LocalNoteAttachment> ?? []
        return attachmentsSet.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
    }
}