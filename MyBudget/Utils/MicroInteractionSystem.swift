import SwiftUI
import Combine

// MARK: - Micro-interaction Types
enum MicroInteractionType: String, CaseIterable {
    case buttonTap = "button_tap"
    case cardSelection = "card_selection"
    case swipeGesture = "swipe_gesture"
    case longPress = "long_press"
    case formValidation = "form_validation"
    case progressUpdate = "progress_update"
    case achievement = "achievement"
    case error = "error"
    case success = "success"
    case navigation = "navigation"
    case dataLoad = "data_load"
    case refresh = "refresh"
    
    var defaultFeedback: HapticFeedbackPattern {
        switch self {
        case .buttonTap:
            return .impact(.light)
        case .cardSelection:
            return .impact(.medium)
        case .swipeGesture:
            return .selection
        case .longPress:
            return .impact(.heavy)
        case .formValidation:
            return .notification(.warning)
        case .progressUpdate:
            return .selection
        case .achievement:
            return .notification(.success)
        case .error:
            return .notification(.error)
        case .success:
            return .notification(.success)
        case .navigation:
            return .impact(.light)
        case .dataLoad:
            return .selection
        case .refresh:
            return .impact(.medium)
        }
    }
    
    var defaultAnimation: MicroAnimationType {
        switch self {
        case .buttonTap:
            return .scale(factor: 0.95, duration: 0.1)
        case .cardSelection:
            return .scaleAndGlow(scaleFactor: 1.05, duration: 0.2)
        case .swipeGesture:
            return .slide(direction: .horizontal, distance: 10, duration: 0.3)
        case .longPress:
            return .pulse(intensity: 1.2, duration: 0.5)
        case .formValidation:
            return .shake(intensity: 5, duration: 0.3)
        case .progressUpdate:
            return .expand(factor: 1.1, duration: 0.4)
        case .achievement:
            return .bounce(intensity: 1.3, duration: 0.6)
        case .error:
            return .shake(intensity: 8, duration: 0.5)
        case .success:
            return .checkmark(duration: 0.8)
        case .navigation:
            return .fade(duration: 0.2)
        case .dataLoad:
            return .shimmer(duration: 1.0)
        case .refresh:
            return .rotate(angle: 360, duration: 0.5)
        }
    }
}

// MARK: - Haptic Feedback Patterns
enum HapticFeedbackPattern {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
    case selection
    case custom([HapticEvent])
}

struct HapticEvent {
    let type: HapticFeedbackPattern
    let delay: TimeInterval
}

// MARK: - Micro Animation Types
enum MicroAnimationType {
    case scale(factor: CGFloat, duration: TimeInterval)
    case scaleAndGlow(scaleFactor: CGFloat, duration: TimeInterval)
    case slide(direction: SlideDirection, distance: CGFloat, duration: TimeInterval)
    case pulse(intensity: CGFloat, duration: TimeInterval)
    case shake(intensity: CGFloat, duration: TimeInterval)
    case expand(factor: CGFloat, duration: TimeInterval)
    case bounce(intensity: CGFloat, duration: TimeInterval)
    case checkmark(duration: TimeInterval)
    case fade(duration: TimeInterval)
    case shimmer(duration: TimeInterval)
    case rotate(angle: Double, duration: TimeInterval)
    case morphColor(from: Color, to: Color, duration: TimeInterval)
    case ripple(intensity: CGFloat, duration: TimeInterval)
}

enum SlideDirection {
    case horizontal
    case vertical
    case diagonal
}

// MARK: - Micro Interaction Manager
@MainActor
class MicroInteractionManager: ObservableObject {
    static let shared = MicroInteractionManager()
    
    @Published var isHapticEnabled: Bool = true
    @Published var isSoundEnabled: Bool = true
    @Published var animationIntensity: AnimationIntensity = .normal
    @Published var interactionHistory: [MicroInteractionEvent] = []
    
    private let hapticGenerator = HapticFeedbackGenerator()
    private let soundPlayer = SoundPlayer()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Core Interaction Method
    
