import SwiftUI

struct BudgetSectionEmptyState: View {
    let sectionType: String
    let onAddCategory: () -> Void
    let animateContent: Bool
    
    private var emptyStateConfig: (icon: String, title: String, subtitle: String, color: Color) {
        switch sectionType {
        case "income":
            return (
                icon: "plus.circle.fill",
                title: "Add Income Sources",
                subtitle: "Track your salary, freelance work, or other income streams",
                color: BudgetDesignSystem.Colors.income
            )
        case "savings":
            return (
                icon: "piggybank.fill", 
                title: "Set Savings Goals",
                subtitle: "Build your emergency fund and save for future goals",
                color: BudgetDesignSystem.Colors.savings
            )
        default:
            return (
                icon: "minus.circle.fill",
                title: "Add Expense Categories",
                subtitle: "Organize your spending into categories like food, transport, and entertainment",
                color: BudgetDesignSystem.Colors.expense
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Empty state illustration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(emptyStateConfig.color.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: emptyStateConfig.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(emptyStateConfig.color)
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
                
                VStack(spacing: 8) {
                    Text(emptyStateConfig.title)
                        .font(BudgetDesignSystem.Typography.title3)
                        .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(emptyStateConfig.subtitle)
                        .font(BudgetDesignSystem.Typography.body)
                        .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            }
            
            // Add category button
            Button(action: onAddCategory) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Add Category")
                        .font(BudgetDesignSystem.Typography.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(emptyStateConfig.color)
                .cornerRadius(8)
            }
            .scaleEffect(animateContent ? 1.0 : 0.9)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(BudgetDesignSystem.Colors.surfaceSecondary.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(emptyStateConfig.color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        BudgetSectionEmptyState(
            sectionType: "income",
            onAddCategory: {},
            animateContent: true
        )
        
        BudgetSectionEmptyState(
            sectionType: "expense", 
            onAddCategory: {},
            animateContent: true
        )
        
        BudgetSectionEmptyState(
            sectionType: "savings",
            onAddCategory: {},
            animateContent: true
        )
    }
    .padding()
    .background(BudgetDesignSystem.Colors.background)
}