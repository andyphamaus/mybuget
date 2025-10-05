# MyGarden iOS App - Claude Development History

## Project Overview
A native iOS app for garden management with Google Mobile Ads integration. This is a clean template ready for custom development.

## Key Features
- Google Mobile Ads banner integration
- Swift Package Manager for dependency management
- Clean template structure for custom development
- AdMob test/production mode switching

## Recent Development Work

### CocoaPods to Swift Package Manager Migration
- **Date**: September 2025
- **Migrated from**: CocoaPods dependency management
- **Migrated to**: Swift Package Manager
- **Primary dependency**: Google Mobile Ads SDK v12.11.0
- **Secondary dependency**: Google User Messaging Platform

### API Updates
Updated Google Mobile Ads API calls due to v12.11.0 changes:
- `GADMobileAds.sharedInstance()` → `MobileAds.shared`
- `GADRequest()` → `Request()`
- `GADBannerView` → `BannerView`
- `GADBannerViewDelegate` → `BannerViewDelegate`
- `GADAdSizeBanner` → `AdSizeBanner`

### App Renamed to MyGarden
Renamed from Meeting Notes to MyGarden:
- **ContentView.swift**: Main app view with garden theme and bottom banner
- Updated app icon from credit card to leaf symbol
- Changed color scheme to green for garden theme
- Kept Google Mobile Ads integration
- Clean template ready for garden management features

### Authentication Integration Added
Integrated Apple and Google Sign-In based on LifeLaunch implementation:
- **AuthenticationService.swift**: Local authentication service for Apple/Google sign-in
- **User.swift**: User model with garden-specific properties (plants, gardens, level)
- **AuthenticationView.swift**: Login screen with Apple and Google sign-in buttons
- **ContentView.swift**: Updated with authentication flow (unauthenticated/authenticating/authenticated)
- **AppDelegate.swift**: Configured GoogleSignIn with client ID from GoogleService-Info.plist
- **MyGarden.entitlements**: Added Sign in with Apple capability
- **Info.plist**: Added URL schemes for Google Sign-In redirect handling

### Configuration Files Updated
- **MyGarden-Info.plist**: Added AdMob App ID and SKAdNetworkItems (49 ad networks)
- **MyGarden.entitlements**: Clean entitlements file
- **Assets.xcassets/AppIcon.appiconset/Contents.json**: Configured iOS app icons for all required sizes

### AdMob Configuration
- **AdMob Test Device ID**: `650018a49821882abd6f5735bd9133ce`
- **Test App ID**: `ca-app-pub-3940256099942544~1458002511`
- **Test Banner ID**: `ca-app-pub-3940256099942544/6300978111`
- **Production App ID**: `ca-app-pub-7184249493869519~2788569307`
- **Production Banner ID**: `ca-app-pub-7184249493869519/5431916650`

## Build Commands
```bash
# Open project in Xcode
open "MyGarden.xcworkspace"

# Clean build folder when needed
# Product → Clean Build Folder in Xcode
```

## Authentication Setup
To complete the authentication integration, you need to:

### Google Sign-In Configuration
✅ **COMPLETED** - Google Sign-In is fully configured:
- **Client ID**: `300044050016-00jisr731koq23h7l7b1nqe02vfth78m.apps.googleusercontent.com`
- **URL Scheme**: `com.googleusercontent.apps.300044050016-00jisr731koq23h7l7b1nqe02vfth78m`
- **Bundle ID**: `com.andycompany.mygarden`
- **Info.plist**: URL schemes configured for Google Sign-In redirect handling
- **AppDelegate**: GoogleSignIn configured with client ID

### Apple Sign-In Configuration  
1. **Apple Developer Account**: Ensure you have a valid Apple Developer account
2. **App ID Configuration**: 
   - Go to Apple Developer Portal
   - Configure your App ID to include Sign in with Apple capability
3. **Provisioning Profile**: Update provisioning profiles to include Sign in with Apple

### Local Testing
- **Sign in with Apple**: ✅ Ready - Works immediately in simulator/device with valid provisioning
- **Google Sign-In**: ✅ Ready - Fully configured with client ID and URL schemes
- **User data**: Stored locally in UserDefaults, no backend API required
- **Bundle ID**: Updated to `com.andycompany.mygarden`

## AdMob Mode Switching
```swift
// Enable test mode (for development)
AdMobConfig.setTestMode(true)

// Enable production mode (for live app)
AdMobConfig.setTestMode(false)
```
- Test mode shows sample ads with test IDs (App: `~1458002511`, Banner: `/6300978111`)
- Production mode shows real ads with production IDs (App: `~2788569307`, Banner: `/5431916650`)

## Known Issues Resolved
1. **GADInvalidInitializationException**: Fixed by adding proper AdMob App ID to Info.plist
2. **Push notification entitlement removed**: Cleaned up unused push notification configuration
3. **API compilation errors**: Fixed by updating GAD-prefixed class names
4. **Asset catalog compilation**: Fixed Contents.json structure for iOS icons
5. **Duplicate GUID error**: Fixed by cleaning derived data and resetting SPM state

## Project Structure
```
MyGarden/
├── MyGarden.xcodeproj/          # Xcode project file
├── MyGarden.xcworkspace/        # Xcode workspace (for SPM)
├── MyGarden/                    # Main app source
│   ├── AppDelegate.swift
│   ├── MyGardenApp.swift
│   ├── ContentView.swift
│   ├── Views/
│   │   └── Ads/
│   │       └── GoogleAdBannerView.swift
│   ├── Services/
│   │   └── Ads/
│   │       └── AdMobIntegrationService.swift
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   └── MyGarden.entitlements
├── MyGardenTests/
├── MyGardenUITests/
├── MyGarden-Info.plist
├── Podfile                          # Legacy (kept for reference)
└── .gitignore                       # Excludes github/ folder
```

## Git Repository
- **Remote**: https://github.com/andyphamaus/MeetingNotes.git (will need updating)
- **Branch**: main
- **Last commit**: Renamed to MyGarden and cleaned up for custom development

## Development Notes
- Project uses Xcode workspace due to Swift Package Manager integration
- AdMob integration is fully functional with test ads
- App icons are configured for all iOS device types and sizes
- Clean template ready for garden management features
- All meeting-related functionality has been removed

## App Store Submission Requirements

### CRITICAL - Privacy Policy Required
**Status**: ⚠️ REQUIRED for App Store approval

Since the app uses Google Mobile Ads and collects advertising data, you MUST:

1. **Create a Privacy Policy** covering:
   - Data collection through Google Mobile Ads
   - Device identifiers and advertising data usage
   - Data handling for membership card functionality (when implemented)
   - User rights and opt-out options

2. **Add Privacy Policy URL** to App Store Connect during submission

3. **App Store Privacy Labels** must declare:
   - Identifiers (Device/Other IDs) - Used for Advertising - Not Linked to User
   - Usage Data (Product Interaction) - Used for Advertising - Not Linked to User

### Privacy Policy Template Points:
- "We use Google Mobile Ads to display advertisements"
- "Ad-related data may be collected for personalized advertising"
- "Garden data is processed locally on your device only"
- "No personal garden data is transmitted to external servers without your consent"
- "Users can opt out of ad tracking in iOS Settings > Privacy & Security"

## Future Considerations for Production
1. ✅ Production AdMob IDs configured
2. ✅ iOS deployment target set to 18.0 for latest features
3. ✅ Clean codebase ready for custom development
4. ⚠️ **Create and host privacy policy before submission**
5. 🔧 **Implement your custom garden management functionality**
6. Consider implementing UMP consent flow for GDPR regions
7. Test on physical devices before App Store submission