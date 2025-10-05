import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let bounce: Bool
    
    init(duration: Double = 1.5, bounce: Bool = false) {
        self.duration = duration
        self.bounce = bounce
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(AnimatedMask(phase: phase))
            .animation(
                .linear(duration: duration)
                .repeatForever(autoreverses: bounce),
                value: phase
            )
            .onAppear {
                phase = 0.8
            }
    }
    
    struct AnimatedMask: AnimatableModifier {
        var phase: CGFloat = 0
        
        var animatableData: CGFloat {
            get { phase }
            set { phase = newValue }
        }
        
        func body(content: Content) -> some View {
            content
                .mask(GradientMask(phase: phase))
        }
    }
    
    struct GradientMask: View {
        let phase: CGFloat
        let centerColor = Color.black
        let edgeColor = Color.black.opacity(0.3)
        
        var body: some View {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: edgeColor, location: phase),
                    .init(color: centerColor, location: phase + 0.1),
                    .init(color: edgeColor, location: phase + 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LoadingPlaceholder: View {
    let height: CGFloat
    let width: CGFloat?
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, width: CGFloat? = nil, cornerRadius: CGFloat = 4) {
        self.height = height
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(Color(.systemFill))
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .modifier(ShimmerEffect())
    }
}

extension View {
    func shimmerEffect(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }
}