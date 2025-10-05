import SwiftUI

// MARK: - Add Transaction Amount Sheet

struct AddTransactionAmountSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    var prefilledCategory: LocalCategory?
    
    @State private var selectedCategory: LocalCategory?
    @State private var amount: String = ""
    @State private var selectedType: String = "EXPENSE"
    @State private var transactionDate = Date()
    @State private var notes: String = ""
    @State private var isRecurring = false
    @State private var recurringFrequency = "MONTHLY"
    @State private var recurringEndDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCategoryPicker = false
    @FocusState private var isAmountFieldFocused: Bool
    
    private let recurringOptions = [
        ("DAILY", "Daily"),
        ("WEEKLY", "Weekly"), 
        ("MONTHLY", "Monthly"),
        ("QUARTERLY", "Quarterly"),
        ("YEARLY", "Yearly")
    ]
    
    private var availableCategories: [LocalCategory] {
        // Show all categories regardless of type - user can choose any category with any type
        return viewModel.incomeCategories + viewModel.expenseCategories
    }
    
    private var groupedCategories: [LocalHeadCategory: [LocalCategory]] {
        let categories = availableCategories
        let validCategories = categories.compactMap { category -> (LocalHeadCategory, LocalCategory)? in
            guard let headCategory = category.headCategory else { return nil }
            return (headCategory, category)
        }
        return Dictionary(grouping: validCategories) { $0.0 }
            .mapValues { $0.map { $0.1 } }
    }
    
    private var isValidInput: Bool {
        guard let category = selectedCategory, !amount.isEmpty else { return false }
        guard let amountDouble = Double(amount), amountDouble > 0, amountDouble <= 1_000_000 else { return false }
        // Validate notes length if provided
        if !notes.isEmpty && notes.count > 200 {
            return false
        }
        return true
    }
    
    private var validationMessage: String {
        if selectedCategory == nil {
            return "Please select a category"
        }
        if amount.isEmpty {
            return "Please enter an amount"
        }
        if Double(amount) == nil {
            return "Please enter a valid number"
        }
        if let amountDouble = Double(amount), amountDouble <= 0 {
            return "Amount must be greater than 0"
        }
        if let amountDouble = Double(amount), amountDouble > 1_000_000 {
            return "Amount cannot exceed $1,000,000"
        }
        if !notes.isEmpty && notes.count > 200 {
            return "Notes cannot exceed 200 characters"
        }
        return ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Amount at top - big, no label, centered
                VStack(spacing: 8) {
                    TextField("0", text: $amount)
                        .font(.system(size: 48, weight: .light))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                Form {
                    // Type section
                    Section {
                        Picker("Type", selection: $selectedType) {
                            Text("Income").tag("INCOME")
                            Text("Expense").tag("EXPENSE")
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Type")
                    }
                    
                    // Category section
                    Section {
                        Button(action: {
                            let incomeCount = viewModel.incomeCategories.count
                            let expenseCount = viewModel.expenseCategories.count
                            showingCategoryPicker = true
                        }) {
                            HStack {
                                if let category = selectedCategory {
                                    Image(systemName: category.icon ?? "circle.fill")
                                        .foregroundColor(Color(hex: category.color) ?? .gray)
                                        .frame(width: 30)
                                    
                                    Text(category.name ?? "Unknown")
                                        .foregroundColor(.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                        .frame(width: 30)
                                    
                                    Text("Select Category")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("Category")
                    }
                    
                    // Date section
                    Section {
                        DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                    } header: {
                        Text("Date")
                    }
                    
                    // Recurring Options section
                    Section {
                        Toggle("Make Recurring", isOn: $isRecurring)
                        
                        if isRecurring {
                            Picker("Frequency", selection: $recurringFrequency) {
                                ForEach(recurringOptions, id: \.0) { option in
                                    Text(option.1).tag(option.0)
                                }
                            }
                            
                            DatePicker("End Date", selection: $recurringEndDate, displayedComponents: .date)
                        }
                    } header: {
                        Text("Recurring Options")
                    }
                    
                    // Notes section
                    Section {
                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes (Optional)")
                    }
                    
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        await saveTransaction()
                    }
                }
                .disabled(!isValidInput || isLoading)
            )
        }
        .onAppear {
            // Apply prefilled data if provided
            if let prefilledCategory = prefilledCategory {
                // Set the type FIRST based on the category's head category
                selectedType = prefilledCategory.headCategory?.preferType ?? "EXPENSE"
                // Then set the category
                selectedCategory = prefilledCategory
            } else {
                // Focus amount field and pre-select first category if not prefilled
                if selectedCategory == nil && !availableCategories.isEmpty {
                    selectedCategory = availableCategories.first
                }
            }
            
            isAmountFieldFocused = true
        }
        .onChange(of: selectedType) { newType in
            // No need to reset category when type changes since we show all categories
        }
        .sheet(isPresented: $showingCategoryPicker) {
            TransactionCategoryPickerView(
                categories: groupedCategories,
                selectedCategory: $selectedCategory,
                isPresented: $showingCategoryPicker
            )
        }
    }
    
    private func saveTransaction() async {
        guard let category = selectedCategory,
              let amountDouble = Double(amount), amountDouble > 0 else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let categoryId = category.id else {
                errorMessage = "Invalid category selected"
                isLoading = false
                return
            }
            
            if isRecurring {
                // For now, create multiple single transactions for recurring
                let calendar = Calendar.current
                var currentDate = transactionDate
                
                while currentDate <= recurringEndDate {
                    try await viewModel.addTransaction(
                        categoryId: categoryId,
                        type: selectedType, 
                        amount: amountDouble,
                        date: currentDate,
                        notes: notes.isEmpty ? nil : notes
                    )
                    
                    // Calculate next date based on frequency
                    switch recurringFrequency {
                    case "DAILY":
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    case "WEEKLY":
                        currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
                    case "MONTHLY":
                        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    case "QUARTERLY":
                        currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate) ?? currentDate
                    case "YEARLY":
                        currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
                    default:
                        break
                    }
                    
                    // Safety check to prevent infinite loop
                    guard let dateInterval = calendar.dateInterval(of: .year, for: currentDate) else {
                        break
                    }
                    if dateInterval.start.timeIntervalSince(transactionDate) > 3 * 365 * 24 * 60 * 60 {
                        break
                    }
                }
            } else {
                // Create single transaction
                try await viewModel.addTransaction(
                    categoryId: categoryId,
                    type: selectedType, 
                    amount: amountDouble,
                    date: transactionDate,
                    notes: notes.isEmpty ? nil : notes
                )
            }
            
            dismiss()
        } catch {
            errorMessage = "Failed to save transaction: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct TransactionCategoryPickerView: View {
    let categories: [LocalHeadCategory: [LocalCategory]]
    @Binding var selectedCategory: LocalCategory?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(categories.keys).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.self) { headCategory in
                        VStack(alignment: .leading, spacing: 12) {
                            // Head category header
                            HStack {
                                Text(headCategory.name ?? "Unknown")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Category icons grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                                ForEach(categories[headCategory] ?? [], id: \.id) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        isPresented = false
                                    }) {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: category.color) ?? .gray)
                                                    .frame(width: 50, height: 50)
                                                    .opacity(selectedCategory?.id == category.id ? 1.0 : 0.3)
                                                
                                                Image(systemName: category.icon ?? "circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                                
                                                if selectedCategory?.id == category.id {
                                                    Circle()
                                                        .stroke(Color.blue, lineWidth: 3)
                                                        .frame(width: 50, height: 50)
                                                }
                                            }
                                            
                                            Text(category.name ?? "Unknown")
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
    }
}

#Preview {
    AddTransactionAmountSheet(viewModel: BudgetViewModel())
        .environmentObject(LocalAuthenticationService())
}