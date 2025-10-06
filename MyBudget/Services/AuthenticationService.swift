import Foundation
import Combine
import AuthenticationServices
import UIKit
// import GoogleSignIn // Temporarily disabled for Xcode Cloud

class AuthenticationService: ObservableObject {
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let userDefaultsKey = "LifeLaunch_CurrentUser"
    private let tokenKey = "LifeLaunch_AuthToken"
    private let baseURL = "https://api.lifelaunch.online/api"
    private var cancellables = Set<AnyCancellable>()
    private var authToken: String?
    
    init() {
        loadUserFromStorage()
        
        // If user is already logged in, refresh data and sync device token
        if authenticationState == .authenticated {
            _Concurrency.Task { @MainActor in
                // Refresh user data to get latest level info
                await self.refreshUserData()
                // Sync device token
                await self.syncDeviceTokenAfterLogin()
            }
        }
    }
    
    // MARK: - Email Authentication
    
    func signIn(with credentials: LoginCredentials) async {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .authenticating
            self?.errorMessage = nil
        }
        
        do {
            let loginRequest = LoginAPIRequest(
                email: credentials.email,
                password: credentials.password
            )
            
            guard let url = URL(string: "\(baseURL)/Auth/login") else {
                throw AuthError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(loginRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                
                let authResponse = try JSONDecoder().decode(AuthAPIResponse.self, from: data)
                
                if authResponse.success {
                    
                    let user = User(
                        id: authResponse.user?.id.uuidString ?? UUID().uuidString,
                        email: authResponse.user?.email ?? credentials.email,
                        fullName: authResponse.user?.fullName ?? "User",
                        profileImageURL: authResponse.user?.profileImageURL,
                        authProvider: .email,
                        totalPoints: authResponse.user?.totalPoints ?? 0,
                        currentLevelId: authResponse.user?.currentLevelId,
                        currentLevelName: authResponse.user?.currentLevelName,
                        currentLevelTitle: authResponse.user?.currentLevelTitle,
                        currentLevelIconUrl: authResponse.user?.currentLevelIconUrl,
                        currentLevelIconDownloadUrl: authResponse.user?.currentLevelIconDownloadUrl,
                        isAdmin: authResponse.user?.isAdmin ?? false,
                        isActive: authResponse.user?.isActive ?? true,
                        isDeleted: authResponse.user?.isDeleted ?? false
                    )
                    
                    DispatchQueue.main.async { [weak self] in
                        
                        self?.currentUser = user
                        self?.authToken = authResponse.token
                        self?.authenticationState = .authenticated
                        self?.saveUserToStorage(user)
                        self?.saveTokenToStorage(authResponse.token ?? "")
                        
                        // Sync device token after successful login
                        _Concurrency.Task {
                            await self?.syncDeviceTokenAfterLogin()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.authenticationState = .unauthenticated
                        self?.errorMessage = authResponse.message ?? "Login failed"
                    }
                }
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async { [weak self] in
                    self?.authenticationState = .unauthenticated
                    self?.errorMessage = "Invalid email or password. Please try again."
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.authenticationState = .unauthenticated
                    self?.errorMessage = "Login failed. Please try again."
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    func register(with credentials: RegisterCredentials) async {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .authenticating
            self?.errorMessage = nil
        }
        
        // Client-side validation
        guard isValidEmail(credentials.email) else {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Please enter a valid email address."
            }
            return
        }
        
        guard credentials.password.count >= 6 else {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Password must be at least 6 characters long."
            }
            return
        }
        
        guard credentials.password == credentials.confirmPassword else {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Passwords do not match."
            }
            return
        }
        
        guard credentials.fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Please enter your full name."
            }
            return
        }
        
