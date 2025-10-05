import Foundation
import CoreData

@objc(LocalUser)
public class LocalUser: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: LocalUser.entity(), insertInto: context)
        self.id = UUID()
        self.createdDate = Date()
        self.totalPoints = 0
        self.currentLevel = "Beginner"
    }
    
    func calculateCurrentLevel() -> String {
        switch totalPoints {
        case 0..<100: return "Beginner"
        case 100..<250: return "Intermediate"
        case 250..<500: return "Advanced"
        case 500..<1000: return "Expert"
        default: return "Master"
        }
    }
    
    func addPoints(_ points: Int32) {
        let oldLevel = calculateCurrentLevel()
        totalPoints += points
        let newLevel = calculateCurrentLevel()
        currentLevel = newLevel
        
        // Check if leveled up
        if oldLevel != newLevel {
            // Post notification for level up
            NotificationCenter.default.post(name: NSNotification.Name("UserLeveledUp"), object: nil, userInfo: [
                "oldLevel": oldLevel,
                "newLevel": newLevel,
                "totalPoints": totalPoints
            ])
        }
    }
    
    // MARK: - Theme Management
    
    var currentTheme: AppColorTheme {
        get {
            guard let themeString = UserDefaults.standard.string(forKey: "selectedTheme"),
                  let theme = AppColorTheme(rawValue: themeString) else {
                return .vibrant // Default fallback
            }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedTheme")
            ThemeColors.setTheme(newValue)
        }
    }
    
    func applyTheme() {
        ThemeColors.setTheme(currentTheme)
    }
}