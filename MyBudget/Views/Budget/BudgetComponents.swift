import SwiftUI

// Shared components used across multiple Budget views

struct BudgetMonthNavigation: View {
    @Binding var currentDate: Date
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    var body: some View {
        HStack {
            Button(action: {
                // Go to previous month
                if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                    withAnimation(BudgetDesignSystem.Animation.smooth) {
                        currentDate = newDate
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(BudgetDesignSystem.Typography.headline)
                    .foregroundColor(BudgetDesignSystem.Colors.primary)
                    .padding(BudgetDesignSystem.Spacing.sm)
                    .background(
                        Circle()
                            .fill(BudgetDesignSystem.Colors.primary.opacity(0.1))
                    )
            }
            .scaleEffect(1.0)
            .animation(BudgetDesignSystem.Animation.spring, value: currentDate)
            
            Spacer()
            
            Text(monthYearFormatter.string(from: currentDate))
                .font(BudgetDesignSystem.Typography.title2)
                .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                .padding(.horizontal, BudgetDesignSystem.Spacing.md)
                .padding(.vertical, BudgetDesignSystem.Spacing.xs)
                .background(
                    Capsule()
                        .fill(BudgetDesignSystem.Colors.primary.opacity(0.05))
                )
                .animation(BudgetDesignSystem.Animation.smooth, value: currentDate)
            
            Spacer()
            
            Button(action: {
                // Go to next month
                if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                    withAnimation(BudgetDesignSystem.Animation.smooth) {
                        currentDate = newDate
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(BudgetDesignSystem.Typography.headline)
                    .foregroundColor(BudgetDesignSystem.Colors.primary)
                    .padding(BudgetDesignSystem.Spacing.sm)
                    .background(
                        Circle()
                            .fill(BudgetDesignSystem.Colors.primary.opacity(0.1))
                    )
            }
            .scaleEffect(1.0)
            .animation(BudgetDesignSystem.Animation.spring, value: currentDate)
        }
        .padding(.horizontal, BudgetDesignSystem.Spacing.xxl)
        .padding(.vertical, BudgetDesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BudgetDesignSystem.CornerRadius.large)
                .fill(BudgetDesignSystem.Colors.surface)
                .shadow(
                    color: BudgetDesignSystem.Shadow.card,
                    radius: BudgetDesignSystem.Shadow.cardRadius,
                    x: BudgetDesignSystem.Shadow.cardOffset.width,
                    y: BudgetDesignSystem.Shadow.cardOffset.height
                )
        )
    }
}

// Helper extensions for adaptive colors
extension Color {
    func isLightColor() -> Bool {
        let uiColor = UIColor(self)
        var white: CGFloat = 0
        uiColor.getWhite(&white, alpha: nil)
        return white > 0.5
    }
    
    var adaptiveTextColor: Color {
        return self.isLightColor() ? .black : .white
    }
    
    static var randomBrightColor: Color {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.7, blue: 1.0),    // Bright blue
            Color(red: 0.0, green: 0.8, blue: 0.4),    // Bright green
            Color(red: 1.0, green: 0.3, blue: 0.3),    // Bright red
            Color(red: 1.0, green: 0.6, blue: 0.0),    // Bright orange
            Color(red: 0.8, green: 0.0, blue: 0.8),    // Bright purple
            Color(red: 0.0, green: 0.7, blue: 0.7),    // Bright teal
            Color(red: 1.0, green: 0.8, blue: 0.0),    // Bright yellow
            Color(red: 0.9, green: 0.1, blue: 0.5)     // Bright pink
        ]
        return colors.randomElement() ?? .blue
    }
}