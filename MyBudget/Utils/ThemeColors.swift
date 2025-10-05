import SwiftUI

// MARK: - App Theme System
enum AppColorTheme: String, CaseIterable, Identifiable {
    case vibrant = "vibrant"
    case ocean = "ocean" 
    case sunset = "sunset"
    case forest = "forest"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .vibrant: return "Vibrant"
        case .ocean: return "Ocean Breeze"
        case .sunset: return "Sunset Glow"
        case .forest: return "Forest Dream"
        }
    }
    
    var description: String {
        switch self {
        case .vibrant: return "Bold and energetic colors"
        case .ocean: return "Cool blues and teals"
        case .sunset: return "Warm oranges and pinks"
        case .forest: return "Natural greens and earth tones"
        }
    }
}

// MARK: - Centralized Theme Color Management
struct ThemeColors {
    
    static var current: AppColorTheme = .vibrant // Default theme
    
    // MARK: - Module Colors Based on Selected Theme
    struct Home {
        static var primary: Color {
            switch current {
            case .vibrant: return Color(red: 1.0, green: 0.6, blue: 0.2)    // Orange
            case .ocean: return Color(red: 0.2, green: 0.7, blue: 0.9)      // Light Blue
            case .sunset: return Color(red: 1.0, green: 0.4, blue: 0.3)     // Coral
            case .forest: return Color(red: 0.8, green: 0.6, blue: 0.3)     // Golden Brown
            }
        }
        
        static var secondary: Color {
            switch current {
            case .vibrant: return Color(red: 0.9, green: 0.5, blue: 0.1)    // Darker Orange
            case .ocean: return Color(red: 0.1, green: 0.6, blue: 0.8)      // Darker Blue
            case .sunset: return Color(red: 0.9, green: 0.3, blue: 0.2)     // Darker Coral
            case .forest: return Color(red: 0.7, green: 0.5, blue: 0.2)     // Darker Golden Brown
            }
        }
        
        static var gradient: LinearGradient {
            LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
        }
    }
    
    struct Tasks {
        static var primary: Color {
            switch current {
            case .vibrant: return Color.blue                                 // Blue
            case .ocean: return Color(red: 0.1, green: 0.5, blue: 0.8)      // Deep Blue
            case .sunset: return Color(red: 0.8, green: 0.4, blue: 0.9)     // Purple Pink
            case .forest: return Color(red: 0.2, green: 0.6, blue: 0.4)     // Forest Green
            }
        }
        
        static var secondary: Color {
            switch current {
            case .vibrant: return Color.blue.opacity(0.9)                   // Lighter Blue
            case .ocean: return Color(red: 0.0, green: 0.4, blue: 0.7)      // Darker Deep Blue
            case .sunset: return Color(red: 0.7, green: 0.3, blue: 0.8)     // Darker Purple Pink
            case .forest: return Color(red: 0.1, green: 0.5, blue: 0.3)     // Darker Forest Green
            }
        }
        
        static var gradient: LinearGradient {
            LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
        }
    }
    
    struct Budget {
        static var primary: Color {
            switch current {
            case .vibrant: return Color(red: 0.4, green: 0.8, blue: 0.6)    // Green
            case .ocean: return Color(red: 0.2, green: 0.8, blue: 0.7)      // Turquoise
            case .sunset: return Color(red: 1.0, green: 0.7, blue: 0.3)     // Golden Orange
            case .forest: return Color(red: 0.3, green: 0.7, blue: 0.4)     // Emerald Green
            }
        }
        
        static var secondary: Color {
            switch current {
            case .vibrant: return Color(red: 0.3, green: 0.7, blue: 0.5)    // Darker Green
            case .ocean: return Color(red: 0.1, green: 0.7, blue: 0.6)      // Darker Turquoise
            case .sunset: return Color(red: 0.9, green: 0.6, blue: 0.2)     // Darker Golden Orange
            case .forest: return Color(red: 0.2, green: 0.6, blue: 0.3)     // Darker Emerald Green
            }
        }
        
        static var gradient: LinearGradient {
            LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
        }
    }
    
    struct Notes {
        static var primary: Color {
            switch current {
            case .vibrant: return Color(red: 0.6, green: 0.3, blue: 0.8)    // Purple
            case .ocean: return Color(red: 0.4, green: 0.6, blue: 0.9)      // Periwinkle
            case .sunset: return Color(red: 0.9, green: 0.5, blue: 0.7)     // Rose Pink
            case .forest: return Color(red: 0.5, green: 0.4, blue: 0.6)     // Lavender Gray
            }
        }
        
        static var secondary: Color {
            switch current {
            case .vibrant: return Color(red: 0.5, green: 0.2, blue: 0.7)    // Darker Purple
            case .ocean: return Color(red: 0.3, green: 0.5, blue: 0.8)      // Darker Periwinkle
            case .sunset: return Color(red: 0.8, green: 0.4, blue: 0.6)     // Darker Rose Pink
            case .forest: return Color(red: 0.4, green: 0.3, blue: 0.5)     // Darker Lavender Gray
            }
        }
        
        static var gradient: LinearGradient {
            LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
        }
    }
    
    struct Settings {
        static var primary: Color {
            switch current {
            case .vibrant: return Color(red: 0.2, green: 0.8, blue: 0.8)    // Teal
            case .ocean: return Color(red: 0.3, green: 0.8, blue: 0.6)      // Sea Green
            case .sunset: return Color(red: 0.8, green: 0.6, blue: 0.4)     // Peach
            case .forest: return Color(red: 0.6, green: 0.5, blue: 0.4)     // Mushroom Brown
            }
        }
        
        static var secondary: Color {
            switch current {
            case .vibrant: return Color(red: 0.1, green: 0.7, blue: 0.7)    // Darker Teal
            case .ocean: return Color(red: 0.2, green: 0.7, blue: 0.5)      // Darker Sea Green
            case .sunset: return Color(red: 0.7, green: 0.5, blue: 0.3)     // Darker Peach
            case .forest: return Color(red: 0.5, green: 0.4, blue: 0.3)     // Darker Mushroom Brown
            }
        }
        
        static var gradient: LinearGradient {
            LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
        }
    }
    
    // MARK: - Tab Colors for Current Theme
    static func tabColor(for index: Int) -> Color {
        switch index {
        case 0: return Home.primary
        case 1: return Tasks.primary
        case 2: return Budget.primary
        case 3: return Notes.primary
        case 4: return Settings.primary
        default: return Home.primary
        }
    }
    
    // MARK: - Theme Management
    static func setTheme(_ theme: AppColorTheme) {
        current = theme
        // Save to UserDefaults
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
    }
    
    static func loadSavedTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppColorTheme(rawValue: savedTheme) {
            current = theme
        }
    }
}

/*
Usage Examples:
1. Background gradient: .background(ThemeColors.Home.gradient)
2. Tab icon color: .foregroundColor(ThemeColors.Home.primary) 
3. Button color: .backgroundColor(ThemeColors.Notes.primary)

Theme Management:
- ThemeColors.setTheme(.ocean) // Switch to Ocean theme
- ThemeColors.loadSavedTheme() // Load saved theme on app start
- ThemeColors.current // Get current theme

Benefits:
- 4 beautiful theme options for users
- Single place to change all colors
- Automatic saving/loading of user preference
- Type-safe color references
- Consistent theming across all modules
*/