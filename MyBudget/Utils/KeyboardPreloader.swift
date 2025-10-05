import SwiftUI
import UIKit

// Extension to preload keyboard and eliminate first-time lag
extension View {
    func preloadKeyboard() -> some View {
        self.onAppear {
            KeyboardPreloader.shared.preload()
        }
    }
}

class KeyboardPreloader {
    static let shared = KeyboardPreloader()
    private var hasPreloaded = false
    
    private init() {}
    
    func preload() {
        guard !hasPreloaded else { return }
        hasPreloaded = true
        
        // Warm up keyboard on background thread
        DispatchQueue.main.async {
            self.warmUpKeyboard()
        }
    }
    
    private func warmUpKeyboard() {
        // Create a temporary UITextField to trigger keyboard loading
        let tempTextField = UITextField()
        
        // Add it to the key window but keep it hidden
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        tempTextField.isHidden = true
        window.addSubview(tempTextField)
        
        // Make it first responder to load keyboard resources
        tempTextField.becomeFirstResponder()
        
        // Immediately resign and remove
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tempTextField.resignFirstResponder()
            tempTextField.removeFromSuperview()
        }
    }
}

// Alternative approach using UITextInputMode
extension KeyboardPreloader {
    func preloadWithTextInputMode() {
        // Warm up text input modes
        _ = UITextInputMode.activeInputModes
        
        // Initialize text checker to preload spell checking resources
        _ = UITextChecker()
        
        // Preload keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        // Remove observer after first keyboard show
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
}