import Foundation
import AppTrackingTransparency
import AdSupport
import Combine
import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform

// MARK: - AdMob Configuration Constants
struct AdMobConfig {
    // UserDefaults key for storing test mode preference
    static let testModeKey = "MyBudget_AdMob_TestMode"
    
    // Check if currently in test mode
    static var isTestMode: Bool {
        return UserDefaults.standard.bool(forKey: testModeKey)
    }
    
    // Set test mode
    static func setTestMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: testModeKey)
        print(enabled ? "🧪 AdMob Test Mode ENABLED" : "💰 AdMob Production Mode ENABLED")
    }
    
    // Dynamic App ID based on test mode
    static var currentAppID: String {
        return isTestMode ? testAppID : productionAppID
    }
    
    // PRODUCTION App ID - MyBudget App ID
    static let productionAppID = "ca-app-pub-7184249493869519~2788569307"
    
    // Test App ID (for development)
    static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    
    struct AdUnitIDs {
        // Dynamic Banner ID based on test mode
        static var currentBanner: String {
            return AdMobConfig.isTestMode ? testBanner : productionBanner
        }
        
        // PRODUCTION IDs - MyBudget Banner Ad Unit
        static let productionBanner = "ca-app-pub-7184249493869519/5431916650"
        
        // TEST IDs (for development only)
        static let testBanner = "ca-app-pub-3940256099942544/6300978111"
    }
    
    struct TestDeviceIDs {
        // Add your test device IDs here for testing
        static let devices: [String] = [
            "650018a49821882abd6f5735bd9133ce" // Current simulator device ID
        ]
    }
}

// MARK: - Real AdMob Integration Service

@MainActor
class AdMobIntegrationService: NSObject, ObservableObject {
    static let shared = AdMobIntegrationService()
    
    // MARK: - Published Properties
    @Published var isInitialized = false
    @Published var initializationError: Error?
    @Published var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    // MARK: - Ad Instances
    private var bannerView: BannerView?
    
    // MARK: - Delegates
    weak var bannerDelegate: BannerViewDelegate?
    
    // MARK: - Configuration
    private let userDefaults = UserDefaults.standard
    private let initializationKey = "MyBudget_AdMobInitialized"
    
    private override init() {
        super.init()
        setupAdMob()
    }
    
    // MARK: - Initialization
    
    func setupAdMob() {
        Task {
            print("🚀 Starting AdMob setup process...")
            
            // Request UMP consent for GDPR/CCPA compliance
            print("🔒 Requesting UMP consent for GDPR/CCPA compliance...")
            await requestUMPConsent()
            
            // Request tracking permission (iOS 14.5+)
            print("📱 Requesting tracking permission...")
            await requestTrackingPermission()
            
            // Initialize AdMob
            print("🏗️ Initializing AdMob SDK...")
            await initializeAdMob()
            
            print("✅ AdMob setup process completed!")
        }
    }
    
    // MARK: - Privacy & Consent Management
    