    func trigger(
        _ type: MicroInteractionType,
        withCustomFeedback customFeedback: HapticFeedbackPattern? = nil,
        withCustomAnimation customAnimation: MicroAnimationType? = nil,
        context: String = "",
        metadata: [String: Any] = [:]
    ) {
        let event = MicroInteractionEvent(
            type: type,
            timestamp: Date(),
            context: context,
            metadata: metadata
        )
        
        // Record interaction
        recordInteraction(event)
        
        // Provide haptic feedback
        if isHapticEnabled {
            let feedback = customFeedback ?? type.defaultFeedback
            hapticGenerator.generateFeedback(feedback)
        }
        
        // Play sound if enabled
        if isSoundEnabled {
            soundPlayer.playSound(for: type)
        }
        
    }
    
    // MARK: - Specialized Interaction Methods
    
    func triggerButtonTap(context: String = "button") {
        trigger(.buttonTap, context: context)
    }
    
    func triggerCardSelection(context: String = "card") {
        trigger(.cardSelection, context: context)
    }
    
    func triggerFormValidation(isValid: Bool, context: String = "form") {
        let feedback: HapticFeedbackPattern = isValid ? .notification(.success) : .notification(.error)
        let animation: MicroAnimationType = isValid ? .checkmark(duration: 0.8) : .shake(intensity: 8, duration: 0.5)
        
        trigger(
            isValid ? .success : .error,
            withCustomFeedback: feedback,
            withCustomAnimation: animation,
            context: context,
            metadata: ["isValid": isValid]
        )
    }
    
    func triggerProgressUpdate(progress: Double, context: String = "progress") {
        trigger(
            .progressUpdate,
            context: context,
            metadata: ["progress": progress]
        )
    }
    
    func triggerAchievement(achievementName: String, context: String = "achievement") {
        // Special celebration pattern
        let celebrationFeedback = HapticFeedbackPattern.custom([
            HapticEvent(type: .impact(.medium), delay: 0.0),
            HapticEvent(type: .impact(.light), delay: 0.1),
            HapticEvent(type: .impact(.light), delay: 0.2),
            HapticEvent(type: .notification(.success), delay: 0.4)
        ])
        
        trigger(
            .achievement,
            withCustomFeedback: celebrationFeedback,
            context: context,
            metadata: ["achievement": achievementName]
        )
    }
    
    func triggerError(errorMessage: String, context: String = "error") {
        trigger(
            .error,
            context: context,
            metadata: ["errorMessage": errorMessage]
        )
    }
    
    func triggerDataLoad(isStarting: Bool, context: String = "data") {
        if isStarting {
            trigger(.dataLoad, context: "\(context)_start")
        } else {
            trigger(.success, context: "\(context)_complete")
        }
    }
    
    func triggerSwipeNavigation(direction: MicroSwipeDirection, context: String = "navigation") {
        let customAnimation: MicroAnimationType = .slide(
            direction: direction == .next ? .horizontal : .horizontal,
            distance: direction == .next ? -20 : 20,
            duration: 0.3
        )
        
        trigger(
            .swipeGesture,
            withCustomAnimation: customAnimation,
            context: context,
            metadata: ["direction": direction.rawValue]
        )
    }
    
    // MARK: - Settings Management
    
    func updateSettings(
        hapticEnabled: Bool? = nil,
        soundEnabled: Bool? = nil,
        animationIntensity: AnimationIntensity? = nil
    ) {
        if let hapticEnabled = hapticEnabled {
            self.isHapticEnabled = hapticEnabled
        }
        
        if let soundEnabled = soundEnabled {
            self.isSoundEnabled = soundEnabled
        }
        
        if let intensity = animationIntensity {
            self.animationIntensity = intensity
        }
        
        saveSettings()
    }
    