        do {
            let registerRequest = RegisterAPIRequest(
                fullName: credentials.fullName,
                email: credentials.email,
                password: credentials.password,
                confirmPassword: credentials.confirmPassword,
                countryCode: "AU",
                languageCode: "en"
            )
            
            guard let url = URL(string: "\(baseURL)/Auth/register") else {
                throw AuthError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(registerRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthAPIResponse.self, from: data)
                
                if authResponse.success {
                    let user = User(
                        id: authResponse.user?.id.uuidString ?? UUID().uuidString,
                        email: authResponse.user?.email ?? credentials.email,
                        fullName: authResponse.user?.fullName ?? credentials.fullName,
                        profileImageURL: authResponse.user?.profileImageURL,
                        authProvider: .email,
                        totalPoints: authResponse.user?.totalPoints ?? 0,
                        currentLevelId: authResponse.user?.currentLevelId,
                        currentLevelName: authResponse.user?.currentLevelName,
                        currentLevelTitle: authResponse.user?.currentLevelTitle,
                        currentLevelIconUrl: authResponse.user?.currentLevelIconUrl,
                        currentLevelIconDownloadUrl: authResponse.user?.currentLevelIconDownloadUrl,
                        isAdmin: authResponse.user?.isAdmin ?? false,
                        isActive: authResponse.user?.isActive ?? true,
                        isDeleted: authResponse.user?.isDeleted ?? false
                    )
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.currentUser = user
                        self?.authToken = authResponse.token
                        self?.authenticationState = .authenticated
                        self?.saveUserToStorage(user)
                        self?.saveTokenToStorage(authResponse.token ?? "")
                        
                        // Sync device token after successful registration
                        _Concurrency.Task {
                            await self?.syncDeviceTokenAfterLogin()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.authenticationState = .unauthenticated
                        self?.errorMessage = authResponse.message ?? "Registration failed"
                    }
                }
            } else {
                let errorResponse = try? JSONDecoder().decode(AuthAPIResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.authenticationState = .unauthenticated
                    self?.errorMessage = errorResponse?.message ?? "Registration failed. Please try again."
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Social Authentication
    
    func signInWithApple() async {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .authenticating
            self?.errorMessage = nil
        }
        
        do {
            let appleUser = try await performAppleSignIn()
            
            // Call social login API
            let socialLoginRequest = SocialLoginAPIRequest(
                email: appleUser.email,
                fullName: appleUser.fullName,
                authProvider: "apple",
                countryCode: "AU", // Hard-coded for Australia
                languageCode: "en" // Hard-coded for English
            )
            
            guard let url = URL(string: "\(baseURL)/Auth/social-login") else {
                throw AuthError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(socialLoginRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthAPIResponse.self, from: data)
                
                if authResponse.success {
                    let user = User(
                        id: authResponse.user?.id.uuidString ?? appleUser.id,
                        email: authResponse.user?.email ?? appleUser.email,
                        fullName: authResponse.user?.fullName ?? appleUser.fullName,
                        profileImageURL: authResponse.user?.profileImageURL,
                        authProvider: .apple,
                        totalPoints: authResponse.user?.totalPoints ?? 0,
                        currentLevelId: authResponse.user?.currentLevelId,
                        currentLevelName: authResponse.user?.currentLevelName,
                        currentLevelTitle: authResponse.user?.currentLevelTitle,
                        currentLevelIconUrl: authResponse.user?.currentLevelIconUrl,
                        currentLevelIconDownloadUrl: authResponse.user?.currentLevelIconDownloadUrl,
                        isAdmin: authResponse.user?.isAdmin ?? false,
                        isActive: authResponse.user?.isActive ?? true,
                        isDeleted: authResponse.user?.isDeleted ?? false
                    )
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.currentUser = user
                        self?.authToken = authResponse.token
                        self?.authenticationState = .authenticated
                        self?.saveUserToStorage(user)
                        self?.saveTokenToStorage(authResponse.token ?? "")
                        
                        // Sync device token after successful social login
                        _Concurrency.Task {
                            await self?.syncDeviceTokenAfterLogin()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.authenticationState = .unauthenticated
                        self?.errorMessage = authResponse.message ?? "Social login failed"
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.authenticationState = .unauthenticated
                    self?.errorMessage = "Apple Sign In failed. Please try again."
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func performAppleSignIn() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            let delegate = AppleSignInDelegate { result in
                continuation.resume(with: result)
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            authorizationController.performRequests()
            
            // Keep delegate alive
            objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func signInWithGoogle() async {
        // Temporarily disabled for Xcode Cloud compatibility
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = "Google Sign-In temporarily disabled for Xcode Cloud compatibility"
        }

        /*
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .authenticating
            self?.errorMessage = nil
        }

        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw AuthError.invalidResponse
            }

            // Try to restore previous sign-in first to avoid consent screen
            if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                do {
                    let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                    // Process restored user
                    await processGoogleUser(user)
                    return
                } catch {
                    // If restore fails, continue with normal sign-in
                }
            }

            // Normal sign-in if no previous session or restore failed
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let googleUser = result.user

            // Process the signed-in user
            await processGoogleUser(googleUser)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                if (error as NSError).code == -5 {
                    self?.errorMessage = "Sign in was cancelled"
                } else {
                    self?.errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                }
            }
        }
        */
    }
    
    private func processGoogleUser(_ googleUser: Any) async {
        // Temporarily disabled for Xcode Cloud compatibility
        print("⚠️ Google Sign-In temporarily disabled for Xcode Cloud compatibility")

        /*
        let email = googleUser.profile?.email ?? ""
        let fullName = googleUser.profile?.name ?? "Google User"

        do {
            // Call social login API
            let socialLoginRequest = SocialLoginAPIRequest(
                email: email,
                fullName: fullName,
                authProvider: "google",
                countryCode: "AU", // Hard-coded for Australia
                languageCode: "en" // Hard-coded for English
            )

            guard let url = URL(string: "\(baseURL)/Auth/social-login") else {
                throw AuthError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(socialLoginRequest)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthAPIResponse.self, from: data)

                if authResponse.success {
                    let user = User(
                        id: authResponse.user?.id.uuidString ?? googleUser.userID ?? UUID().uuidString,
                        email: authResponse.user?.email ?? email,
                        fullName: authResponse.user?.fullName ?? fullName,
                        profileImageURL: authResponse.user?.profileImageURL ?? googleUser.profile?.imageURL(withDimension: 200)?.absoluteString,
                        authProvider: .google,
                        totalPoints: authResponse.user?.totalPoints ?? 0,
                        currentLevelId: authResponse.user?.currentLevelId,
                        currentLevelName: authResponse.user?.currentLevelName,
                        currentLevelTitle: authResponse.user?.currentLevelTitle,
                        currentLevelIconUrl: authResponse.user?.currentLevelIconUrl,
                        currentLevelIconDownloadUrl: authResponse.user?.currentLevelIconDownloadUrl,
                        isAdmin: authResponse.user?.isAdmin ?? false,
                        isActive: authResponse.user?.isActive ?? true,
                        isDeleted: authResponse.user?.isDeleted ?? false
                    )

                    DispatchQueue.main.async { [weak self] in
                        self?.currentUser = user
                        self?.authToken = authResponse.token
                        self?.authenticationState = .authenticated
                        self?.saveUserToStorage(user)
                        self?.saveTokenToStorage(authResponse.token ?? "")

                        // Sync device token after successful social login
                        _Concurrency.Task {
                            await self?.syncDeviceTokenAfterLogin()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.authenticationState = .unauthenticated
                        self?.errorMessage = authResponse.message ?? "Google Sign In failed"
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.authenticationState = .unauthenticated
                    self?.errorMessage = "Google Sign In failed. Please try again."
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                self?.errorMessage = "Failed to process Google Sign In: \(error.localizedDescription)"
            }
        }
        */
    }
    
    
    // MARK: - Session Management
    
    func refreshUserData() async {
        
        guard let token = authToken else {
            return
        }
        
        do {
            guard let url = URL(string: "\(baseURL)/Auth/profile") else {
                throw AuthError.invalidURL
            }
            
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            
            if let responseString = String(data: data, encoding: .utf8) {
            }
            
            if httpResponse.statusCode == 200 {
                // API returns user data directly, not wrapped in a response object
                let userDto = try JSONDecoder().decode(UserAPIDto.self, from: data)
                
                
                let refreshedUser = User(
                    id: userDto.id.uuidString,
                    email: userDto.email,
                    fullName: userDto.fullName,
                    profileImageURL: userDto.profileImageURL,
                    authProvider: AuthProvider(rawValue: userDto.authProvider) ?? .email,
                    totalPoints: userDto.totalPoints ?? 0,
                    currentLevelId: userDto.currentLevelId,
                    currentLevelName: userDto.currentLevelName,
                    currentLevelTitle: userDto.currentLevelTitle,
                    currentLevelIconUrl: userDto.currentLevelIconUrl,
                    currentLevelIconDownloadUrl: userDto.currentLevelIconDownloadUrl,
                    isAdmin: userDto.isAdmin,
                    isActive: userDto.isActive,
                    isDeleted: userDto.isDeleted
                )
                
                DispatchQueue.main.async { [weak self] in
                    
                    self?.currentUser = refreshedUser
                    self?.saveUserToStorage(refreshedUser)
                    
                }
            } else if httpResponse.statusCode == 401 {
                // Token expired, sign out
                DispatchQueue.main.async { [weak self] in
                    self?.signOut()
                }
            } else {
            }
        } catch {
        }
    }
    
    func signOut() {
        currentUser = nil
        authToken = nil
        authenticationState = .unauthenticated
        errorMessage = nil
        removeUserFromStorage()
        removeTokenFromStorage()
    }
    
    func getAuthToken() -> String? {
        return authToken
    }
    
    private func saveUserToStorage(_ user: User) {
        do {
            // Debug: Log what we're saving
            
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize() // Force immediate save
            
        } catch {
        }
    }
    
    private func loadUserFromStorage() {
        guard let userData = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: userData)
            
            // Debug: Log loaded user's level data
            
            self.currentUser = user
            
            // Also load the auth token
            if let tokenData = UserDefaults.standard.data(forKey: tokenKey),
               let token = String(data: tokenData, encoding: .utf8) {
                self.authToken = token
            }
            
            self.authenticationState = .authenticated
        } catch {
            
            // Clear corrupted data to prevent repeated failures
            removeUserFromStorage()
            removeTokenFromStorage()
            
            // Reset authentication state
            self.currentUser = nil
            self.authToken = nil
            self.authenticationState = .unauthenticated
        }
    }
    
    private func removeUserFromStorage() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    private func saveTokenToStorage(_ token: String) {
        if let data = token.data(using: .utf8) {
            UserDefaults.standard.set(data, forKey: tokenKey)
        }
    }
    
    private func removeTokenFromStorage() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let username = email.components(separatedBy: "@").first ?? "User"
        return username.capitalized
    }
    
    private func mapUserFromAPI(_ apiUser: UserAPIDto) -> User {
        var user = User(
            id: apiUser.id.uuidString,
            email: apiUser.email,
            fullName: apiUser.fullName,
            profileImageURL: apiUser.profileImageURL,
            authProvider: AuthProvider(rawValue: apiUser.authProvider) ?? .email,
            totalPoints: apiUser.totalPoints ?? 0,
            currentLevelId: apiUser.currentLevelId,
            currentLevelName: apiUser.currentLevelName,
            currentLevelTitle: apiUser.currentLevelTitle,
            currentLevelIconUrl: apiUser.currentLevelIconUrl,
            currentLevelIconDownloadUrl: apiUser.currentLevelIconDownloadUrl,
            isAdmin: apiUser.isAdmin,
            isActive: apiUser.isActive,
            isDeleted: apiUser.isDeleted
        )
        
        // Update notification settings from API
        user.isAllowAppleNotification = apiUser.isAllowAppleNotification ?? true
        user.isAllowAndroidNotification = apiUser.isAllowAndroidNotification ?? true
        user.isAllowTaskReminder = apiUser.isAllowTaskReminder ?? true
        user.isAllowHealthReminder = apiUser.isAllowHealthReminder ?? true
        user.isAllowBudgetReminder = apiUser.isAllowBudgetReminder ?? true
        
        return user
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSettings(
        isAllowAppleNotification: Bool? = nil,
        isAllowAndroidNotification: Bool? = nil,
        isAllowTaskReminder: Bool? = nil,
        isAllowHealthReminder: Bool? = nil,
        isAllowBudgetReminder: Bool? = nil,
        deviceToken: String? = nil
    ) async -> Bool {
        guard let token = authToken else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Not authenticated"
            }
            return false
        }
        
        do {
            let request = UpdateNotificationSettingsRequest(
                isAllowAppleNotification: isAllowAppleNotification,
                isAllowAndroidNotification: isAllowAndroidNotification,
                isAllowTaskReminder: isAllowTaskReminder,
                isAllowHealthReminder: isAllowHealthReminder,
                isAllowBudgetReminder: isAllowBudgetReminder,
                deviceToken: deviceToken,
                deviceType: "iOS"
            )
            
            guard let url = URL(string: "\(baseURL)/Auth/notification-settings") else {
                throw AuthError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let updateResponse = try JSONDecoder().decode(UpdateNotificationSettingsResponse.self, from: data)
                
                if updateResponse.success, let userDto = updateResponse.user {
                    // Convert UserNotificationSettingsDto to User
                    let currentUser = self.currentUser ?? User(email: userDto.email, fullName: userDto.fullName)
                    var updatedUser = User(
                        id: userDto.id,
                        email: userDto.email,
                        fullName: userDto.fullName,
                        profileImageURL: userDto.profileImageURL,
                        authProvider: AuthProvider(rawValue: userDto.authProvider) ?? .email
                    )
                    
                    // Preserve dates from current user
                    updatedUser.createdDate = currentUser.createdDate
                    updatedUser.lastLoginDate = currentUser.lastLoginDate
                    
                    // Update notification settings
                    updatedUser.isAllowAppleNotification = userDto.isAllowAppleNotification
                    updatedUser.isAllowAndroidNotification = userDto.isAllowAndroidNotification
                    updatedUser.isAllowTaskReminder = userDto.isAllowTaskReminder
                    updatedUser.isAllowHealthReminder = userDto.isAllowHealthReminder
                    updatedUser.isAllowBudgetReminder = userDto.isAllowBudgetReminder
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.currentUser = updatedUser
                        self?.saveUserToStorage(updatedUser)
                    }
                    
                    return true
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.errorMessage = updateResponse.message
                    }
                    return false
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to update notification settings"
                }
                return false
            }
        } catch {
            // Log the error for debugging
            
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to parse response: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Device Token Management
    
    func updateDeviceToken(_ deviceToken: String) async -> Bool {
        guard let token = authToken else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Not authenticated"
            }
            return false
        }
        
        do {
            let request = UpdateDeviceTokenRequest(deviceToken: deviceToken)
            
            guard let url = URL(string: "\(baseURL)/Auth/device-token") else {
                throw AuthError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return true
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return false
            }
        } catch {
            return false
        }
    }
    
    func syncDeviceTokenAfterLogin() async {
        // TODO: Implement device token sync when NotificationService supports these methods
        // Check if we have a stored device token to sync
        /*
        if let deviceToken = NotificationService.shared.getStoredDeviceToken(),
           NotificationService.shared.shouldSyncDeviceToken() {

            let success = await updateDeviceToken(deviceToken)

            if success {
                NotificationService.shared.markDeviceTokenSynced()
            } else {
            }
        }
        */
    }
}

// MARK: - Apple Sign In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<User, Error>) -> Void
    
