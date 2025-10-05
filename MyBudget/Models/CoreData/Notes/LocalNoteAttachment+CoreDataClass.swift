import Foundation
import CoreData

@objc(LocalNoteAttachment)
public class LocalNoteAttachment: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalNoteAttachment.entity(), insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
    }
    
    // Helper computed property for attachment type enum
    var attachmentType: AttachmentType {
        get {
            return AttachmentType(rawValue: type ?? "") ?? .document
        }
        set {
            type = newValue.rawValue
        }
    }
    
    enum AttachmentType: String, CaseIterable {
        case image = "image"
        case audio = "audio"
        case document = "document"
        case voice = "voice"
        
        var systemImage: String {
            switch self {
            case .image: return "photo"
            case .audio: return "waveform"
            case .document: return "doc"
            case .voice: return "mic"
            }
        }
    }
    
    // Helper to get file size in readable format
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}