import SwiftUI
import Foundation

// MARK: - Budget Design System
/// Centralized design system for all Budget module components
/// Ensures consistent colors, animations, spacing, and styling across all budget screens

struct BudgetDesignSystem {
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Brand Colors
        static let primary = Color(red: 0.1, green: 0.5, blue: 0.9)        // Deep blue
        static let primaryLight = Color(red: 0.3, green: 0.6, blue: 1.0)    // Light blue
        static let primaryDark = Color(red: 0.05, green: 0.35, blue: 0.7)   // Dark blue
        
        // Success & Positive States
        static let success = Color(red: 0.0, green: 0.7, blue: 0.4)         // Green
        static let successLight = Color(red: 0.2, green: 0.8, blue: 0.5)    // Light green
        static let successDark = Color(red: 0.0, green: 0.5, blue: 0.3)     // Dark green
        
        // Warning & Attention States
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)         // Orange
        static let warningLight = Color(red: 1.0, green: 0.7, blue: 0.3)    // Light orange
        static let warningDark = Color(red: 0.8, green: 0.4, blue: 0.0)     // Dark orange
        
        // Error & Danger States
        static let error = Color(red: 0.9, green: 0.2, blue: 0.2)           // Red
        static let errorLight = Color(red: 1.0, green: 0.4, blue: 0.4)      // Light red
        static let errorDark = Color(red: 0.7, green: 0.1, blue: 0.1)       // Dark red
        
        // Income Colors
        static let income = Color(red: 0.0, green: 0.8, blue: 0.4)          // Bright green
        static let incomeLight = Color(red: 0.2, green: 0.9, blue: 0.5)     // Light green
        static let incomeAccent = Color(red: 0.1, green: 0.6, blue: 0.3)    // Dark green
        
        // Expense Colors
        static let expense = Color(red: 0.9, green: 0.3, blue: 0.3)         // Soft red
        static let expenseLight = Color(red: 1.0, green: 0.5, blue: 0.5)    // Light red
        static let expenseAccent = Color(red: 0.7, green: 0.2, blue: 0.2)   // Dark red
        
        // Savings Colors
        static let savings = Color(red: 0.2, green: 0.6, blue: 0.9)         // Blue
        static let savingsLight = Color(red: 0.4, green: 0.7, blue: 1.0)    // Light blue
        static let savingsAccent = Color(red: 0.1, green: 0.4, blue: 0.7)   // Dark blue
        
        
        // Neutral Colors
        static let background = Color(.systemGroupedBackground)
        static let surface = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        static let border = Color(.separator)
        static let borderLight = Color(.separator).opacity(0.5)
        
        // Category Colors (for visual distinction)
        static let categoryColors: [Color] = [
            Color(red: 0.2, green: 0.7, blue: 1.0),    // Blue
            Color(red: 0.0, green: 0.8, blue: 0.4),    // Green
            Color(red: 1.0, green: 0.3, blue: 0.3),    // Red
            Color(red: 1.0, green: 0.6, blue: 0.0),    // Orange
            Color(red: 0.8, green: 0.0, blue: 0.8),    // Purple
            Color(red: 0.0, green: 0.7, blue: 0.7),    // Teal
            Color(red: 1.0, green: 0.8, blue: 0.0),    // Yellow
            Color(red: 0.9, green: 0.1, blue: 0.5),    // Pink
            Color(red: 0.4, green: 0.6, blue: 0.9),    // Lavender
            Color(red: 0.6, green: 0.8, blue: 0.2),    // Lime
        ]
        
        // Smart Card Severity Colors
        static let severityHigh = Color(red: 0.9, green: 0.2, blue: 0.2)
        static let severityMedium = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let severityLow = Color(red: 1.0, green: 0.8, blue: 0.0)
        static let severityInfo = Color(red: 0.2, green: 0.6, blue: 0.9)
        
        // Glassmorphism Colors (adaptive)
        static let glassBackground = Color(.systemFill).opacity(0.15)
        static let glassBorder = Color(.separator).opacity(0.3)
        
        // Additional Semantic Colors for Dark Theme Support
        static let backgroundPrimary = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let backgroundTertiary = Color(.tertiarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let groupedBackgroundSecondary = Color(.secondarySystemGroupedBackground)
        
        // Overlay Colors (adaptive)
        static let overlayBackground = Color(.black).opacity(0.4)
        static let overlayLight = Color(.systemFill)
        
        // Card and Surface Colors
        static let cardBackground = Color(.secondarySystemBackground)
        static let cardBorder = Color(.separator).opacity(0.2)
        
        // Interactive Element Colors (adaptive)
        static let buttonPrimary = primary
        static let buttonSecondary = Color(.systemFill)
        static let buttonText = Color(.white) // For primary buttons
        static let buttonTextSecondary = Color(.label) // For secondary buttons
        
        // Status Colors (keep existing but ensure visibility)
        static let statusActive = success
        static let statusInactive = Color(.systemGray)
        static let statusPending = warning
        
        // Chart Colors (ensure visibility in both themes)
        static let chartPrimary = primary
        static let chartSecondary = primaryLight
        static let chartTertiary = Color(.systemGray3)
        
        // Helper function to get adaptive text color for overlays
        static func adaptiveTextColor(for background: Color = backgroundPrimary) -> Color {
            return textPrimary
        }
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline.weight(.medium)
        static let body = Font.body
        static let bodyMedium = Font.body.weight(.medium)
        static let callout = Font.callout
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
        static let footnote = Font.footnote
        
        // Custom Budget Typography
        static let budgetAmount = Font.system(size: 32, weight: .bold, design: .rounded)
        static let categoryAmount = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let smallAmount = Font.system(size: 14, weight: .medium, design: .rounded)
        static let percentageText = Font.system(size: 16, weight: .bold, design: .rounded)
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
        
        // Card Padding
        static let cardPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        
        // Section Padding
        static let sectionPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let card: CGFloat = 12
        static let button: CGFloat = 10
    }
    
    // MARK: - Shadow
    struct Shadow {
        static let card = Color.black.opacity(0.05)
        static let cardRadius: CGFloat = 8
        static let cardOffset: CGSize = CGSize(width: 0, height: 2)
        
        static let elevated = Color.black.opacity(0.1)
        static let elevatedRadius: CGFloat = 12
        static let elevatedOffset: CGSize = CGSize(width: 0, height: 4)
        
        static let floating = Color.black.opacity(0.15)
        static let floatingRadius: CGFloat = 16
        static let floatingOffset: CGSize = CGSize(width: 0, height: 8)
    }
    
    // MARK: - Animations
    struct Animation {
        // Standard Animations
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.4)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.5)
        
        // Entry Animations
        static let fadeInUp = SwiftUI.Animation.easeOut(duration: 0.6)
        static let slideInLeft = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.8)
        static let slideInRight = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.8)
        static let scaleIn = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        
        // Progress Animations
        static let progressFill = SwiftUI.Animation.easeInOut(duration: 1.0)
        static let counterUp = SwiftUI.Animation.easeInOut(duration: 0.8)
        
        // Stagger Delays
        static func staggerDelay(index: Int) -> Double {
            return Double(index) * 0.1
        }
    }
    
    // MARK: - Effects
    struct Effects {
        // Blur Effects
        static let backgroundBlur = 10.0
        static let cardBlur = 5.0
        
        // Scale Effects
        static let pressedScale = 0.98
        static let hoverScale = 1.02
        
        // Opacity States
        static let disabled = 0.6
        static let pressed = 0.8
        static let hover = 1.0
    }
}

