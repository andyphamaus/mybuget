import Foundation
import CoreData

@objc(LocalSmartInsight)
public class LocalSmartInsight: NSManagedObject {

}


// MARK: - Convenience Methods
extension LocalSmartInsight {
    
    /// Create a unique key for insight deduplication (now includes period ID)
    static func createUniqueKey(type: String, title: String, categoryId: String?, periodId: String?) -> String {
        let components = [type, title, categoryId ?? "", periodId ?? ""].joined(separator: "_")
        return components.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    /// Convert to SmartInsight struct
    func toSmartInsight() -> SmartInsight {
        return SmartInsight(
            id: self.id ?? UUID(),
            type: InsightType(stringValue: self.type ?? "") ?? .recommendation,
            title: self.title ?? "",
            description: self.insightDescription ?? "",
            priority: InsightPriority(rawValue: Int(self.priority)) ?? .medium,
            actionable: self.isActionable,
            relatedCategoryId: self.relatedCategoryId,
            createdDate: self.createdDate ?? Date(),
            isRead: self.isRead
        )
    }
    
    /// Create from SmartInsight struct
    static func fromSmartInsight(_ insight: SmartInsight, context: NSManagedObjectContext) -> LocalSmartInsight {
        let entity = LocalSmartInsight(context: context)
        entity.id = insight.id
        entity.type = insight.type.stringValue
        entity.title = insight.title
        entity.insightDescription = insight.description
        entity.priority = Int16(insight.priority.rawValue)
        entity.isActionable = insight.actionable
        entity.relatedCategoryId = insight.relatedCategoryId
        entity.createdDate = insight.createdDate
        entity.isRead = insight.isRead
        entity.isDismissed = false
        entity.uniqueKey = createUniqueKey(
            type: insight.type.stringValue,
            title: insight.title,
            categoryId: insight.relatedCategoryId,
            periodId: nil // Will be set later when we have period context
        )
        return entity
    }
}

// MARK: - Extensions for InsightType and Priority
extension InsightType {
    init?(stringValue: String) {
        switch stringValue {
        case "budgetAlert": self = .budgetAlert
        case "spendingPattern": self = .spendingPattern
        case "anomaly": self = .anomaly
        case "recommendation": self = .recommendation
        case "forecast": self = .forecast
        case "healthScore": self = .healthScore
        default: return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .budgetAlert: return "budgetAlert"
        case .spendingPattern: return "spendingPattern"
        case .anomaly: return "anomaly"
        case .recommendation: return "recommendation"
        case .forecast: return "forecast"
        case .healthScore: return "healthScore"
        }
    }
}

