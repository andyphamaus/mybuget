import Foundation
import Combine
import AuthenticationServices
import UIKit
// import GoogleSignIn // Temporarily disabled for Xcode Cloud
import CoreData

@MainActor
class LocalAuthenticationService: ObservableObject {
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var currentUser: LocalUser?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let persistenceController = PersistenceController.shared
    
    init() {
        loadUserFromCoreData()
    }
    
    // MARK: - Core Data User Management
    
    private func loadUserFromCoreData() {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            if let user = users.first {
                DispatchQueue.main.async { [weak self] in
                    self?.currentUser = user
                    self?.authenticationState = .authenticated
                }
            }
        } catch {
        }
    }
    
    private func saveUserToCoreData(email: String, fullName: String, profileImageURL: String? = nil) {
        let context = persistenceController.viewContext
        
        // Check if user already exists
        let request: NSFetchRequest<LocalUser> = LocalUser.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let existingUsers = try context.fetch(request)
            let user: LocalUser
            
            if let existingUser = existingUsers.first {
                // Update existing user
                user = existingUser
                user.fullName = fullName
                user.profileImageUrl = profileImageURL
            } else {
                // Create new user
                user = LocalUser(context: context)
                user.email = email
                user.fullName = fullName
                user.profileImageUrl = profileImageURL
            }
            
            try context.save()
            
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
                self?.authenticationState = .authenticated
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to save user data"
                self?.authenticationState = .unauthenticated
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .authenticating
            self?.errorMessage = nil
        }
        
        do {
            let appleUser = try await performAppleSignIn()
            
            // Save user locally to Core Data
            saveUserToCoreData(
                email: appleUser.email,
                fullName: appleUser.fullName,
                profileImageURL: nil
            )
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .unauthenticated
                if (error as NSError).code == 1001 {
                    self?.errorMessage = "Sign in was cancelled"
                } else {
                    self?.errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func performAppleSignIn() async throws -> (id: String, email: String, fullName: String) {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            let delegate = LocalAppleSignInDelegate { result in
                switch result {
                case .success(let appleUser):
                    continuation.resume(returning: appleUser)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            authorizationController.performRequests()
            
            // Keep delegate alive
            objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Google Sign In
    
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

            // Try to restore previous sign-in first
            if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                do {
                    let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                    await processGoogleUser(user)
                    return
                } catch {
                    // If restore fails, continue with normal sign-in
                }
            }

            // Normal sign-in if no previous session or restore failed
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let googleUser = result.user

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
        let profileImageURL = googleUser.profile?.imageURL(withDimension: 200)?.absoluteString

        // Save user locally to Core Data
        saveUserToCoreData(
            email: email,
            fullName: fullName,
            profileImageURL: profileImageURL
        )
        */
    }
    
    
    // MARK: - Sign Out
    
    func logout() {
        // Sign out from Google if signed in
        // if GIDSignIn.sharedInstance.hasPreviousSignIn() {
        //     GIDSignIn.sharedInstance.signOut()
        // }

        // Clear user data
        currentUser = nil
        authenticationState = .unauthenticated
        errorMessage = nil

        // Note: We don't delete user data from Core Data for now
        // This allows users to sign back in and retain their data
        // In the future, we might want to add an option to delete all data
    }
    
    func signOut() {
        logout()
    }
    
    // MARK: - Helper Methods
    
    func getAuthToken() -> String? {
        // No token needed for local authentication
        return nil
    }
    
    func getCurrentUser() -> LocalUser? {
        return currentUser
    }
}

// MARK: - Local Apple Sign In Delegate

private class LocalAppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<(id: String, email: String, fullName: String), Error>) -> Void
    
    init(completion: @escaping (Result<(id: String, email: String, fullName: String), Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let email = appleIDCredential.email ?? "apple_user@privacy.com"
            
            // Get full name
            var fullName = "Apple User"
            if let givenName = appleIDCredential.fullName?.givenName,
               let familyName = appleIDCredential.fullName?.familyName {
                fullName = "\(givenName) \(familyName)"
            } else if let givenName = appleIDCredential.fullName?.givenName {
                fullName = givenName
            }
            
            completion(.success((id: userID, email: email, fullName: fullName)))
        } else {
            completion(.failure(AuthError.invalidResponse))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first ?? UIWindow()
        }
        return UIWindow()
    }
}