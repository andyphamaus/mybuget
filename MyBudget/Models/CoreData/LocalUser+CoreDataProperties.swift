import Foundation
import CoreData

extension LocalUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalUser> {
        return NSFetchRequest<LocalUser>(entityName: "LocalUser")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var email: String?
    @NSManaged public var fullName: String?
    @NSManaged public var profileImageUrl: String?
    @NSManaged public var totalPoints: Int32
    @NSManaged public var currentLevel: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var smartNotificationsEnabled: Bool
    @NSManaged public var isPremiumUser: Bool

}