    init(completion: @escaping (Result<User, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email ?? "user@appleid.com"
            
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let finalName = displayName.isEmpty ? "Apple User" : displayName
            
            let user = User(
                id: appleIDCredential.user,
                email: email,
                fullName: finalName,
                authProvider: .apple
            )
            
            completion(.success(user))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - API Request/Response Models
struct LoginAPIRequest: Codable {
    let email: String
    let password: String
}

struct RegisterAPIRequest: Codable {
    let fullName: String
    let email: String
    let password: String
    let confirmPassword: String
    let countryCode: String
    let languageCode: String
}

struct SocialLoginAPIRequest: Codable {
    let email: String
    let fullName: String
    let authProvider: String
    let countryCode: String
    let languageCode: String
}

struct AuthAPIResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let user: UserAPIDto?
}

struct UserAPIDto: Codable {
    let id: UUID
    let email: String
    let fullName: String
    let profileImageURL: String?
    let authProvider: String
    let isAdmin: Bool
    let isActive: Bool
    let isDeleted: Bool
    let createdDate: String
    let lastLoginDate: String?
    let isAllowAppleNotification: Bool?
    let isAllowAndroidNotification: Bool?
    let isAllowTaskReminder: Bool?
    let isAllowHealthReminder: Bool?
    let isAllowBudgetReminder: Bool?
    // Gamification properties from level.md
    let totalPoints: Int?
    let currentLevelId: String?
    // Level details (new fields)
    let currentLevelName: String?
    let currentLevelTitle: String?
    let currentLevelIconUrl: Int?
    let currentLevelIconDownloadUrl: String?
    // Country information
    let countryCode: String?
    let countryName: String?
    let countryNativeName: String?
    let countryFlagEmoji: String?
}

// MARK: - User Refresh Response
struct UserRefreshResponse: Codable {
    let success: Bool
    let message: String?
    let user: UserAPIDto?
}

// MARK: - Auth Errors
enum AuthError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(String)
}
