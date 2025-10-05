import SwiftUI

// MARK: - Advanced Glassmorphism Card Component

struct GlassmorphismCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let glassIntensity: Double
    let borderWidth: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    
    init(
        content: Content,
        cornerRadius: CGFloat = 20,
        glassIntensity: Double = 0.7,
        borderWidth: CGFloat = 1,
        shadowRadius: CGFloat = 15,
        shadowOpacity: Double = 0.15
    ) {
        self.content = content
        self.cornerRadius = cornerRadius
        self.glassIntensity = glassIntensity
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
    }
    
    var body: some View {
        ZStack {
            // Main glass background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Gradient overlay for enhanced glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3 * glassIntensity),
                                    Color.white.opacity(0.1 * glassIntensity),
                                    Color.white.opacity(0.05 * glassIntensity)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    // Border with gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8 * glassIntensity),
                                    Color.white.opacity(0.2 * glassIntensity),
                                    Color.white.opacity(0.1 * glassIntensity)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                )
                .shadow(
                    color: Color.black.opacity(shadowOpacity),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius / 2
                )
            
            // Content
            content
        }
    }
}

// MARK: - Enhanced Glassmorphism Card with Custom Background

struct EnhancedGlassCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let blurIntensity: Double
    let borderColor: Color
    let shadowColor: Color
    
    @State private var shimmerOffset: CGFloat = -200
    @State private var isShimmering = false
    
    init(
        content: Content,
        backgroundColor: Color = .clear,
        cornerRadius: CGFloat = 24,
        blurIntensity: Double = 0.8,
        borderColor: Color = .white.opacity(0.3),
        shadowColor: Color = .black.opacity(0.1)
    ) {
        self.content = content
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.blurIntensity = blurIntensity
        self.borderColor = borderColor
        self.shadowColor = shadowColor
    }
    
    var body: some View {
        ZStack {
            // Background with blur
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .background(.ultraThinMaterial)
                .overlay(
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4 * blurIntensity),
                                    Color.white.opacity(0.1 * blurIntensity),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                )
                .overlay(
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: shimmerOffset)
                        .opacity(isShimmering ? 1 : 0)
                        .animation(
                            .linear(duration: 2.0)
                            .repeatForever(autoreverses: false),
                            value: shimmerOffset
                        )
                        .clipped()
                )
                .overlay(
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1.5)
                )
                .shadow(color: shadowColor, radius: 20, x: 0, y: 10)
            
            // Content
            content
        }
        .onAppear {
            startShimmer()
        }
    }
    
    private func startShimmer() {
        // Delay before starting shimmer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                isShimmering = true
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Morphing Glass Container

struct MorphingGlassContainer<Content: View>: View {
    let content: Content
    let isExpanded: Bool
    let cornerRadius: CGFloat
    
    @State private var morphAnimation = false
    
    init(
        content: Content,
        isExpanded: Bool = false,
        cornerRadius: CGFloat = 20
    ) {
        self.content = content
        self.isExpanded = isExpanded
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            // Base glass shape
            RoundedRectangle(
                cornerRadius: morphAnimation ? cornerRadius * 1.5 : cornerRadius
            )
            .fill(.regularMaterial)
            .overlay(
                // Animated gradient
                RoundedRectangle(
                    cornerRadius: morphAnimation ? cornerRadius * 1.5 : cornerRadius
                )
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3),
                            Color.pink.opacity(0.3),
                            Color.blue.opacity(0.3)
                        ]),
                        center: .center,
                        startAngle: .degrees(morphAnimation ? 360 : 0),
                        endAngle: .degrees(morphAnimation ? 720 : 360)
                    )
                )
                .opacity(morphAnimation ? 0.6 : 0.3)
            )
            .scaleEffect(morphAnimation ? 1.05 : 1.0)
            .animation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true),
                value: morphAnimation
            )
            
            // Content
            content
        }
        .onAppear {
            morphAnimation = true
        }
    }
}

// MARK: - Glassmorphism Modifier

struct GlassmorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = 16,
        intensity: Double = 0.8,
        borderWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3 * intensity),
                                        Color.white.opacity(0.1 * intensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                Color.white.opacity(0.5 * intensity),
                                lineWidth: borderWidth
                            )
                    )
            )
    }
}

extension View {
    func glassmorphism(
        cornerRadius: CGFloat = 16,
        intensity: Double = 0.8,
        borderWidth: CGFloat = 1
    ) -> some View {
        self.modifier(
            GlassmorphismModifier(
                cornerRadius: cornerRadius,
                intensity: intensity,
                borderWidth: borderWidth
            )
        )
    }
}

// MARK: - Preview

#Preview("Basic Glass Card") {
    ZStack {
        AnimatedGradientBackground()
        
        VStack(spacing: 20) {
            GlassmorphismCard(
                content: VStack(spacing: 12) {
                    Text("🎯")
                        .font(.system(size: 40))
                    
                    Text("Welcome to Premium")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Experience the future of glassmorphism design with advanced animations and interactions.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                },
                cornerRadius: 28,
                glassIntensity: 0.9
            )
            .padding(24)
            .frame(maxWidth: 300)
            
            EnhancedGlassCard(
                content: VStack(spacing: 8) {
                    Text("Enhanced Glass")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text("With shimmer effects")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                },
                backgroundColor: Color.blue.opacity(0.1),
                cornerRadius: 20
            )
            .padding(16)
            .frame(maxWidth: 200)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Morphing Container") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        MorphingGlassContainer(
            content: VStack {
                Text("🌟")
                    .font(.system(size: 60))
                
                Text("Morphing Glass")
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
        )
        .frame(width: 200, height: 200)
    }
}