import SwiftUI
import Combine

// MARK: - Advanced Animation System for Premium Onboarding

struct PremiumAnimations {
    
    // MARK: - Spring Physics Constants
    static let ultraBouncySpring = Animation.interpolatingSpring(
        mass: 0.6,
        stiffness: 100,
        damping: 10,
        initialVelocity: 0.8
    )
    
    static let gentleSpring = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 120,
        damping: 15,
        initialVelocity: 0
    )
    
    static let quickSpring = Animation.interpolatingSpring(
        mass: 0.4,
        stiffness: 200,
        damping: 12,
        initialVelocity: 0.5
    )
    
    static let heroSpring = Animation.interpolatingSpring(
        mass: 0.8,
        stiffness: 80,
        damping: 8,
        initialVelocity: 1.2
    )
    
    // MARK: - Timing Curves
    static let smoothEaseOut = Animation.easeOut(duration: 0.8)
    static let quickFade = Animation.easeInOut(duration: 0.3)
    static let slowReveal = Animation.easeOut(duration: 1.2)
    static let snapAnimation = Animation.easeInOut(duration: 0.2)
}

// MARK: - Animated Background Gradient

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    @State private var gradientRotation: Double = 0
    
    private let colors = [
        Color(red: 0.4, green: 0.8, blue: 0.6),
        Color(red: 0.3, green: 0.7, blue: 0.9),
        Color(red: 0.6, green: 0.4, blue: 0.8),
        Color(red: 0.2, green: 0.6, blue: 0.8)
    ]
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: animateGradient ? 
            [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.3, 0.7], [1.0, 0.5],  
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ] :
            [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.7, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: colors
        )
        .rotationEffect(.degrees(gradientRotation))
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 8.0)
                    .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
            
            withAnimation(
                Animation.linear(duration: 20.0)
                    .repeatForever(autoreverses: false)
            ) {
                gradientRotation = 360
            }
        }
    }
}

// MARK: - Particle Effect System

struct ParticleEffect: View {
    let particleCount: Int
    let colors: [Color]
    let size: CGSize
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var life: Double
        var maxLife: Double
        var color: Color
        var size: Double
        
        mutating func update() {
            position.x += velocity.x
            position.y += velocity.y
            life -= 1/60.0 // 60fps
            velocity.y += 0.5 // gravity
        }
        
        var isAlive: Bool {
            life > 0
        }
        
        var opacity: Double {
            life / maxLife
        }
        
        var scale: Double {
            life / maxLife
        }
    }
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    origin: CGPoint(
                        x: particle.position.x - particle.size/2,
                        y: particle.position.y - particle.size/2
                    ),
                    size: CGSize(width: particle.size, height: particle.size)
                )
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particle.color.opacity(particle.opacity))
                )
            }
        }
        .onAppear {
            startParticleSystem()
        }
    }
    
    private func startParticleSystem() {
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { timer in
            updateParticles()
            
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
    
    private func updateParticles() {
        // Update existing particles
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            updatedParticle.update()
            return updatedParticle.isAlive ? updatedParticle : nil
        }
        
        // Add new particles
        if particles.count < particleCount {
            let newParticle = Particle(
                position: CGPoint(
                    x: Double.random(in: 0...size.width),
                    y: size.height
                ),
                velocity: CGPoint(
                    x: Double.random(in: -2...2),
                    y: Double.random(in: -8...(-3))
                ),
                life: Double.random(in: 2...4),
                maxLife: 4,
                color: colors.randomElement() ?? .blue,
                size: Double.random(in: 2...6)
            )
            particles.append(newParticle)
        }
    }
}

// MARK: - Hero Animation Container

struct HeroAnimationContainer<Content: View>: View {
    let content: Content
    @State private var heroScale: Double = 0.8
    @State private var heroOpacity: Double = 0
    @State private var heroOffset: Double = 50
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .scaleEffect(heroScale)
            .opacity(heroOpacity)
            .offset(y: heroOffset)
            .onAppear {
                withAnimation(PremiumAnimations.heroSpring.delay(0.1)) {
                    heroScale = 1.0
                    heroOpacity = 1.0
                    heroOffset = 0
                }
            }
    }
}

// MARK: - Shimmer Loading Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
            )
            .onAppear {
                phase = 300
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Breathing Animation

struct BreathingModifier: ViewModifier {
    @State private var breathing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(breathing ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: breathing
            )
            .onAppear {
                breathing = true
            }
    }
}

extension View {
    func breathingAnimation() -> some View {
        modifier(BreathingModifier())
    }
}

// MARK: - Confetti Celebration

struct PremiumConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    @State private var animationTimer: Timer?
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var rotation: Double
        var rotationSpeed: Double
        var fallSpeed: Double
        var color: Color
        var size: Double
        
        mutating func update() {
            y += fallSpeed
            rotation += rotationSpeed
            x += sin(y * 0.01) * 0.5
        }
    }
    
    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    var body: some View {
        Canvas { context, size in
            for piece in confetti {
                let rect = CGRect(
                    x: piece.x - piece.size/2,
                    y: piece.y - piece.size/2,
                    width: piece.size,
                    height: piece.size
                )
                
                context.translateBy(x: piece.x, y: piece.y)
                context.rotate(by: .degrees(piece.rotation))
                
                context.fill(
                    Path(CGRect(
                        x: -piece.size/2,
                        y: -piece.size/2,
                        width: piece.size,
                        height: piece.size
                    )),
                    with: .color(piece.color)
                )
                
                context.rotate(by: .degrees(-piece.rotation))
                context.translateBy(x: -piece.x, y: -piece.y)
            }
        }
        .onAppear {
            startConfetti()
        }
        .onDisappear {
            stopConfetti()
        }
    }
    
    private func startConfetti() {
        // Generate initial confetti
        for _ in 0..<50 {
            let newPiece = ConfettiPiece(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10),
                fallSpeed: Double.random(in: 2...6),
                color: colors.randomElement() ?? .blue,
                size: Double.random(in: 4...8)
            )
            confetti.append(newPiece)
        }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            updateConfetti()
        }
    }
    
    private func updateConfetti() {
        confetti = confetti.compactMap { piece in
            var updatedPiece = piece
            updatedPiece.update()
            
            // Remove pieces that are off screen
            return updatedPiece.y < UIScreen.main.bounds.height + 50 ? updatedPiece : nil
        }
        
        // Add new pieces occasionally
        if Double.random(in: 0...1) < 0.1 {
            let newPiece = ConfettiPiece(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10),
                fallSpeed: Double.random(in: 2...6),
                color: colors.randomElement() ?? .blue,
                size: Double.random(in: 4...8)
            )
            confetti.append(newPiece)
        }
    }
    
    private func stopConfetti() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AnimatedGradientBackground()
        
        VStack {
            HeroAnimationContainer {
                Text("Premium Animations")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .breathingAnimation()
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 200, height: 100)
                .shimmer()
        }
        
        PremiumConfettiView()
    }
}