    private func loadSettings() {
        isHapticEnabled = UserDefaults.standard.object(forKey: "MicroInteraction_HapticEnabled") as? Bool ?? true
        isSoundEnabled = UserDefaults.standard.object(forKey: "MicroInteraction_SoundEnabled") as? Bool ?? true
        
        if let intensityRaw = UserDefaults.standard.object(forKey: "MicroInteraction_AnimationIntensity") as? String {
            animationIntensity = AnimationIntensity(rawValue: intensityRaw) ?? .normal
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isHapticEnabled, forKey: "MicroInteraction_HapticEnabled")
        UserDefaults.standard.set(isSoundEnabled, forKey: "MicroInteraction_SoundEnabled")
        UserDefaults.standard.set(animationIntensity.rawValue, forKey: "MicroInteraction_AnimationIntensity")
    }
    
    // MARK: - Analytics
    
    private func recordInteraction(_ event: MicroInteractionEvent) {
        interactionHistory.append(event)
        
        // Keep only last 100 events for memory management
        if interactionHistory.count > 100 {
            interactionHistory.removeFirst()
        }
    }
    
    func getInteractionAnalytics() -> InteractionAnalytics {
        let totalInteractions = interactionHistory.count
        let typeCounts = interactionHistory.reduce(into: [:]) { counts, event in
            counts[event.type.rawValue, default: 0] += 1
        }
        
        let contextCounts = interactionHistory.reduce(into: [:]) { counts, event in
            counts[event.context, default: 0] += 1
        }
        
        return InteractionAnalytics(
            totalInteractions: totalInteractions,
            interactionTypeCounts: typeCounts,
            contextCounts: contextCounts,
            sessionDuration: Date().timeIntervalSince(interactionHistory.first?.timestamp ?? Date()),
            averageInteractionsPerMinute: totalInteractions > 0 ? Double(totalInteractions) / max(1, Date().timeIntervalSince(interactionHistory.first?.timestamp ?? Date()) / 60) : 0
        )
    }
    
    func clearAnalytics() {
        interactionHistory.removeAll()
    }
}

// MARK: - Supporting Types

enum AnimationIntensity: String, CaseIterable {
    case minimal = "minimal"
    case normal = "normal"
    case enhanced = "enhanced"
    
    var scaleFactor: CGFloat {
        switch self {
        case .minimal: return 0.7
        case .normal: return 1.0
        case .enhanced: return 1.3
        }
    }
}

enum MicroSwipeDirection: String {
    case next = "next"
    case previous = "previous"
}

struct MicroInteractionEvent {
    let id = UUID()
    let type: MicroInteractionType
    let timestamp: Date
    let context: String
    let metadata: [String: Any]
}

struct InteractionAnalytics {
    let totalInteractions: Int
    let interactionTypeCounts: [String: Int]
    let contextCounts: [String: Int]
    let sessionDuration: TimeInterval
    let averageInteractionsPerMinute: Double
}

// MARK: - Haptic Feedback Generator

class HapticFeedbackGenerator {
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    func generateFeedback(_ pattern: HapticFeedbackPattern) {
        switch pattern {
        case .impact(.light):
            impactLight.impactOccurred()
        case .impact(.medium):
            impactMedium.impactOccurred()
        case .impact(.heavy):
            impactHeavy.impactOccurred()
        case .impact(.soft):
            impactSoft.impactOccurred()
        case .impact(.rigid):
            impactRigid.impactOccurred()
        case .notification(let type):
            notification.notificationOccurred(type)
        case .selection:
            selection.selectionChanged()
        case .custom(let events):
            executeCustomPattern(events)
        }
    }
    
    private func executeCustomPattern(_ events: [HapticEvent]) {
        for event in events {
            DispatchQueue.main.asyncAfter(deadline: .now() + event.delay) {
                self.generateFeedback(event.type)
            }
        }
    }
}

// MARK: - Sound Player

class SoundPlayer {
    private var soundCache: [String: URL] = [:]
    
    func playSound(for type: MicroInteractionType) {
        // Placeholder for sound implementation
        // Would typically load and play system sounds or custom sounds
    }
}

// MARK: - SwiftUI View Modifiers

struct MicroInteractionModifier: ViewModifier {
    let type: MicroInteractionType
    let context: String
    let metadata: [String: Any]
    