    private func requestUMPConsent() async {
        return await withCheckedContinuation { continuation in
            let parameters = RequestParameters()
            // Set tag for under age of consent if needed
            parameters.isTaggedForUnderAgeOfConsent = false
            
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
                if let error = error {
                    print("❌ UMP consent info update failed: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }
                
                let consentStatus = ConsentInformation.shared.consentStatus
                print("🔒 UMP Consent Status: \(consentStatus.description)")
                
                // Check if consent form is available and required
                if ConsentInformation.shared.formStatus == .available {
                    self?.loadAndPresentConsentForm { formError in
                        if let formError = formError {
                            print("❌ UMP consent form error: \(formError.localizedDescription)")
                        } else {
                            print("✅ UMP consent form completed")
                        }
                        continuation.resume()
                    }
                } else {
                    print("ℹ️ UMP consent form not required or not available")
                    continuation.resume()
                }
            }
        }
    }
    
    private func loadAndPresentConsentForm(completion: @escaping (Error?) -> Void) {
        ConsentForm.load { form, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let form = form else {
                completion(NSError(domain: "UMPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Consent form is nil"]))
                return
            }
            
            // Present consent form if needed
            if ConsentInformation.shared.consentStatus == .required {
                // Get the root view controller to present the form
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    form.present(from: rootViewController) { dismissError in
                        completion(dismissError)
                    }
                } else {
                    print("⚠️ Could not find root view controller for UMP consent form")
                    completion(nil) // Continue without presenting form
                }
            } else {
                completion(nil) // Consent not required
            }
        }
    }
    
    private func requestTrackingPermission() async {
        guard #available(iOS 14.5, *) else {
            trackingAuthorizationStatus = .authorized
            return
        }
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        trackingAuthorizationStatus = status
        
        print("📊 ATT Status: \(status.description)")
    }
    
    private func initializeAdMob() async {
        return await withCheckedContinuation { continuation in
            print("🚀 Initializing AdMob with App ID: \(AdMobConfig.currentAppID)")
            print("📱 Banner Ad Unit: \(AdMobConfig.AdUnitIDs.currentBanner)")
            print("🧪 Test Mode: \(AdMobConfig.isTestMode)")
            
            MobileAds.shared.start { [weak self] initStatus in
                DispatchQueue.main.async {
                    self?.handleInitializationStatus(initStatus)
                    print("✅ AdMob initialization completed successfully")
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleInitializationStatus(_ status: InitializationStatus) {
        isInitialized = true
        userDefaults.set(true, forKey: initializationKey)
        
        // Configure test devices and settings
        configureAdMobSettings()
        
        // Log adapter statuses for debugging
        let adapterStatuses = status.adapterStatusesByClassName
        for (adapter, adapterStatus) in adapterStatuses {
            print("🔧 AdMob Adapter \(adapter): \(adapterStatus.description)")
        }
        
        print("✅ AdMob initialized successfully")
    }
    
    private func configureAdMobSettings() {
        let configuration = MobileAds.shared.requestConfiguration
        
        // Set test device IDs
        configuration.testDeviceIdentifiers = AdMobConfig.TestDeviceIDs.devices
        
        // Set maximum ad content rating
        configuration.maxAdContentRating = GADMaxAdContentRating.parentalGuidance
        
        print("🔧 AdMob configuration completed")
    }
    
    // MARK: - Banner Ads
    
    func createBannerView(rootViewController: UIViewController) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = AdMobConfig.AdUnitIDs.currentBanner
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
        
        self.bannerView = bannerView
        return bannerView
    }
    
    func loadBannerAd() {
        guard let bannerView = bannerView else {
            print("❌ Banner view not created")
            return
        }
        
        guard isInitialized else {
            print("⏳ AdMob not initialized yet - will retry banner load")
            return
        }
        
        print("📱 Loading banner ad with ID: \(AdMobConfig.AdUnitIDs.currentBanner)")
        print("🧪 Test Mode: \(AdMobConfig.isTestMode)")
        
        let request = Request()
        bannerView.load(request)
    }
    
    // MARK: - Ad Availability
    
    var isBannerAdReady: Bool {
        return bannerView != nil && isInitialized
    }
    
    // MARK: - Utility Methods
    
    func preloadBannerAd() {
        guard isInitialized else { return }
        print("🔄 Banner ads ready for display...")
    }
    
    func getAdvertisingID() -> String? {
        guard trackingAuthorizationStatus == .authorized else {
            return nil
        }
        
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}

// MARK: - GADBannerViewDelegate

extension AdMobIntegrationService: BannerViewDelegate {
    nonisolated func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("✅ Banner ad received")
    }
    
    nonisolated func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Banner ad failed to load: \(error.localizedDescription)")
    }
    
    nonisolated func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        print("👁️ Banner ad impression recorded")
    }
    
    nonisolated func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        print("📱 Banner ad will present screen")
    }
    
    nonisolated func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        print("📱 Banner ad dismissed screen")
    }
}

// MARK: - ATTrackingManager.AuthorizationStatus Extension

@available(iOS 14.5, *)
extension ATTrackingManager.AuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - UMPConsentStatus Extension

extension ConsentStatus {
    var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .required:
            return "Required"
        case .notRequired:
            return "Not Required"
        case .obtained:
            return "Obtained"
        @unknown default:
            return "Unknown Default"
        }
    }
}

// MARK: - Production Configuration Guide

/*
 📋 BANNER-ONLY ADMOB SETUP FOR MEETING NOTES:
 
 1. ADMOB CONFIGURATION:
    - Create a new app in AdMob console for Meeting Notes
    - Get your App ID and Banner Ad Unit ID
    - Replace the placeholder values in this file:
      - productionAppID: Your Meeting Notes App ID
      - productionBanner: Your Meeting Notes Banner Ad Unit ID
    
    TEST MODE (for development):
    - App ID: ca-app-pub-3940256099942544~1458002511
    - Banner Ad Unit: ca-app-pub-3940256099942544/6300978111
 
 2. COCOAPODS SETUP:
    - Run: pod init
    - Add to Podfile: pod 'Google-Mobile-Ads-SDK'
    - Run: pod install
    - Use .xcworkspace file instead of .xcodeproj
 
 3. INFO.PLIST CONFIGURATION:
    - Add GADApplicationIdentifier with your AdMob App ID
    - Add SKAdNetworkItems for ad attribution
    - Add NSUserTrackingUsageDescription for iOS 14.5+
 
 4. TESTING:
    - Use AdMobConfig.setTestMode(true) for test ads
    - Add test device IDs in TestDeviceIDs.devices
    - Test ads will show sample content
 
 5. PRODUCTION:
    - Set AdMobConfig.setTestMode(false)
    - Real ads will be served
    - Monitor AdMob console for revenue
 */