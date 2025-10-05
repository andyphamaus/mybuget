import Foundation
import CoreData
import SwiftUI

@objc(LocalNoteTag)
public class LocalNoteTag: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalNoteTag.entity(), insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.colorHex = "#808080" // Default gray color
        self.usageCount = 0
        self.lastUsedAt = nil
    }
    
    // Helper to convert hex string to Color
    var color: Color {
        return Color(hex: colorHex ?? "#808080")
    }
    
    // Helper to set color from SwiftUI Color (stores as hex)
    func setColor(_ color: Color) {
        self.colorHex = color.toHex()
    }
    
    // Helper to get sorted notes
    var sortedNotes: [LocalNote] {
        let notesSet = notes as? Set<LocalNote> ?? []
        return notesSet.sorted { ($0.updatedAt ?? Date()) > ($1.updatedAt ?? Date()) }
    }
    
    // Track usage when tag is used
    func incrementUsage() {
        usageCount += 1
        lastUsedAt = Date()
    }
    
    // Computed properties for statistics
    var isPopular: Bool {
        return usageCount >= 5 // Tag used 5+ times is considered popular
    }
    
    var isRecentlyUsed: Bool {
        guard let lastUsed = lastUsedAt else { return false }
        return Date().timeIntervalSince(lastUsed) <= 7 * 24 * 60 * 60 // Used within last week
    }
    
    var notesCount: Int {
        return (notes as? Set<LocalNote>)?.count ?? 0
    }
}

// MARK: - Color Extensions for Hex Conversion

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}