    @State private var isPressed = false
    @State private var animationTrigger = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(getScaleEffect())
            .opacity(getOpacity())
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {
                triggerInteraction()
            }
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                    if pressing {
                        MicroInteractionManager.shared.trigger(
                            .buttonTap,
                            context: "\(context)_press"
                        )
                    }
                },
                perform: {
                    triggerInteraction()
                }
            )
    }
    
    private func triggerInteraction() {
        MicroInteractionManager.shared.trigger(
            type,
            context: context,
            metadata: metadata
        )
        
        // Visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animationTrigger.toggle()
        }
    }
    
    private func getScaleEffect() -> CGFloat {
        let intensity = MicroInteractionManager.shared.animationIntensity
        let basePressScale: CGFloat = 0.95
        
        switch type {
        case .buttonTap, .cardSelection:
            return isPressed ? basePressScale * intensity.scaleFactor : 1.0
        default:
            return 1.0
        }
    }
    
    private func getOpacity() -> Double {
        switch type {
        case .buttonTap:
            return isPressed ? 0.8 : 1.0
        default:
            return 1.0
        }
    }
}

// MARK: - View Extensions

extension View {
    func microInteraction(
        _ type: MicroInteractionType,
        context: String = "",
        metadata: [String: Any] = [:]
    ) -> some View {
        modifier(
            MicroInteractionModifier(
                type: type,
                context: context,
                metadata: metadata
            )
        )
    }
    
    func buttonTapInteraction(context: String = "button") -> some View {
        microInteraction(.buttonTap, context: context)
    }
    
    func cardSelectionInteraction(context: String = "card") -> some View {
        microInteraction(.cardSelection, context: context)
    }
    
    func formValidationInteraction(isValid: Bool, context: String = "form") -> some View {
        microInteraction(isValid ? .success : .error, context: context, metadata: ["isValid": isValid])
    }
}

// MARK: - Specialized Animation Views

struct PulseAnimationView<Content: View>: View {
    let content: Content
    let intensity: CGFloat
    let duration: TimeInterval
    
    @State private var isPulsing = false
    
    init(
        intensity: CGFloat = 1.2,
        duration: TimeInterval = 1.0,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.duration = duration
        self.content = content()
    }
    
    var body: some View {
        content
            .scaleEffect(isPulsing ? intensity : 1.0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShakeAnimationView<Content: View>: View {
    let content: Content
    let intensity: CGFloat
    let duration: TimeInterval
    
    @State private var offset: CGFloat = 0
    
    init(
        intensity: CGFloat = 8,
        duration: TimeInterval = 0.5,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.duration = duration
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(x: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.05).repeatCount(Int(duration / 0.1), autoreverses: true)) {
                    offset = intensity
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    offset = 0
                }
            }
    }
}

struct RippleEffectView: View {
    let intensity: CGFloat
    
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 1
    
    var body: some View {
        Circle()
            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            .scaleEffect(rippleScale)
            .opacity(rippleOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    rippleScale = intensity
                    rippleOpacity = 0
                }
            }
    }
}

// MARK: - Preview Helpers

struct MicroInteractionDemoView: View {
    @StateObject private var interactionManager = MicroInteractionManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Micro-Interaction Demo")
                    .font(.title)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(MicroInteractionType.allCases, id: \.self) { type in
                        Button(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) {
                            interactionManager.trigger(type, context: "demo")
                        }
                        .buttonTapInteraction(context: "demo_\(type.rawValue)")
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                VStack {
                    Text("Settings")
                        .font(.headline)
                    
                    Toggle("Haptic Feedback", isOn: $interactionManager.isHapticEnabled)
                    Toggle("Sound Feedback", isOn: $interactionManager.isSoundEnabled)
                    
                    Picker("Animation Intensity", selection: $interactionManager.animationIntensity) {
                        ForEach(AnimationIntensity.allCases, id: \.self) { intensity in
                            Text(intensity.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct MicroInteractionSystem_Previews: PreviewProvider {
    static var previews: some View {
        MicroInteractionDemoView()
    }
}