// MARK: - Helper Functions
extension BudgetDesignSystem.Colors {
    /// Returns appropriate color for transaction type
    static func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "income":
            return income
        case "expense":
            return expense
        case "savings":
            return savings
        default:
            return BudgetDesignSystem.Colors.primary
        }
    }
    
    /// Returns light variant for transaction type
    static func lightColorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "income":
            return incomeLight
        case "expense":
            return expenseLight
        case "savings":
            return savingsLight
        default:
            return BudgetDesignSystem.Colors.primaryLight
        }
    }
    
    /// Returns category color by index
    static func categoryColor(index: Int) -> Color {
        return categoryColors[index % categoryColors.count]
    }
    
    /// Returns color for category type
    static func getCategoryTypeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "income":
            return income
        case "expense":
            return expense
        case "savings":
            return savings
        default:
            return primary
        }
    }
    
    /// Returns severity color for smart cards
    static func severityColor(for severity: String) -> Color {
        switch severity.lowercased() {
        case "high":
            return severityHigh
        case "medium":
            return severityMedium
        case "low":
            return severityLow
        case "info":
            return severityInfo
        default:
            return severityInfo
        }
    }
}

// MARK: - View Modifiers
extension View {
    /// Applies budget card styling
    func budgetCardStyle() -> some View {
        self
            .padding(BudgetDesignSystem.Spacing.cardPadding)
            .background(BudgetDesignSystem.Colors.surface)
            .cornerRadius(BudgetDesignSystem.CornerRadius.card)
            .shadow(color: BudgetDesignSystem.Shadow.card, 
                   radius: BudgetDesignSystem.Shadow.cardRadius, 
                   x: BudgetDesignSystem.Shadow.cardOffset.width, 
                   y: BudgetDesignSystem.Shadow.cardOffset.height)
    }
    
