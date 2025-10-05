import SwiftUI
import UIKit

struct DashboardDesignSystem {
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Colors
        static let primaryBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
        static let successGreen = Color(red: 0.4, green: 0.8, blue: 0.6)
        static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
        static let errorRed = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let neutralGray = Color(.systemGroupedBackground)
        
        // Gradient Collections
        static let blueGradient = LinearGradient(
            colors: [primaryBlue, primaryBlue.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let greenGradient = LinearGradient(
            colors: [successGreen, successGreen.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warningGradient = LinearGradient(
            colors: [warningOrange, warningOrange.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Glassmorphism
        static let glassBackground = Color.white.opacity(0.15)
        static let glassStroke = Color.white.opacity(0.3)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let sectionHeader = Font.title2.weight(.semibold)
        static let cardTitle = Font.headline.weight(.medium)
        static let body = Font.body.weight(.regular)
        static let caption = Font.caption.weight(.medium)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let strong = Color.black.opacity(0.15)
        
        static let smallShadow = (color: light, radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let mediumShadow = (color: medium, radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let largeShadow = (color: strong, radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - Animations
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Dashboard Glassmorphism Card Style
struct DashboardGlassmorphismCard: ViewModifier {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = DashboardDesignSystem.CornerRadius.medium) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DashboardDesignSystem.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DashboardDesignSystem.Colors.glassStroke, lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
    }
}

// MARK: - Dashboard Neumorphism Card Style
struct DashboardNeumorphismCard: ViewModifier {
    let cornerRadius: CGFloat
    let isPressed: Bool
    
    init(cornerRadius: CGFloat = DashboardDesignSystem.CornerRadius.medium, isPressed: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isPressed = isPressed
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isPressed ? DashboardDesignSystem.Shadow.light : DashboardDesignSystem.Shadow.medium,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 1 : 4,
                        y: isPressed ? 1 : 4
                    )
                    .shadow(
                        color: Color.white.opacity(0.8),
                        radius: isPressed ? 1 : 4,
                        x: isPressed ? -1 : -2,
                        y: isPressed ? -1 : -2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DashboardDesignSystem.Animation.quick, value: isPressed)
    }
}

// MARK: - View Modifiers Extensions
extension View {
    func glassmorphismCard(cornerRadius: CGFloat = DashboardDesignSystem.CornerRadius.medium) -> some View {
        modifier(DashboardGlassmorphismCard(cornerRadius: cornerRadius))
    }
    
    func neumorphismCard(cornerRadius: CGFloat = DashboardDesignSystem.CornerRadius.medium, isPressed: Bool = false) -> some View {
        modifier(DashboardNeumorphismCard(cornerRadius: cornerRadius, isPressed: isPressed))
    }
    
    func dashboardCardShadow() -> some View {
        shadow(
            color: DashboardDesignSystem.Shadow.smallShadow.color,
            radius: DashboardDesignSystem.Shadow.smallShadow.radius,
            x: DashboardDesignSystem.Shadow.smallShadow.x,
            y: DashboardDesignSystem.Shadow.smallShadow.y
        )
    }
}