import UIKit
import GoogleMobileAds
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Google Mobile Ads SDK
        print("🚀 Initializing Google Mobile Ads SDK...")
        MobileAds.shared.start { status in
            print("AdMob initialized with status: \(status)")
        }
        
        // Enable production mode for MyBudget app
        AdMobConfig.setTestMode(false)
        
        // Configure Google Sign-In
        configureGoogleSignIn()
        
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    private func configureGoogleSignIn() {
        // Configure Google Sign-In with provided client ID
        let clientId = GoogleSignInConfig.clientID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ Google Sign-In configured with client ID: \(clientId)")
    }
}