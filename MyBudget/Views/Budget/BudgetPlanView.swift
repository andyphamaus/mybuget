import SwiftUI

// MARK: - Budget Plan View (Tab 1: Planning)

struct BudgetPlanView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showingAddSection = false
    @State private var newSectionName = ""
    @State private var isCreatingSection = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Summary Card
                if let summary = viewModel.planningSummary {
                    PlanSummaryCard(summary: summary)
                        .padding(.horizontal)
                }
                
                // Sections
                if !viewModel.sections.isEmpty {
                    ForEach(viewModel.sections.sorted { $0.displayOrder < $1.displayOrder }, id: \.id) { section in
                        BudgetSectionView(
                            section: section,
                            viewModel: viewModel
                        )
                        .padding(.horizontal)
                    }
                    
                    // Add Section Inline
                    InlineAddSectionView(
                        showingAddSection: $showingAddSection,
                        newSectionName: $newSectionName,
                        isCreatingSection: $isCreatingSection,
                        viewModel: viewModel
                    )
                    .padding(.horizontal)
                    
                } else {
                    // Empty state - show add section to get started
                    VStack(spacing: 24) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        VStack(spacing: 12) {
                            Text("Create Your First Section")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Add sections like Income, Expenses, or Savings to organize your budget.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        
                        // Add Section Button
                        InlineAddSectionView(
                            showingAddSection: $showingAddSection,
                            newSectionName: $newSectionName,
                            isCreatingSection: $isCreatingSection,
                            viewModel: viewModel
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 40)
                }
                
                // Bottom padding for better scroll experience
                Spacer(minLength: 100)
            }
            .padding(.top, 10)
        }
        .sheet(isPresented: $showingAddSection) {
            AddSectionSheet(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.refreshCurrentBudgetData()
        }
    }
}

// MARK: - Plan Summary Card

struct PlanSummaryCard: View {
    let summary: PlanningSummary
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Summary stats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                VStack(spacing: 4) {
                    Text("$\(summary.totalPlannedIncome, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("$\(summary.totalPlannedExpense, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Expense")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("$\(summary.totalPlannedIncome - summary.totalPlannedExpense, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor((summary.totalPlannedIncome - summary.totalPlannedExpense) >= 0 ? .green : .red)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Plan Section

struct PlanSection: View {
    let section: LocalPeriodSection
    @ObservedObject var viewModel: BudgetViewModel
    
    private var sectionPlans: [LocalBudgetPeriodPlan] {
        viewModel.plansForSection(section)
    }
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(sectionPlans, id: \.id) { plan in
                PlanCard(plan: plan, viewModel: viewModel, section: section)
                    .draggable(plan.id ?? "")
            }
        }
        .dropDestination(for: String.self) { items, location in
            handleDrop(items: items, location: location)
        }
        
        // Drop area for empty section
        if sectionPlans.isEmpty {
            EmptyDropArea(section: section, viewModel: viewModel)
        }
    }
    
    private func handleDrop(items: [String], location: CGPoint) -> Bool {
        guard let draggedPlanId = items.first else { return false }
        
        // Find the dragged plan
        guard let draggedPlan = viewModel.plans.first(where: { $0.id == draggedPlanId }) else {
            return false
        }
        
        // Find which section the dragged plan currently belongs to
        let draggedPlanSection = viewModel.sections.first { section in
            viewModel.plansForSection(section).contains { $0.id == draggedPlan.id }
        }
        
        // If same section, handle reordering
        if draggedPlanSection?.id == section.id {
            // For now, just move to end of section
            // We can implement more precise positioning later
            Task {
                await viewModel.reorderPlansInSection(section, from: IndexSet([0]), to: sectionPlans.count)
            }
        } else {
            // Cross-section move
            Task {
                do {
                    try await viewModel.movePlan(draggedPlan, to: section, at: 0)
                } catch {
                    viewModel.errorMessage = "Failed to move plan: \(error.localizedDescription)"
                }
            }
        }
        
        return true
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: LocalBudgetPeriodPlan
    @ObservedObject var viewModel: BudgetViewModel
    let section: LocalPeriodSection
    @State private var showingEditPlan = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon and color
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: plan.category?.color) ?? .gray)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: plan.category?.icon ?? "circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Category info
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.category?.name ?? "Unknown Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .onTapGesture {
                            showingEditPlan = true
                        }
                    
                    if let notes = plan.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text("$\(plan.amountInCurrency, specifier: "%.0f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditPlan) {
            AddPlannedAmountSheet(
                viewModel: viewModel,
                section: section,
                prefilledCategory: plan.category,
                prefilledAmount: plan.amountInCurrency,
                prefilledNotes: plan.notes,
                prefilledType: plan.category?.headCategory?.preferType
            )
        }
    }
}


