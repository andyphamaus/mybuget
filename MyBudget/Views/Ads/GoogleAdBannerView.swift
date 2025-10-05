import SwiftUI
import UIKit
import GoogleMobileAds

// MARK: - Google AdMob Banner View for SwiftUI

struct GoogleAdBannerView: UIViewRepresentable {
    let adSize: AdSize
    let adUnitID: String
    
    @StateObject private var adMobService = AdMobIntegrationService.shared
    
    init(adSize: AdSize = AdSizeBanner, adUnitID: String = AdMobConfig.AdUnitIDs.currentBanner) {
        self.adSize = adSize
        self.adUnitID = adUnitID
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        guard adMobService.isInitialized else { return }
        
        // Set root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            uiView.rootViewController = rootViewController
            
            // Load ad if not already loaded
            if uiView.adUnitID != nil {
                let request = Request()
                uiView.load(request)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        let parent: GoogleAdBannerView
        
        init(_ parent: GoogleAdBannerView) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Google Banner ad received successfully")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Google Banner ad failed to load: \(error.localizedDescription)")
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("👁️ Google Banner ad impression recorded")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("📱 Google Banner ad presenting screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("📱 Google Banner ad dismissed screen")
        }
    }
}

// MARK: - SwiftUI Integration View

struct AdBannerContainer: View {
    let placement: BannerPlacement
    let height: CGFloat
    
    @StateObject private var adMobService = AdMobIntegrationService.shared
    @AppStorage("MyBudget_ShowAds") private var showAds: Bool = true
    
    enum BannerPlacement {
        case top
        case bottom
        
        var description: String {
            switch self {
            case .top: return "top_banner"
            case .bottom: return "bottom_banner"
            }
        }
    }
    
    init(placement: BannerPlacement = .bottom, height: CGFloat = 50) {
        self.placement = placement
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if adMobService.isInitialized && showAds {
                GoogleAdBannerView()
                    .frame(height: height)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        print("📱 Banner ad displayed at \(placement.description)")
                        print("🎯 Banner ad successfully rendered")
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: adMobService.isInitialized)
        .onAppear {
            print("🔍 AdBannerContainer appeared - initialized: \(adMobService.isInitialized), shouldShow: \(showAds)")
            if !adMobService.isInitialized {
                print("⏳ AdMob not initialized yet - banner ad hidden")
            } else if !showAds {
                print("🚫 Banner ad hidden due to user preferences")
            }
        }
    }
}

// MARK: - Preview for Development

struct GoogleAdBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("MyBudget App")
                .font(.title)
            
            Spacer()
            
            AdBannerContainer(placement: .bottom, height: 50)
            
            Spacer()
            
            Text("More App Content")
        }
        .padding()
    }
}

// MARK: - Ad Size Extensions

extension AdSize {
    static var smartBanner: AdSize {
        return AdSizeBanner
    }
    
    static var mediumRectangle: AdSize {
        return AdSizeMediumRectangle
    }
    
    static var largeBanner: AdSize {
        return AdSizeLargeBanner
    }
}

// MARK: - AdMob Test Utilities

extension GoogleAdBannerView {
    static func testBanner() -> GoogleAdBannerView {
        return GoogleAdBannerView(
            adSize: AdSizeBanner,
            adUnitID: AdMobConfig.AdUnitIDs.testBanner
        )
    }
    
    static func productionBanner() -> GoogleAdBannerView {
        return GoogleAdBannerView(
            adSize: AdSizeBanner,
            adUnitID: AdMobConfig.AdUnitIDs.currentBanner
        )
    }
}

/*
 📋 BANNER ADS USAGE GUIDE FOR MYGARDEN:
 
 1. BOTTOM BANNER (RECOMMENDED):
    VStack {
        // Your main content
        Spacer()
        AdBannerContainer(placement: .bottom)
    }
 
 2. TOP BANNER:
    VStack {
        AdBannerContainer(placement: .top)
        // Your main content
        Spacer()
    }
 
 3. INTEGRATION WITH MAIN VIEW:
    Add to ContentView or any main screen:
    .safeAreaInset(edge: .bottom) {
        AdBannerContainer(placement: .bottom)
    }
 
 4. USER PREFERENCE:
    The AdBannerContainer checks @AppStorage("MyBudget_ShowAds")
    to allow users to toggle ads on/off in settings
 */