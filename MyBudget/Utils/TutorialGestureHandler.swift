import SwiftUI
import Foundation

// MARK: - Gesture Direction and Types

enum GestureDirection: String, CaseIterable, Codable {
    case up = "up"
    case down = "down"
    case left = "left"
    case right = "right"
    case upLeft = "up_left"
    case upRight = "up_right"
    case downLeft = "down_left"
    case downRight = "down_right"
    
    var vector: CGVector {
        switch self {
        case .up: return CGVector(dx: 0, dy: -1)
        case .down: return CGVector(dx: 0, dy: 1)
        case .left: return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        case .upLeft: return CGVector(dx: -0.7, dy: -0.7)
        case .upRight: return CGVector(dx: 0.7, dy: -0.7)
        case .downLeft: return CGVector(dx: -0.7, dy: 0.7)
        case .downRight: return CGVector(dx: 0.7, dy: 0.7)
        }
    }
    
    var description: String {
        switch self {
        case .up: return "Swipe up"
        case .down: return "Swipe down"
        case .left: return "Swipe left"
        case .right: return "Swipe right"
        case .upLeft: return "Swipe up-left"
        case .upRight: return "Swipe up-right"
        case .downLeft: return "Swipe down-left"
        case .downRight: return "Swipe down-right"
        }
    }
}

enum TutorialGestureType: String, CaseIterable, Codable {
    case tap = "tap"
    case doubleTap = "double_tap"
    case longPress = "long_press"
    case swipe = "swipe"
    case pinch = "pinch"
    case rotation = "rotation"
    case pan = "pan"
    case drag = "drag"
    
    var systemImageName: String {
        switch self {
        case .tap: return "hand.tap.fill"
        case .doubleTap: return "hand.tap.fill"
        case .longPress: return "hand.tap.fill"
        case .swipe: return "hand.draw.fill"
        case .pinch: return "hand.pinch.fill"
        case .rotation: return "arrow.clockwise"
        case .pan: return "hand.draw.fill"
        case .drag: return "move.3d"
        }
    }
    
    var description: String {
        switch self {
        case .tap: return "Tap"
        case .doubleTap: return "Double tap"
        case .longPress: return "Long press"
        case .swipe: return "Swipe"
        case .pinch: return "Pinch"
        case .rotation: return "Rotate"
        case .pan: return "Pan"
        case .drag: return "Drag"
        }
    }
}

// MARK: - Gesture Configuration

struct GestureConfiguration: Codable {
    let type: TutorialGestureType
    let direction: GestureDirection?
    let minimumDistance: CGFloat
    let velocityThreshold: CGFloat
    let timeWindow: TimeInterval
    let allowedDeviation: CGFloat
    
    init(
        type: TutorialGestureType,
        direction: GestureDirection? = nil,
        minimumDistance: CGFloat = 50.0,
        velocityThreshold: CGFloat = 100.0,
        timeWindow: TimeInterval = 1.0,
        allowedDeviation: CGFloat = 0.3
    ) {
        self.type = type
        self.direction = direction
        self.minimumDistance = minimumDistance
        self.velocityThreshold = velocityThreshold
        self.timeWindow = timeWindow
        self.allowedDeviation = allowedDeviation
    }
    
    static let defaultConfigurations: [TutorialGestureType: GestureConfiguration] = [
        .tap: GestureConfiguration(type: .tap, minimumDistance: 0, velocityThreshold: 0, timeWindow: 0.5),
        .doubleTap: GestureConfiguration(type: .doubleTap, minimumDistance: 10, velocityThreshold: 0, timeWindow: 0.3),
        .longPress: GestureConfiguration(type: .longPress, minimumDistance: 0, velocityThreshold: 0, timeWindow: 0.8),
        .swipe: GestureConfiguration(type: .swipe, minimumDistance: 100, velocityThreshold: 200, timeWindow: 1.0),
        .pinch: GestureConfiguration(type: .pinch, minimumDistance: 20, velocityThreshold: 50, timeWindow: 2.0),
        .pan: GestureConfiguration(type: .pan, minimumDistance: 30, velocityThreshold: 50, timeWindow: 3.0),
        .drag: GestureConfiguration(type: .drag, minimumDistance: 50, velocityThreshold: 100, timeWindow: 5.0)
    ]
}

// MARK: - Gesture Recognition Result

