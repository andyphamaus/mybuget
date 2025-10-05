import SwiftUI

// MARK: - Particle Emitter System

struct ParticleEmitter: View {
    let particleCount: Int
    let particleLifetime: Double
    let emissionAngle: Angle
    let colors: [Color]
    
    @State private var particles: [EmittedParticle] = []
    @State private var isActive = false
    
    struct EmittedParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var life: Double
        var maxLife: Double
        let color: Color
        let size: Double
        var opacity: Double
        var rotation: Double
        var rotationSpeed: Double
        
        mutating func update(deltaTime: Double) {
            // Update position
            position.x += velocity.dx * deltaTime
            position.y += velocity.dy * deltaTime
            
            // Update life
            life -= deltaTime
            
            // Update opacity based on life remaining
            opacity = max(0, life / maxLife)
            
            // Update rotation
            rotation += rotationSpeed * deltaTime
            
            // Add some physics
            velocity.dy += 50 * deltaTime // gravity
            velocity.dx *= 0.99 // air resistance
            velocity.dy *= 0.99
        }
        
        var isAlive: Bool {
            life > 0
        }
        
        var scale: Double {
            let lifeRatio = life / maxLife
            return 0.3 + (lifeRatio * 0.7) // Scale from 0.3 to 1.0
        }
    }
    
    init(
        particleCount: Int = 20,
        particleLifetime: Double = 3.0,
        emissionAngle: Angle = .degrees(0),
        colors: [Color] = [.blue, .green, .purple]
    ) {
        self.particleCount = particleCount
        self.particleLifetime = particleLifetime
        self.emissionAngle = emissionAngle
        self.colors = colors.isEmpty ? [.blue] : colors
    }
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x - particle.size * particle.scale / 2,
                    y: particle.position.y - particle.size * particle.scale / 2,
                    width: particle.size * particle.scale,
                    height: particle.size * particle.scale
                )
                
                context.opacity = particle.opacity
                context.rotate(by: .degrees(particle.rotation))
                
                // Draw particle as a circle with gradient
                let path = Circle().path(in: rect)
                context.fill(
                    path,
                    with: .radialGradient(
                        Gradient(colors: [
                            particle.color.opacity(0.8),
                            particle.color.opacity(0.3),
                            Color.clear
                        ]),
                        center: CGPoint(x: rect.midX, y: rect.midY),
                        startRadius: 0,
                        endRadius: particle.size * particle.scale / 2
                    )
                )
            }
        }
        .onAppear {
            startEmission()
        }
        .onDisappear {
            stopEmission()
        }
    }
    
    private func startEmission() {
        isActive = true
        
        // Start the particle update timer
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { timer in
            guard isActive else {
                timer.invalidate()
                return
            }
            
            updateParticles()
            
            // Stop if no particles are alive and we're not active
            if !isActive && particles.isEmpty {
                timer.invalidate()
            }
        }
        
        // Emit initial burst of particles
        emitParticles(count: particleCount)
        
        // Continue emitting particles over time
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isActive else {
                timer.invalidate()
                return
            }
            
            // Emit new particles to maintain count
            let aliveCount = particles.filter { $0.isAlive }.count
            let neededCount = min(3, particleCount - aliveCount)
            if neededCount > 0 {
                emitParticles(count: neededCount)
            }
        }
    }
    
    private func stopEmission() {
        isActive = false
    }
    
    private func emitParticles(count: Int) {
        for _ in 0..<count {
            let angle = emissionAngle.radians + Double.random(in: -0.5...0.5)
            let speed = Double.random(in: 50...150)
            
            let particle = EmittedParticle(
                position: CGPoint(
                    x: Double.random(in: 0...300),
                    y: Double.random(in: 0...300)
                ),
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                life: particleLifetime + Double.random(in: -0.5...0.5),
                maxLife: particleLifetime,
                color: colors.randomElement() ?? .blue,
                size: Double.random(in: 4...12),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180)
            )
            
            particles.append(particle)
        }
    }
    
    private func updateParticles() {
        let deltaTime = 1.0 / 60.0
        
        // Update all particles
        for i in particles.indices {
            particles[i].update(deltaTime: deltaTime)
        }
        
        // Remove dead particles
        particles.removeAll { !$0.isAlive }
    }
}

// MARK: - Burst Particle Effect

struct BurstParticleEffect: View {
    let centerPoint: CGPoint
    let colors: [Color]
    let particleCount: Int
    
    @State private var isAnimating = false
    
    init(
        centerPoint: CGPoint = CGPoint(x: 150, y: 150),
        colors: [Color] = [.yellow, .orange, .red],
        particleCount: Int = 15
    ) {
        self.centerPoint = centerPoint
        self.colors = colors
        self.particleCount = particleCount
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .yellow)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: isAnimating ? Double.random(in: -100...100) : 0,
                        y: isAnimating ? Double.random(in: -100...100) : 0
                    )
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(Double(index) * 0.05),
                        value: isAnimating
                    )
            }
        }
        .position(centerPoint)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Confetti Burst

struct ConfettiBurst: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill([Color.red, .green, .blue, .yellow, .pink, .purple].randomElement() ?? .blue)
                    .frame(width: 6, height: 6)
                    .offset(
                        x: animate ? Double.random(in: -200...200) : 0,
                        y: animate ? Double.random(in: -200...200) : 0
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2.0)
                        .delay(Double(index) * 0.02),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Preview

#Preview("Particle Emitter") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ParticleEmitter(
            particleCount: 25,
            particleLifetime: 3.0,
            emissionAngle: .degrees(-90),
            colors: [.cyan, .blue, .purple, .pink]
        )
    }
}

#Preview("Burst Effect") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        BurstParticleEffect(
            centerPoint: CGPoint(x: 200, y: 200),
            colors: [.yellow, .orange, .red, .pink]
        )
    }
}

#Preview("Confetti") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ConfettiBurst()
    }
}