    /// Applies elevated card styling
    func elevatedCardStyle() -> some View {
        self
            .padding(BudgetDesignSystem.Spacing.cardPadding)
            .background(BudgetDesignSystem.Colors.surface)
            .cornerRadius(BudgetDesignSystem.CornerRadius.large)
            .shadow(color: BudgetDesignSystem.Shadow.elevated, 
                   radius: BudgetDesignSystem.Shadow.elevatedRadius, 
                   x: BudgetDesignSystem.Shadow.elevatedOffset.width, 
                   y: BudgetDesignSystem.Shadow.elevatedOffset.height)
    }
    
    /// Applies glassmorphism styling
    func glassCardStyle() -> some View {
        self
            .padding(BudgetDesignSystem.Spacing.cardPadding)
            .background(BudgetDesignSystem.Colors.glassBackground)
            .cornerRadius(BudgetDesignSystem.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: BudgetDesignSystem.CornerRadius.large)
                    .stroke(BudgetDesignSystem.Colors.glassBorder, lineWidth: 1)
            )
            .backdrop(blur: BudgetDesignSystem.Effects.cardBlur)
    }
    
    /// Applies budget button styling
    func budgetButtonStyle() -> some View {
        self
            .font(BudgetDesignSystem.Typography.bodyMedium)
            .padding(.horizontal, BudgetDesignSystem.Spacing.lg)
            .padding(.vertical, BudgetDesignSystem.Spacing.md)
            .background(BudgetDesignSystem.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BudgetDesignSystem.CornerRadius.button)
            .shadow(color: BudgetDesignSystem.Shadow.card, 
                   radius: BudgetDesignSystem.Shadow.cardRadius,
                   x: 0, y: 2)
    }
    
    /// Applies staggered entry animation
    func staggeredEntry(index: Int) -> some View {
        self
            .opacity(1)
            .animation(
                BudgetDesignSystem.Animation.fadeInUp
                    .delay(BudgetDesignSystem.Animation.staggerDelay(index: index))
            )
    }
    
    /// Applies backdrop blur effect for glassmorphism
    func backdrop(blur radius: Double) -> some View {
        self
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: radius)
            )
    }
    
    /// Applies press animation
    func pressAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(BudgetDesignSystem.Animation.spring, value: UUID())
    }
}