struct GestureRecognitionResult {
    let type: TutorialGestureType
    let direction: GestureDirection?
    let startPoint: CGPoint
    let endPoint: CGPoint
    let velocity: CGVector
    let duration: TimeInterval
    let confidence: Double
    let timestamp: Date
    
    init(
        type: TutorialGestureType,
        direction: GestureDirection? = nil,
        startPoint: CGPoint,
        endPoint: CGPoint,
        velocity: CGVector = .zero,
        duration: TimeInterval,
        confidence: Double = 1.0
    ) {
        self.type = type
        self.direction = direction
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.velocity = velocity
        self.duration = duration
        self.confidence = confidence
        self.timestamp = Date()
    }
}

// MARK: - Tutorial Gesture Handler

@MainActor
class TutorialGestureHandler: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var canSwipeToNext: Bool = false
    @Published var canSwipeToPrevious: Bool = false
    @Published var isGestureInProgress: Bool = false
    @Published var currentGestureProgress: Double = 0.0
    @Published var gestureHint: String?
    @Published var expectedGesture: TutorialGestureType?
    @Published var expectedDirection: GestureDirection?
    
    // MARK: - Private Properties
    
    private var gestureStartTime: Date?
    private var gestureStartPoint: CGPoint = .zero
    private var lastGestureEndTime: Date?
    private var tapCount: Int = 0
    private var gestureConfiguration: [TutorialGestureType: GestureConfiguration] = GestureConfiguration.defaultConfigurations
    private var recognizedGestures: [GestureRecognitionResult] = []
    private var onGestureRecognized: ((GestureRecognitionResult) -> Void)?
    private var onNavigationGesture: ((GestureDirection) -> Void)?
    private var doubleTapWorkItem: DispatchWorkItem?
    
    deinit {
        doubleTapWorkItem?.cancel()
    }
    
    // MARK: - Configuration
    
    func setGestureCallback(_ callback: @escaping (GestureRecognitionResult) -> Void) {
        self.onGestureRecognized = callback
    }
    
    func setNavigationCallback(_ callback: @escaping (GestureDirection) -> Void) {
        self.onNavigationGesture = callback
    }
    
    func setExpectedGesture(_ type: TutorialGestureType, direction: GestureDirection? = nil) {
        self.expectedGesture = type
        self.expectedDirection = direction
        
        // Update gesture hint
        if let direction = direction {
            self.gestureHint = "\(type.description) \(direction.description.lowercased())"
        } else {
            self.gestureHint = type.description
        }
    }
    
    func enableNavigationGestures(previous: Bool = true, next: Bool = true) {
        self.canSwipeToPrevious = previous
        self.canSwipeToNext = next
    }
    
    func clearExpectedGesture() {
        self.expectedGesture = nil
        self.expectedDirection = nil
        self.gestureHint = nil
    }
    
    // MARK: - Gesture Processing
    
    func handleTapGesture(at location: CGPoint) {
        let now = Date()
        
        // Check for double tap
        if let lastEndTime = lastGestureEndTime,
           now.timeIntervalSince(lastEndTime) < gestureConfiguration[.doubleTap]?.timeWindow ?? 0.3,
           tapCount == 1 {
            
            tapCount = 2
            let result = GestureRecognitionResult(
                type: .doubleTap,
                startPoint: location,
                endPoint: location,
                duration: now.timeIntervalSince(lastEndTime),
                confidence: 1.0
            )
            processGestureResult(result)
            
        } else {
            tapCount = 1
            
            // Cancel any existing double tap work item
            doubleTapWorkItem?.cancel()
            
            // Wait for potential second tap
            let workItem = DispatchWorkItem {
                if self.tapCount == 1 {
                    let result = GestureRecognitionResult(
                        type: .tap,
                        startPoint: location,
                        endPoint: location,
                        duration: 0.1,
                        confidence: 1.0
                    )
                    self.processGestureResult(result)
                }
                self.tapCount = 0
            }
            doubleTapWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + (gestureConfiguration[.doubleTap]?.timeWindow ?? 0.3), execute: workItem)
        }
        
        lastGestureEndTime = now
        provideTactileFeedback(.selection)
    }
    
    func handleLongPressGesture(at location: CGPoint, state: UILongPressGestureRecognizer.State) {
        switch state {
        case .began:
            gestureStartTime = Date()
            gestureStartPoint = location
            isGestureInProgress = true
            
        case .ended:
            guard let startTime = gestureStartTime else { return }
            let duration = Date().timeIntervalSince(startTime)
            
            let result = GestureRecognitionResult(
                type: .longPress,
                startPoint: gestureStartPoint,
                endPoint: location,
                duration: duration,
                confidence: duration >= (gestureConfiguration[.longPress]?.timeWindow ?? 0.8) ? 1.0 : 0.5
            )
            processGestureResult(result)
            
            resetGestureState()
            provideTactileFeedback(.impact(.medium))
            
        case .cancelled, .failed:
            resetGestureState()
            
        default:
            break
        }
    }
    
    func handleDragChange(_ value: DragGesture.Value) {
        if gestureStartTime == nil {
            gestureStartTime = Date()
            gestureStartPoint = value.startLocation
            isGestureInProgress = true
        }
        
        let translation = value.translation
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        
        // Update progress for visual feedback
        if let config = gestureConfiguration[.swipe] {
            currentGestureProgress = min(1.0, distance / config.minimumDistance)
        }
        
        // Determine direction for navigation hints
        if distance > 30 {
            let direction = getGestureDirection(from: translation)
            updateNavigationHints(for: direction)
        }
    }
    
    func handleDragEnd(_ value: DragGesture.Value) {
        guard let startTime = gestureStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let translation = value.translation
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        let direction = getGestureDirection(from: translation)
        
        // Determine gesture type based on characteristics
        let gestureType: TutorialGestureType
        if distance < 20 && duration < 0.5 {
            gestureType = .tap
        } else if distance >= (gestureConfiguration[.swipe]?.minimumDistance ?? 100) && duration < 1.0 {
            gestureType = .swipe
        } else {
            gestureType = .drag
        }
        
        let velocity = CGVector(
            dx: value.predictedEndTranslation.width / duration,
            dy: value.predictedEndTranslation.height / duration
        )
        
        let result = GestureRecognitionResult(
            type: gestureType,
            direction: gestureType == .swipe ? direction : nil,
            startPoint: value.startLocation,
            endPoint: value.location,
            velocity: velocity,
            duration: duration,
            confidence: calculateConfidence(for: gestureType, distance: distance, duration: duration)
        )
        
        // Handle navigation gestures
        if gestureType == .swipe {
            handleNavigationGesture(direction)
        }
        
        processGestureResult(result)
        resetGestureState()
        
        // Provide appropriate haptic feedback
        provideTactileFeedback(.impact(.light))
    }
    
    // MARK: - Direction Calculation
    
    private func getGestureDirection(from translation: CGSize) -> GestureDirection {
        let angle = atan2(translation.height, translation.width)
        let degrees = angle * 180 / .pi
        
        switch degrees {
        case -22.5...22.5:
            return .right
        case 22.5...67.5:
            return .downRight
        case 67.5...112.5:
            return .down
        case 112.5...157.5:
            return .downLeft
        case 157.5...180, -180...(-157.5):
            return .left
        case -157.5...(-112.5):
            return .upLeft
        case -112.5...(-67.5):
            return .up
        case -67.5...(-22.5):
            return .upRight
        default:
            return .right
        }
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(for gestureType: TutorialGestureType, distance: CGFloat, duration: TimeInterval) -> Double {
        guard let config = gestureConfiguration[gestureType] else { return 0.5 }
        
        var confidence = 1.0
        
        // Distance-based confidence
        if gestureType == .swipe || gestureType == .drag {
            if distance < config.minimumDistance {
                confidence *= distance / config.minimumDistance
            }
        }
        
        // Duration-based confidence
        if gestureType == .longPress {
            if duration < config.timeWindow {
                confidence *= duration / config.timeWindow
            }
        }
        
        // Speed-based confidence for swipes
        if gestureType == .swipe {
            let speed = distance / duration
            if speed < config.velocityThreshold {
                confidence *= speed / config.velocityThreshold
            }
        }
        
        return max(0.0, min(1.0, confidence))
    }
    
    // MARK: - Navigation Handling
    
    private func handleNavigationGesture(_ direction: GestureDirection) {
        switch direction {
        case .left:
            if canSwipeToNext {
                onNavigationGesture?(.left)
            }
        case .right:
            if canSwipeToPrevious {
                onNavigationGesture?(.right)
            }
        default:
            break
        }
    }
    
    private func updateNavigationHints(for direction: GestureDirection) {
        switch direction {
        case .left where canSwipeToNext:
            gestureHint = "Continue swiping left to go next"
        case .right where canSwipeToPrevious:
            gestureHint = "Continue swiping right to go back"
        default:
            gestureHint = expectedGesture?.description ?? "Perform the expected gesture"
        }
    }
    
    // MARK: - Gesture Processing
    
    private func processGestureResult(_ result: GestureRecognitionResult) {
        // Add to history
        recognizedGestures.append(result)
        
        // Keep only last 50 gestures for memory management
        if recognizedGestures.count > 50 {
            recognizedGestures.removeFirst()
        }
        
        // Check if this matches expected gesture
        let isExpectedGesture = validateExpectedGesture(result)
        
        if isExpectedGesture {
        } else {
        }
        
        // Notify callback
        onGestureRecognized?(result)
    }
    
    private func validateExpectedGesture(_ result: GestureRecognitionResult) -> Bool {
        guard let expectedType = expectedGesture else { return true }
        
        if result.type != expectedType {
            return false
        }
        
        if let expectedDir = expectedDirection,
           let resultDir = result.direction {
            return expectedDir == resultDir
        }
        
        return true
    }
    
    // MARK: - State Management
    
    private func resetGestureState() {
        isGestureInProgress = false
        currentGestureProgress = 0.0
        gestureStartTime = nil
        gestureStartPoint = .zero
    }
    
    // MARK: - Haptic Feedback
    
    private func provideTactileFeedback(_ type: TactileFeedbackType) {
        switch type {
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        case .notification(let type):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        }
    }
    
    // MARK: - Analytics
    
    func getGestureAnalytics() -> [String: Any] {
        let totalGestures = recognizedGestures.count
        let gestureTypeCounts = recognizedGestures.reduce(into: [:]) { counts, gesture in
            counts[gesture.type.rawValue, default: 0] += 1
        }
        
        let averageConfidence = recognizedGestures.isEmpty ? 0.0 :
            recognizedGestures.reduce(0.0) { $0 + $1.confidence } / Double(recognizedGestures.count)
        
        return [
            "totalGestures": totalGestures,
            "gestureTypeCounts": gestureTypeCounts,
            "averageConfidence": averageConfidence,
            "sessionDuration": Date().timeIntervalSince(recognizedGestures.first?.timestamp ?? Date())
        ]
    }
    
    func clearGestureHistory() {
        recognizedGestures.removeAll()
    }
}

