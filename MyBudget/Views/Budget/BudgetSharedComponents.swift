import SwiftUI

// MARK: - Shared Components Used Across Budget Views

// MARK: - Budget Empty State View

struct BudgetEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("No Budget Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create your first budget to start tracking your finances.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Loading Budget...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Missing Sheet Components (Placeholders)

struct BudgetSelectorSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Budget Selector")
                    .font(.title2)
                    .padding()
                
                Text("Select a budget from your available budgets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Select Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BudgetEditSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var budgetName: String = ""
    @State private var selectedIcon: String = ""
    @State private var selectedColor: String = ""
    @State private var selectedCurrency: String = ""
    @State private var isLoading: Bool = false
    
    private let budgetIcons = ["💰", "🏦", "💳", "🏠", "🎯", "📊", "💼", "🌟", "💎", "🔥", "⚡", "🚀"]
    private let budgetColors = ["#4CAF50", "#2196F3", "#9C27B0", "#FF5722", "#795548", "#607D8B", "#E91E63", "#FF9800", "#8BC34A", "#3F51B5", "#009688", "#F44336"]
    private let currencies = ["USD", "EUR", "VND", "GBP", "JPY", "AUD", "CAD", "CHF", "CNY", "SGD"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Budget Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter budget name", text: $budgetName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Icon Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Icon")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(budgetIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Text(icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedIcon == icon ? 
                                            Color.blue.opacity(0.2) : 
                                            Color.gray.opacity(0.1)
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    selectedIcon == icon ? Color.blue : Color.clear, 
                                                    lineWidth: 2
                                                )
                                        )
                                }
                            }
                        }
                    }
                    
                    
                    // Currency Selection Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currency")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Save Button
                    Button(action: {
                        saveBudgetChanges()
                    }) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Saving...")
                                    .fontWeight(.semibold)
                            }
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!canSave || isLoading)
                }
                .padding(20)
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentBudgetData()
            }
        }
    }
    
    private var canSave: Bool {
        !budgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedIcon.isEmpty &&
        !selectedCurrency.isEmpty
    }
    
    private func loadCurrentBudgetData() {
        guard let budget = viewModel.currentBudget else { return }
        budgetName = budget.name ?? ""
        selectedIcon = budget.icon ?? budgetIcons.first ?? "💰"
        selectedCurrency = budget.currencyCode ?? "USD"
        // Keep existing color, don't allow editing
        selectedColor = budget.color ?? budgetColors.first ?? "#4CAF50"
    }
    
    private func saveBudgetChanges() {
        guard let budget = viewModel.currentBudget, canSave else { return }
        
        isLoading = true
        
        Task {
            do {
                try await viewModel.updateBudget(
                    name: budgetName.trimmingCharacters(in: .whitespacesAndNewlines),
                    icon: selectedIcon,
                    color: selectedColor,
                    currencyCode: selectedCurrency
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Could add error handling here
                }
            }
        }
    }
}



#Preview {
    VStack(spacing: 20) {
        BudgetEmptyStateView()
        
        LoadingOverlay()
            .frame(height: 100)
    }
}