// MARK: - Empty Drop Area

struct EmptyDropArea: View {
    let section: LocalPeriodSection
    let viewModel: BudgetViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("No plans in this section yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .dropDestination(for: String.self) { items, location in
            guard let draggedPlanId = items.first else { return false }
            
            guard let draggedPlan = viewModel.plans.first(where: { $0.id == draggedPlanId }) else {
                return false
            }
            
            Task {
                do {
                    try await viewModel.movePlan(draggedPlan, to: section, at: 0)
                } catch {
                    viewModel.errorMessage = "Failed to move plan: \(error.localizedDescription)"
                }
            }
            
            return true
        }
    }
}

// MARK: - Budget Section View

struct BudgetSectionView: View {
    let section: LocalPeriodSection
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showingAddCategory = false
    @State private var showingEditName = false
    @State private var editingName = ""
    
    private var sectionPlans: [LocalBudgetPeriodPlan] {
        viewModel.plansForSection(section)
    }
    
    private var sectionTotal: Double {
        sectionPlans.reduce(0) { $0 + $1.amountInCurrency }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.name ?? "Unknown Section")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .contextMenu {
                            Button(action: {
                                editingName = section.name ?? ""
                                showingEditName = true
                            }) {
                                Label("Edit Name", systemImage: "pencil")
                            }
                        }
                    
                    Text("$\(sectionTotal, specifier: "%.0f") planned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add category button
                Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Section Content
            PlanSection(section: section, viewModel: viewModel)
                .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingAddCategory) {
            AddPlannedAmountSheet(
                viewModel: viewModel,
                section: section
            )
        }
        .sheet(isPresented: $showingEditName) {
            EditSectionNameSheet(
                sectionName: $editingName,
                onSave: { newName in
                    Task {
                        do {
                            try await viewModel.updateSection(section, name: newName)
                        } catch {
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Inline Add Section View

struct InlineAddSectionView: View {
    @Binding var showingAddSection: Bool
    @Binding var newSectionName: String
    @Binding var isCreatingSection: Bool
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "plus.circle.dashed")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("Add New Section")
                .font(.subheadline)
                .foregroundColor(.blue)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showingAddSection = true
        }
    }
}

// MARK: - Add Section Sheet

struct AddSectionSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var sectionName = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create New Section")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Organize your budget into sections like Income, Essentials, Lifestyle, etc.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Form
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Section Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("e.g., Transportation, Entertainment", text: $sectionName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .focused($isTextFieldFocused)
                    }
                }
                
                Spacer()
                
                // Create button
                Button(action: createSection) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                        }
                        
                        Text("Create Section")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            }
            .padding()
            .navigationTitle("New Section")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-focus the text field when sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func createSection() {
        guard !sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                let _ = try await viewModel.createSection(
                    name: sectionName.trimmingCharacters(in: .whitespacesAndNewlines),
                    typeHint: nil
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }
}


// MARK: - Edit Section Name Sheet

struct EditSectionNameSheet: View {
    @Binding var sectionName: String
    let onSave: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Section Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter section name", text: $sectionName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Section")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if !sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSave(sectionName.trimmingCharacters(in: .whitespacesAndNewlines))
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .font(.headline)
                .disabled(sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

#Preview {
    BudgetPlanView(viewModel: BudgetViewModel())
        .environmentObject(LocalAuthenticationService())
}