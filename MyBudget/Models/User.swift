import Foundation
import UIKit

enum AuthProvider: String, Codable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var fullName: String
    var profileImageURL: String?
    var authProvider: AuthProvider
    var createdDate: Date
    var lastLoginDate: Date
    
    
    // Gamification properties
    var totalPoints: Int = 0
    var currentLevelId: String?

    // Level details
    var currentLevelName: String?
    var currentLevelTitle: String?
    var currentLevelIconUrl: Int?
    var currentLevelIconDownloadUrl: String?

    // Budget app specific properties
    var budgetsCreated: Int = 0
    var categoriesCreated: Int = 0
    
    // Account status
    var isAdmin: Bool = false
    var isActive: Bool = true
    var isDeleted: Bool = false
    
    
    // Notification settings
    var isAllowAppleNotification: Bool = true
    var isAllowAndroidNotification: Bool = true
    var isAllowTaskReminder: Bool = true
    var isAllowHealthReminder: Bool = true
    var isAllowBudgetReminder: Bool = true
    
    init(id: String = UUID().uuidString, email: String, fullName: String, profileImageURL: String? = nil, authProvider: AuthProvider = .email, totalPoints: Int = 0, currentLevelId: String? = nil, currentLevelName: String? = nil, currentLevelTitle: String? = nil, currentLevelIconUrl: Int? = nil, currentLevelIconDownloadUrl: String? = nil, budgetsCreated: Int = 0, categoriesCreated: Int = 0, isAdmin: Bool = false, isActive: Bool = true, isDeleted: Bool = false) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.profileImageURL = profileImageURL
        self.authProvider = authProvider
        self.createdDate = Date()
        self.lastLoginDate = Date()
        self.totalPoints = totalPoints
        self.currentLevelId = currentLevelId
        self.currentLevelName = currentLevelName
        self.currentLevelTitle = currentLevelTitle
        self.currentLevelIconUrl = currentLevelIconUrl
        self.currentLevelIconDownloadUrl = currentLevelIconDownloadUrl
        self.isAdmin = isAdmin
        self.isActive = isActive
        self.isDeleted = isDeleted
        self.isAllowAppleNotification = true
        self.isAllowAndroidNotification = true
        self.isAllowTaskReminder = true
        self.isAllowHealthReminder = true
        self.isAllowBudgetReminder = true
    }
    
    // Custom decoder to handle backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        authProvider = try container.decode(AuthProvider.self, forKey: .authProvider)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastLoginDate = try container.decode(Date.self, forKey: .lastLoginDate)
        
        
        // Gamification properties (backward compatible - new fields)
        totalPoints = try container.decodeIfPresent(Int.self, forKey: .totalPoints) ?? 0
        currentLevelId = try container.decodeIfPresent(String.self, forKey: .currentLevelId)
        
        // Level details (backward compatible - newest fields)
        currentLevelName = try container.decodeIfPresent(String.self, forKey: .currentLevelName)
        currentLevelTitle = try container.decodeIfPresent(String.self, forKey: .currentLevelTitle)
        currentLevelIconUrl = try container.decodeIfPresent(Int.self, forKey: .currentLevelIconUrl)
        currentLevelIconDownloadUrl = try container.decodeIfPresent(String.self, forKey: .currentLevelIconDownloadUrl)
        
        // Account status (backward compatible - new fields)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        
        
        // Notification settings (backward compatible)
        isAllowAppleNotification = try container.decodeIfPresent(Bool.self, forKey: .isAllowAppleNotification) ?? true
        isAllowAndroidNotification = try container.decodeIfPresent(Bool.self, forKey: .isAllowAndroidNotification) ?? true
        isAllowTaskReminder = try container.decodeIfPresent(Bool.self, forKey: .isAllowTaskReminder) ?? true
        isAllowHealthReminder = try container.decodeIfPresent(Bool.self, forKey: .isAllowHealthReminder) ?? true
        isAllowBudgetReminder = try container.decodeIfPresent(Bool.self, forKey: .isAllowBudgetReminder) ?? true
    }

    // Computed properties
    var currentLevel: String {
        return currentLevelName ?? "1"
    }

    // Define CodingKeys for the custom decoder
    private enum CodingKeys: String, CodingKey {
        case id, email, fullName, profileImageURL, authProvider, createdDate, lastLoginDate
        case totalPoints, currentLevelId
        case currentLevelName, currentLevelTitle, currentLevelIconUrl, currentLevelIconDownloadUrl
        case isAdmin, isActive, isDeleted
        case isAllowAppleNotification, isAllowAndroidNotification
        case isAllowTaskReminder, isAllowHealthReminder, isAllowBudgetReminder
    }
}

struct LoginCredentials {
    let email: String
    let password: String
}

struct RegisterCredentials {
    let fullName: String
    let email: String
    let password: String
    let confirmPassword: String
}

struct AuthResponse {
    let user: User
    let token: String?
    let success: Bool
    let message: String?
}

struct UpdateNotificationSettingsRequest: Codable {
    let isAllowAppleNotification: Bool?
    let isAllowAndroidNotification: Bool?
    let isAllowTaskReminder: Bool?
    let isAllowHealthReminder: Bool?
    let isAllowBudgetReminder: Bool?
    let deviceToken: String?
    let deviceType: String?
    
    init(isAllowAppleNotification: Bool? = nil,
         isAllowAndroidNotification: Bool? = nil,
         isAllowTaskReminder: Bool? = nil,
         isAllowHealthReminder: Bool? = nil,
         isAllowBudgetReminder: Bool? = nil,
         deviceToken: String? = nil,
         deviceType: String? = "iOS") {
        self.isAllowAppleNotification = isAllowAppleNotification
        self.isAllowAndroidNotification = isAllowAndroidNotification
        self.isAllowTaskReminder = isAllowTaskReminder
        self.isAllowHealthReminder = isAllowHealthReminder
        self.isAllowBudgetReminder = isAllowBudgetReminder
        self.deviceToken = deviceToken
        self.deviceType = deviceType
    }
}

struct UpdateNotificationSettingsResponse: Codable {
    let success: Bool
    let message: String
    let user: UserNotificationSettingsDto?
}

struct UserNotificationSettingsDto: Codable {
    let id: String
    let email: String
    let fullName: String
    let profileImageURL: String?
    let authProvider: String
    let isAllowAppleNotification: Bool
    let isAllowAndroidNotification: Bool
    let isAllowTaskReminder: Bool
    let isAllowHealthReminder: Bool
    let isAllowBudgetReminder: Bool
}

struct UpdateDeviceTokenRequest: Codable {
    let deviceToken: String
    let deviceType: String
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    let deviceId: String?
    
    init(deviceToken: String, deviceType: String = "iOS") {
        self.deviceToken = deviceToken
        self.deviceType = deviceType
        self.deviceModel = DeviceInfo.deviceModel
        self.osVersion = DeviceInfo.osVersion
        self.appVersion = DeviceInfo.appVersion
        self.deviceId = DeviceInfo.deviceId
    }
}

struct DeviceInfo {
    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)) ?? UnicodeScalar(63)!) // 63 is '?'
        }
        
        // Map identifier to readable name
        switch identifier {
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "x86_64": return "iPhone Simulator"
        case "arm64": return "iPhone Simulator (Apple Silicon)"
        default: return identifier.isEmpty ? "Unknown iPhone" : identifier
        }
    }
    
    static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}