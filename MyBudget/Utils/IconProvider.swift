import SwiftUI

/// Icon provider that handles both Streamline icons and SF Symbols fallbacks
class IconProvider {
    static let shared = IconProvider()
    
    private init() {}
    
    /// Get icon name for a category, with fallback to SF Symbols
    func getIconName(for category: String, iconClass: String? = nil) -> String {
        // First try to map from API iconClass
        if let iconClass = iconClass {
            return mapIconClass(iconClass)
        }
        
        // Fallback to category-based mapping
        return mapCategoryToIcon(category)
    }
    
    /// Check if a custom Streamline icon exists in assets
    func hasCustomIcon(_ iconName: String) -> Bool {
        return UIImage(named: iconName) != nil
    }
    
    /// Get the final icon name with fallback logic
    func getFinalIconName(_ streamlineIconName: String) -> String {
        // Check if custom Streamline icon exists
        if hasCustomIcon(streamlineIconName) {
            return streamlineIconName
        }
        
        // Fallback to SF Symbol
        return getStreamlineToSFSymbolFallback(streamlineIconName)
    }
    
    // MARK: - Private Methods
    
    private func mapIconClass(_ iconClass: String) -> String {
        let streamlineIcon: String
        
        switch iconClass {
        case "fa-bolt":
            streamlineIcon = "streamline-bolt"
        case "fa-heart":
            streamlineIcon = "streamline-heart-pulse"
        case "fa-dollar-sign", "fa-dollar":
            streamlineIcon = "streamline-coin-dollar"
        case "fa-shield-alt", "fa-shield":
            streamlineIcon = "streamline-shield-check"
        case "fa-list":
            streamlineIcon = "streamline-list-check"
        case "fa-home":
            streamlineIcon = "streamline-house"
        case "fa-car":
            streamlineIcon = "streamline-car"
        case "fa-briefcase":
            streamlineIcon = "streamline-briefcase"
        case "fa-graduation-cap":
            streamlineIcon = "streamline-graduation-cap"
        default:
            streamlineIcon = "streamline-tag"
        }
        
        return getFinalIconName(streamlineIcon)
    }
    
    private func mapCategoryToIcon(_ category: String) -> String {
        let streamlineIcon: String
        
        switch category.lowercased() {
        case "utilities":
            streamlineIcon = "streamline-bolt"
        case "health":
            streamlineIcon = "streamline-heart-pulse"
        case "financial":
            streamlineIcon = "streamline-coin-dollar"
        case "insurance":
            streamlineIcon = "streamline-shield-check"
        case "general":
            streamlineIcon = "streamline-list-check"
        default:
            streamlineIcon = "streamline-tag"
        }
        
        return getFinalIconName(streamlineIcon)
    }
    
    private func getStreamlineToSFSymbolFallback(_ streamlineIcon: String) -> String {
        switch streamlineIcon {
        case "streamline-bolt":
            return "bolt.fill"
        case "streamline-heart-pulse":
            return "heart.fill"
        case "streamline-coin-dollar":
            return "dollarsign.circle.fill"
        case "streamline-shield-check":
            return "shield.fill"
        case "streamline-list-check":
            return "list.bullet"
        case "streamline-house":
            return "house.fill"
        case "streamline-car":
            return "car.fill"
        case "streamline-briefcase":
            return "briefcase.fill"
        case "streamline-graduation-cap":
            return "graduationcap.fill"
        case "streamline-tag":
            return "tag.fill"
        case "streamline-apps":
            return "apps.iphone"
        default:
            return "tag.fill"
        }
    }
}

// MARK: - SwiftUI Extensions
extension Image {
    /// Create image with automatic fallback from Streamline to SF Symbols
    init(iconName: String) {
        let finalIconName = IconProvider.shared.getFinalIconName(iconName)
        
        if IconProvider.shared.hasCustomIcon(finalIconName) {
            // Use custom asset icon
            self.init(finalIconName)
        } else {
            // Use SF Symbol
            self.init(systemName: finalIconName)
        }
    }
}