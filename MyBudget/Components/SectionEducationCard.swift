import SwiftUI

struct SectionEducationCard: View {
    let isAnimated: Bool
    let animationDelay: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(BudgetDesignSystem.Colors.primary)
                
                Text("About Budget Sections")
                    .font(BudgetDesignSystem.Typography.headline)
                    .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Description
            Text("Your budget is organized into four main sections to help you track and manage different types of financial activities:")
                .font(BudgetDesignSystem.Typography.body)
                .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.leading)
            
            // Section details
            VStack(spacing: 12) {
                SectionDetailRow(
                    icon: "dollarsign.circle.fill",
                    title: "Income",
                    description: "All money coming in (salary, freelance, etc.)",
                    color: BudgetDesignSystem.Colors.income,
                    isAnimated: isAnimated,
                    animationDelay: animationDelay + 0.2
                )
                
                SectionDetailRow(
                    icon: "house.fill",
                    title: "Fixed Expenses",
                    description: "Regular monthly costs (rent, insurance, etc.)",
                    color: .orange,
                    isAnimated: isAnimated,
                    animationDelay: animationDelay + 0.4
                )
                
                SectionDetailRow(
                    icon: "cart.fill",
                    title: "Variable Expenses",
                    description: "Flexible spending (food, entertainment, etc.)",
                    color: .red,
                    isAnimated: isAnimated,
                    animationDelay: animationDelay + 0.6
                )
                
                SectionDetailRow(
                    icon: "banknote.fill",
                    title: "Savings",
                    description: "Money set aside for goals and emergencies",
                    color: .green,
                    isAnimated: isAnimated,
                    animationDelay: animationDelay + 0.8
                )
            }
            
            // Benefits highlight
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("Why sections help:")
                        .font(BudgetDesignSystem.Typography.body)
                        .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    BenefitRow(text: "Better organization and clarity", isAnimated: isAnimated, animationDelay: animationDelay + 1.0)
                    BenefitRow(text: "Easier to find and track categories", isAnimated: isAnimated, animationDelay: animationDelay + 1.2)
                    BenefitRow(text: "Clear overview of your financial structure", isAnimated: isAnimated, animationDelay: animationDelay + 1.4)
                }
            }
        }
        .padding(20)
        .background(BudgetDesignSystem.Colors.surfaceSecondary)
        .cornerRadius(16)
        .scaleEffect(isAnimated ? 1.0 : 0.95)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - Section Detail Row

private struct SectionDetailRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isAnimated: Bool
    let animationDelay: Double
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BudgetDesignSystem.Typography.body)
                    .foregroundColor(BudgetDesignSystem.Colors.textPrimary)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(BudgetDesignSystem.Typography.caption1)
                    .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(x: isAnimated ? 0 : -20)
        .animation(.easeOut(duration: 0.4).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let text: String
    let isAnimated: Bool
    let animationDelay: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(BudgetDesignSystem.Colors.primary)
                .frame(width: 4, height: 4)
            
            Text(text)
                .font(BudgetDesignSystem.Typography.caption1)
                .foregroundColor(BudgetDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(x: isAnimated ? 0 : -10)
        .animation(.easeOut(duration: 0.3).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - Preview

struct SectionEducationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SectionEducationCard(isAnimated: true, animationDelay: 0.0)
            Spacer()
        }
        .padding()
        .background(BudgetDesignSystem.Colors.background)
        .previewDisplayName("Section Education Card")
    }
}