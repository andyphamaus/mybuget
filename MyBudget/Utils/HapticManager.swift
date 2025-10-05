import UIKit
import CoreHaptics

// MARK: - Haptic Manager
class HapticManager {
    // MARK: - Properties
    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    init() {
        prepareHaptics()
        setupHapticEngine()
    }
    
    // MARK: - Setup
    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
        }
    }
    
    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        switch style {
        case .light:
            impactLight.impactOccurred(intensity: intensity)
        case .medium:
            impactMedium.impactOccurred(intensity: intensity)
        case .heavy:
            impactHeavy.impactOccurred(intensity: intensity)
        case .soft:
            impactSoft.impactOccurred(intensity: intensity)
        case .rigid:
            impactRigid.impactOccurred(intensity: intensity)
        @unknown default:
            impactMedium.impactOccurred(intensity: intensity)
        }
    }
    
    // MARK: - Selection Feedback
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Custom Patterns
    func playCustomPattern(_ pattern: HapticPattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        do {
            let hapticPattern = try pattern.createCHHapticPattern()
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: 0)
        } catch {
        }
    }
    
    // MARK: - Preset Patterns
    func playSuccessPattern() {
        playCustomPattern(.success)
    }
    
    func playErrorPattern() {
        playCustomPattern(.error)
    }
    
    func playWarningPattern() {
        playCustomPattern(.warning)
    }
    
    func playBouncePattern() {
        playCustomPattern(.bounce)
    }
    
    func playHeartbeatPattern() {
        playCustomPattern(.heartbeat)
    }
}

// MARK: - Haptic Pattern
enum HapticPattern {
    case success
    case error
    case warning
    case bounce
    case heartbeat
    case custom(events: [CHHapticEvent])
    
    func createCHHapticPattern() throws -> CHHapticPattern {
        let events: [CHHapticEvent]
        
        switch self {
        case .success:
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0.1
                )
            ]
            
        case .error:
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0.1
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: 0.2
                )
            ]
            
        case .warning:
            events = [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0,
                    duration: 0.3
                )
            ]
            
        case .bounce:
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0.15
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.25
                )
            ]
            
        case .heartbeat:
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.1
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0.6
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.7
                )
            ]
            
        case .custom(let customEvents):
            events = customEvents
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
}

// MARK: - Haptic Utilities
extension HapticManager {
    // Convenience methods for common interactions
    func buttonTap() {
        impact(.light)
    }
    
    func toggleSwitch() {
        impact(.medium)
    }
    
    func sliderChange() {
        selection()
    }
    
    func dragStart() {
        impact(.medium)
    }
    
    func dragEnd() {
        impact(.light, intensity: 0.6)
    }
    
    func cardSwipe() {
        impact(.soft)
    }
    
    func pullToRefresh() {
        impact(.rigid)
    }
    
    func longPress() {
        impact(.heavy)
    }
}