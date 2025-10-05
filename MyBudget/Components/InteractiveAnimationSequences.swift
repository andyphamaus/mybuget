import SwiftUI

// MARK: - Animation Values
struct InteractiveAnimationValues {
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var rotation: Angle = .zero
    var offset: CGSize = .zero
    var blur: CGFloat = 0.0
    var hue: Angle = .zero
}

// MARK: - Animation Phases
enum InteractiveAnimationPhase: CaseIterable {
    case initial
    case attractAttention
    case demonstrating
    case userInteraction
    case success
    case completed
    
    var description: String {
        switch self {
        case .initial: return "Ready to start"
        case .attractAttention: return "Getting attention"
        case .demonstrating: return "Showing example"
        case .userInteraction: return "Waiting for user"
        case .success: return "Success!"
        case .completed: return "Animation complete"
        }
    }
}

// MARK: - Interactive Budget Demo Animation
struct InteractiveBudgetDemoView: View {
    @State private var animationPhase: InteractiveAnimationPhase = .initial
    @State private var interactionCount: Int = 0
    @State private var totalInteractions: Int = 3
    @State private var showSparkles: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var bounceAnimation: Bool = false
    
    let onCompleted: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Main animation content
            animatedContent
            
            // Interaction instructions
            interactionInstructions
            
            // Progress indicator
            progressIndicator
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    @ViewBuilder
    private var animatedContent: some View {
        ZStack {
            // Background effect
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3),
                            Color.pink.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: animationPhase == .attractAttention ? 10 : 0)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .opacity(animationPhase == .initial ? 0.3 : 0.8)
            
