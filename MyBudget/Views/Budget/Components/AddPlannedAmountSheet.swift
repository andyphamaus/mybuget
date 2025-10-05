import SwiftUI

struct AddPlannedAmountSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) var dismiss
    let section: LocalPeriodSection?
    
    // Optional prefill parameters
    let prefilledCategory: LocalCategory?
    let prefilledAmount: Double?
    let prefilledNotes: String?
    let prefilledType: String?
    
    @State private var selectedCategory: LocalCategory?
    @State private var amount: String = ""
    @State private var notes: String = ""
    @State private var selectedType: String = "EXPENSE"
    @State private var showingCategoryPicker = false
    @FocusState private var isAmountFieldFocused: Bool
    
    // Initialize with prefill data
    init(viewModel: BudgetViewModel, 
         section: LocalPeriodSection? = nil,
         prefilledCategory: LocalCategory? = nil,
         prefilledAmount: Double? = nil,
         prefilledNotes: String? = nil,
         prefilledType: String? = nil) {
        self.viewModel = viewModel
        self.section = section
        self.prefilledCategory = prefilledCategory
        self.prefilledAmount = prefilledAmount
        self.prefilledNotes = prefilledNotes
        self.prefilledType = prefilledType
    }
    
    private var availableCategories: [LocalCategory] {
        return selectedType == "INCOME" ? viewModel.incomeCategories : viewModel.expenseCategories
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
                    
                    // Notes section
                    Section {
                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes (Optional)")
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Planned Amount")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveAmount()
                }
                .disabled(!isValidInput)
            )
        }
        .onAppear {
            // Apply prefilled data if provided
            if let prefilledCategory = prefilledCategory {
                selectedCategory = prefilledCategory
            }
            if let prefilledAmount = prefilledAmount {
                amount = String(format: "%.0f", prefilledAmount)
            }
            if let prefilledNotes = prefilledNotes {
                notes = prefilledNotes
            }
            if let prefilledType = prefilledType {
                selectedType = prefilledType
            }
            
            // Focus amount field and pre-select first category if not prefilled
            isAmountFieldFocused = true
            if selectedCategory == nil && !availableCategories.isEmpty {
                selectedCategory = availableCategories.first
            }
        }
        .onChange(of: selectedType) { _ in
            // Reset selected category when type changes
            selectedCategory = nil
            // Pre-select first available category for new type
            if !availableCategories.isEmpty {
                selectedCategory = availableCategories.first
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                categories: groupedCategories,
                selectedCategory: $selectedCategory,
                isPresented: $showingCategoryPicker
            )
        }
    }
    
    private func saveAmount() {
        guard let category = selectedCategory,
              let categoryId = category.id,
              let amountValue = Double(amount),
              amountValue > 0 else {
            return
        }
        
        Task {
            do {
                if let section = section {
                    // Add plan to specific section
                    try await viewModel.addOrUpdatePlanForSection(
                        section,
                        categoryId: categoryId,
                        type: selectedType,
                        amount: amountValue,
                        notes: notes.isEmpty ? nil : notes
                    )
                } else {
                    // General plan addition (not section-specific)
                    try await viewModel.addOrUpdatePlan(
                        categoryId: categoryId,
                        type: selectedType,
                        amount: amountValue,
                        notes: notes.isEmpty ? nil : notes
                    )
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                viewModel.errorMessage = "Failed to save plan: \(error.localizedDescription)"
            }
        }
    }
}

struct CategoryPickerView: View {
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

struct AddTransactionSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: LocalCategory?
    @State private var amount: String = ""
    @State private var notes: String = ""
    @State private var selectedType: String = "EXPENSE"
    @State private var selectedDate: Date = Date()
    
    private var availableCategories: [LocalCategory] {
        return selectedType == "INCOME" ? viewModel.incomeCategories : viewModel.expenseCategories
    }
    
    private var isValidInput: Bool {
        guard let category = selectedCategory, !amount.isEmpty else { return false }
        guard let amountDouble = Double(amount), amountDouble > 0, amountDouble <= 1_000_000 else { return false }
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
        return ""
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("Income").tag("INCOME")
                        Text("Expense").tag("EXPENSE")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    if availableCategories.isEmpty {
                        Text("No categories available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableCategories, id: \.id) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack {
                                    Image(systemName: category.icon ?? "circle.fill")
                                        .foregroundColor(Color(hex: category.color) ?? .gray)
                                        .frame(width: 30)
                                    
                                    Text(category.name ?? "Unknown")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Date") {
                    DatePicker("Transaction Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let category = selectedCategory {
                    Section("Selected Category") {
                        HStack {
                            Image(systemName: category.icon ?? "circle.fill")
                                .foregroundColor(Color(hex: category.color) ?? .gray)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(category.name ?? "Unknown")
                                    .font(.headline)
                                
                                Text(category.headCategory?.name ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveTransaction()
                }
                .disabled(!isValidInput)
            )
        }
        .onAppear {
            // Pre-select the first available category
            if selectedCategory == nil && !availableCategories.isEmpty {
                selectedCategory = availableCategories.first
            }
        }
    }
    
    private func saveTransaction() {
        guard let category = selectedCategory,
              let categoryId = category.id,
              let amountValue = Double(amount),
              amountValue > 0 else {
            return
        }
        
        Task {
            do {
                try await viewModel.addTransaction(
                    categoryId: categoryId,
                    type: selectedType,
                    amount: amountValue,
                    date: selectedDate,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                viewModel.errorMessage = "Failed to save transaction: \(error.localizedDescription)"
            }
        }
    }
}

#Preview("Add Planned Amount") {
    AddPlannedAmountSheet(viewModel: BudgetViewModel(), section: nil)
}

#Preview("Add Transaction") {
    AddTransactionSheet(viewModel: BudgetViewModel())
}