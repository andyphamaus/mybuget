import SwiftUI

struct BudgetHeaderView: View {
    let budgetName: String
    let budgetIcon: String
    let budgetColor: Color
    let onHelpTapped: () -> Void
    let onBudgetTapped: () -> Void
    let onGearTapped: () -> Void
    
    var body: some View {
        HStack {
            // Gear icon on left
            Button(action: onGearTapped) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Budget icon and name in center
            Button(action: onBudgetTapped) {
                HStack(spacing: 8) {
                    // Check if budgetIcon is an SF Symbol name (contains "." or starts with common SF symbol prefixes)
                    if budgetIcon.contains(".") || 
                       budgetIcon.hasPrefix("star") || 
                       budgetIcon.hasPrefix("heart") || 
                       budgetIcon.hasPrefix("circle") ||
                       budgetIcon.hasPrefix("square") ||
                       budgetIcon.hasPrefix("dollar") {
                        Image(systemName: budgetIcon)
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        // It's an emoji or other text
                        Text(budgetIcon)
                            .font(.title2)
                    }
                    
                    Text(budgetName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Help icon on right
            Button(action: onHelpTapped) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct BudgetTabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["Plan", "Remaining", "Analytics"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tabs[index])
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == index ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index ? 
                            Color.white.opacity(0.2) : 
                            Color.clear
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.clear)
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}