import SwiftUI

// MARK: - Floating Glass Tooltip Component

struct FloatingGlassTooltip: View {
    let text: String
    let position: TooltipPosition
    @State private var isVisible = false
    @State private var scale: Double = 0.8
    @State private var opacity: Double = 0
    
    enum TooltipPosition {
        case top, bottom, leading, trailing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if position == .bottom {
                tooltipContent
                arrow
            } else if position == .top {
                arrow
                    .rotationEffect(.degrees(180))
                tooltipContent
            } else {
                HStack(spacing: 0) {
                    if position == .trailing {
                        arrow
                            .rotationEffect(.degrees(90))
                        tooltipContent
                    } else {
                        tooltipContent
                        arrow
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(PremiumAnimations.ultraBouncySpring.delay(0.1)) {
                isVisible = true
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private var tooltipContent: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
    }
    
    private var arrow: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 8, y: 8))
            path.addLine(to: CGPoint(x: 16, y: 0))
            path.closeSubpath()
        }
        .fill(.thinMaterial)
        .frame(width: 16, height: 8)
        .overlay(
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 8, y: 8))
                path.addLine(to: CGPoint(x: 16, y: 0))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
    }
}

// MARK: - Glass Button Component

struct GlassButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, tertiary
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .clear
            case .tertiary: return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return .white
            case .secondary, .tertiary: return .white.opacity(0.9)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return .blue.opacity(0.3)
            case .secondary: return .white.opacity(0.3)
            case .tertiary: return .white.opacity(0.2)
            }
        }
    }
    
    init(title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(style.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(style.backgroundColor)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                    }
                    
                    // Pressed state overlay
                    if isPressed {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.1))
                    }
                    
                    // Border
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style.borderColor, lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(PremiumAnimations.snapAnimation, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AnimatedGradientBackground()
        
        VStack(spacing: 30) {
            FloatingGlassTooltip(
                text: "This is a floating glass tooltip with premium design",
                position: .bottom
            )
            
            HStack(spacing: 16) {
                GlassButton(title: "Primary", icon: "star.fill", style: .primary) {}
                GlassButton(title: "Secondary", icon: "heart", style: .secondary) {}
                GlassButton(title: "Tertiary", style: .tertiary) {}
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}