// MARK: - Tactile Feedback Types

enum TactileFeedbackType {
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
}

// MARK: - Gesture Navigation View

struct GestureNavigationView<Content: View>: View {
    @ViewBuilder let content: Content
    @StateObject private var gestureHandler = TutorialGestureHandler()
    @State private var dragOffset: CGSize = .zero
    
    let onNext: (() -> Void)?
    let onPrevious: (() -> Void)?
    let canGoNext: Bool
    let canGoPrevious: Bool
    
    init(
        canGoNext: Bool = true,
        canGoPrevious: Bool = true,
        onNext: (() -> Void)? = nil,
        onPrevious: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.canGoNext = canGoNext
        self.canGoPrevious = canGoPrevious
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(dragOffset)
            .environmentObject(gestureHandler)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        gestureHandler.handleDragChange(value)
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                        gestureHandler.handleDragEnd(value)
                    }
            )
            .onAppear {
                gestureHandler.enableNavigationGestures(
                    previous: canGoPrevious,
                    next: canGoNext
                )
                
                gestureHandler.setNavigationCallback { direction in
                    switch direction {
                    case .left:
                        onNext?()
                    case .right:
                        onPrevious?()
                    default:
                        break
                    }
                }
            }
            .overlay(
                gestureProgressIndicator,
                alignment: .bottom
            )
    }
    
    @ViewBuilder
    private var gestureProgressIndicator: some View {
        if gestureHandler.isGestureInProgress && gestureHandler.currentGestureProgress > 0 {
            VStack {
                Spacer()
                
                HStack {
                    if canGoPrevious {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .opacity(dragOffset.width > 50 ? 1.0 : 0.3)
                    }
                    
                    Spacer()
                    
                    if let hint = gestureHandler.gestureHint {
                        Text(hint)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if canGoNext {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.primary)
                            .opacity(dragOffset.width < -50 ? 1.0 : 0.3)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Preview

struct GestureNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        GestureNavigationView(
            canGoNext: true,
            canGoPrevious: true,
        ) {
            VStack(spacing: 20) {
                Text("Tutorial Content")
                    .font(.title)
                
                Text("Swipe left to continue or right to go back")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button("Tap me!") {
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
        }
    }
}