            // Main budget icon
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white)
                .keyframeAnimator(
                    initialValue: InteractiveAnimationValues(),
                    repeating: animationPhase == .demonstrating
                ) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .opacity(value.opacity)
                        .rotationEffect(value.rotation)
                        .offset(value.offset)
                        .blur(radius: value.blur)
                        .hueRotation(value.hue)
                } keyframes: { _ in
                    // Scale keyframes
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.3, duration: 0.5)
                        SpringKeyframe(1.0, duration: 0.5)
                        SpringKeyframe(1.1, duration: 0.3)
                        SpringKeyframe(1.0, duration: 0.2)
                    }
                    
                    // Opacity keyframes
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0.3, duration: 0.25)
                        LinearKeyframe(1.0, duration: 0.25)
                        LinearKeyframe(0.7, duration: 0.25)
                        LinearKeyframe(1.0, duration: 0.25)
                    }
                    
                    // Rotation keyframes
                    KeyframeTrack(\.rotation) {
                        LinearKeyframe(.degrees(10), duration: 0.4)
                        SpringKeyframe(.degrees(-10), duration: 0.4)
                        SpringKeyframe(.degrees(5), duration: 0.3)
                        SpringKeyframe(.degrees(0), duration: 0.4)
                    }
                    
                    // Offset keyframes for floating effect
                    KeyframeTrack(\.offset) {
                        LinearKeyframe(CGSize(width: 0, height: -10), duration: 0.6)
                        LinearKeyframe(CGSize(width: 5, height: 0), duration: 0.4)
                        LinearKeyframe(CGSize(width: -5, height: 5), duration: 0.4)
                        LinearKeyframe(CGSize(width: 0, height: 0), duration: 0.6)
                    }
                    
                    // Hue rotation for color changes
                    KeyframeTrack(\.hue) {
                        LinearKeyframe(.degrees(60), duration: 0.8)
                        LinearKeyframe(.degrees(120), duration: 0.4)
                        LinearKeyframe(.degrees(180), duration: 0.4)
                        LinearKeyframe(.degrees(0), duration: 0.4)
                    }
                }
                .scaleEffect(bounceAnimation ? 0.9 : 1.0)
                .animation(.bouncy(duration: 0.6), value: bounceAnimation)
            
            // Interactive sparkles overlay
            if showSparkles {
                SparkleOverlay(count: 15, size: 4...12)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Success checkmark
            if animationPhase == .success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
                    .background(Circle().fill(Color.white))
                    .offset(x: 50, y: -50)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 220, height: 220)
        .onTapGesture {
            handleUserInteraction()
        }
        .onLongPressGesture {
            handleSpecialInteraction()
        }
    }
    
    @ViewBuilder
    private var interactionInstructions: some View {
        VStack(spacing: 8) {
            Text(getInstructionText())
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .animation(.easeInOut(duration: 0.3), value: animationPhase)
            
            if animationPhase == .userInteraction {
                Text("Tap to interact • Long press for special effect")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var progressIndicator: some View {
        if animationPhase == .userInteraction || animationPhase == .success {
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * (Double(interactionCount) / Double(totalInteractions)),
                                height: 8
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: interactionCount)
                    }
                }
                .frame(height: 8)
                
                Text("\(interactionCount)/\(totalInteractions) interactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .transition(.slide.combined(with: .opacity))
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimationSequence() {
        // Initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                animationPhase = .attractAttention
                pulseAnimation = true
            }
        }
        
        // Start demonstration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animationPhase = .demonstrating
                pulseAnimation = false
            }
        }
        
        // Wait for user interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase = .userInteraction
            }
        }
    }
    
    private func handleUserInteraction() {
        guard animationPhase == .userInteraction else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.bouncy(duration: 0.4)) {
            bounceAnimation.toggle()
            interactionCount += 1
        }
        
        // Show sparkles temporarily
        withAnimation(.easeInOut(duration: 0.3)) {
            showSparkles = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSparkles = false
            }
        }
        
        // Check if completed
        if interactionCount >= totalInteractions {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                completeAnimation()
            }
        }
    }
    
    private func handleSpecialInteraction() {
        guard animationPhase == .userInteraction else { return }
        
        // Special haptic pattern
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showSparkles = true
            interactionCount = min(interactionCount + 2, totalInteractions)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSparkles = false
            }
        }
        
        if interactionCount >= totalInteractions {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                completeAnimation()
            }
        }
    }
    
    private func completeAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationPhase = .success
            showSparkles = true
        }
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.8)) {
                animationPhase = .completed
                showSparkles = false
            }
            
            // Notify completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onCompleted()
            }
        }
    }
    
    private func getInstructionText() -> String {
        switch animationPhase {
        case .initial:
            return "Let's explore budget management together!"
        case .attractAttention:
            return "Watch how budgeting works..."
        case .demonstrating:
            return "See the budget data in action"
        case .userInteraction:
            return "Now it's your turn! Interact with the demo"
        case .success:
            return "Excellent! You're ready to manage your budget"
        case .completed:
            return "Animation completed successfully!"
        }
    }
}

// MARK: - Sparkle Overlay
struct SparkleOverlay: View {
    let count: Int
    let size: ClosedRange<CGFloat>
    
    @State private var sparkles: [SparkleParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(sparkles.indices, id: \.self) { index in
                let sparkle = sparkles[index]
                
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size, weight: .bold))
                    .foregroundColor(sparkle.color)
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
                    .rotationEffect(sparkle.rotation)
            }
        }
        .onAppear {
            generateSparkles()
            animateSparkles()
        }
    }
    
    private func generateSparkles() {
        sparkles = (0..<count).map { _ in
            SparkleParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...220),
                    y: CGFloat.random(in: 0...220)
                ),
                size: CGFloat.random(in: size.lowerBound...size.upperBound),
                color: [.yellow, .orange, .pink, .purple, .blue].randomElement() ?? .yellow,
                opacity: Double.random(in: 0.6...1.0),
                scale: CGFloat.random(in: 0.5...1.2),
                rotation: Angle.degrees(Double.random(in: 0...360))
            )
        }
    }
    
    private func animateSparkles() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            for index in sparkles.indices {
                sparkles[index].opacity = Double.random(in: 0.3...1.0)
                sparkles[index].scale = CGFloat.random(in: 0.3...1.5)
                sparkles[index].rotation = Angle.degrees(Double.random(in: 0...720))
            }
        }
    }
}

