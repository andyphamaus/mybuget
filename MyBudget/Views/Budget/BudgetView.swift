import SwiftUI

// MARK: - Master Budget View with 3 Sub-Tabs

struct BudgetView: View {
    @EnvironmentObject var authService: LocalAuthenticationService

    var body: some View {
        BudgetViewInternal(authService: authService)
    }
}

struct BudgetViewInternal: View {
    @StateObject private var viewModel: BudgetViewModel
    @StateObject private var smartAnalyticsService = SmartAnalyticsService()

    @State private var showingBudgetEdit = false
    @State private var showingBudgetSelector = false
    @State private var showingAddTransaction = false
    @State private var showingAddPlannedAmount = false
    @State private var showingRecurringTransactions = false
    @State private var showingAlerts = false

    init(authService: LocalAuthenticationService) {
        _viewModel = StateObject(wrappedValue: BudgetViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section with Green Background
                VStack(spacing: 0) {
                    // Header
                    BudgetHeaderView(
                        budgetName: viewModel.currentBudgetName,
                        budgetIcon: viewModel.currentBudgetIcon,
                        budgetColor: viewModel.currentBudgetColor,
                        onHelpTapped: { 
                            OnboardingPreferences.resetOnboarding()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NotificationCenter.default.post(name: Notification.Name.showOnboardingTutorial, object: nil)
                            }
                        },
                        onBudgetTapped: { showingBudgetSelector = true },
                        onGearTapped: { showingBudgetEdit = true }
                    )
                    
                    // Budget Tab selector
                    BudgetTabSelector(selectedTab: $viewModel.selectedTab)
                }
                .background(ThemeColors.Budget.gradient)
                
                // Content Section
                Group {
                    VStack(spacing: 0) {
                        // Period Picker for all tabs
                        PeriodPickerView(viewModel: viewModel)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Tab Content - Using separate view files
                        switch viewModel.selectedTab {
                        case 0:
                            BudgetPlanView(viewModel: viewModel)
                        case 1:
                            BudgetRemainingView(viewModel: viewModel)
                        case 2:
                            BudgetAnalyticsView(viewModel: viewModel)
                                .environmentObject(smartAnalyticsService)
                        default:
                            BudgetEmptyStateView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(BudgetDesignSystem.Animation.smooth, value: viewModel.selectedTab)
            }
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        LoadingOverlay()
                    }
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.onboardingCompleted)) { _ in
            Task {
                // Add small delay to avoid race conditions
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Ensure system categories are created after onboarding
                let dataSeeder = BudgetDataSeeder()
                do {
                    if !dataSeeder.isSystemDataSeeded() {
                        print("🌱 Creating system categories after onboarding completion...")
                        try await dataSeeder.seedDefaultBudgetData()
                    }
                } catch {
                    print("❌ Failed to seed system categories after onboarding: \(error)")
                }
                
                await viewModel.refreshCurrentBudgetData()
            }
        }
        .sheet(isPresented: $showingAddPlannedAmount) {
            AddPlannedAmountSheet(
                viewModel: viewModel,
                section: nil
            )
        }
        .sheet(isPresented: $showingBudgetSelector) {
            BudgetSelectorSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingBudgetEdit) {
            BudgetEditSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(viewModel: viewModel)
        }
        .budgetOnboarding()
    }
    
}

#Preview {
    BudgetView()
        .environmentObject(LocalAuthenticationService())
}