// MARK: - Sparkle Particle
struct SparkleParticle {
    var position: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
    var scale: CGFloat
    var rotation: Angle
}

// MARK: - Sequence Control View
struct InteractiveAnimationSequenceView: View {
    @State private var currentSequence: Int = 0
    @State private var isPlaying: Bool = false
    
    let sequences: [AnimationSequenceConfig]
    let onCompleted: () -> Void
    
    init(
        sequences: [AnimationSequenceConfig] = AnimationSequenceConfig.defaultSequences,
        onCompleted: @escaping () -> Void
    ) {
        self.sequences = sequences
        self.onCompleted = onCompleted
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Sequence title
            Text(sequences[currentSequence].title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Current sequence view
            currentSequenceView
            
            // Controls
            sequenceControls
        }
        .padding()
    }
    
    @ViewBuilder
    private var currentSequenceView: some View {
        switch sequences[currentSequence].type {
        case .budgetDemo:
            InteractiveBudgetDemoView {
                advanceToNextSequence()
            }
        case .categoryExploration:
            CategoryExplorationAnimation {
                advanceToNextSequence()
            }
        case .transactionFlow:
            TransactionFlowAnimation {
                advanceToNextSequence()
            }
        case .insightsVisualization:
            InsightsVisualizationAnimation {
                advanceToNextSequence()
            }
        }
    }
    
    @ViewBuilder
    private var sequenceControls: some View {
        HStack(spacing: 20) {
            Button("Skip") {
                advanceToNextSequence()
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            // Sequence indicator
            HStack(spacing: 6) {
                ForEach(sequences.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentSequence ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentSequence ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentSequence)
                }
            }
            
            Spacer()
            
            Button("Next") {
                advanceToNextSequence()
            }
            .foregroundColor(.primary)
        }
    }
    
    private func advanceToNextSequence() {
        if currentSequence < sequences.count - 1 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentSequence += 1
            }
        } else {
            onCompleted()
        }
    }
}

// MARK: - Animation Sequence Configuration
struct AnimationSequenceConfig {
    let id: UUID = UUID()
    let title: String
    let type: AnimationSequenceType
    let duration: TimeInterval
    let interactionRequired: Bool
    
    static let defaultSequences: [AnimationSequenceConfig] = [
        AnimationSequenceConfig(
            title: "Budget Overview Demo",
            type: .budgetDemo,
            duration: 6.0,
            interactionRequired: true
        ),
        AnimationSequenceConfig(
            title: "Category Management",
            type: .categoryExploration,
            duration: 5.0,
            interactionRequired: true
        ),
        AnimationSequenceConfig(
            title: "Transaction Flow",
            type: .transactionFlow,
            duration: 4.0,
            interactionRequired: false
        ),
        AnimationSequenceConfig(
            title: "Insights & Analytics",
            type: .insightsVisualization,
            duration: 5.0,
            interactionRequired: true
        )
    ]
}

enum AnimationSequenceType {
    case budgetDemo
    case categoryExploration
    case transactionFlow
    case insightsVisualization
}

// MARK: - Placeholder Animation Views (to be implemented)
struct CategoryExplorationAnimation: View {
    let onCompleted: () -> Void
    
    var body: some View {
        VStack {
            Text("Category Exploration Animation")
            Text("(Implementation placeholder)")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onCompleted()
            }
        }
    }
}

struct TransactionFlowAnimation: View {
    let onCompleted: () -> Void
    
    var body: some View {
        VStack {
            Text("Transaction Flow Animation")
            Text("(Implementation placeholder)")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onCompleted()
            }
        }
    }
}

struct InsightsVisualizationAnimation: View {
    let onCompleted: () -> Void
    
    var body: some View {
        VStack {
            Text("Insights Visualization Animation")
            Text("(Implementation placeholder)")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onCompleted()
            }
        }
    }
}

// MARK: - Preview
struct InteractiveAnimationSequences_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveAnimationSequenceView {
        }
    }
}
