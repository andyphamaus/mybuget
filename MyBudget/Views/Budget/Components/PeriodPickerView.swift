import SwiftUI

struct PeriodPickerView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showingCopyAlert = false
    
    // Check if we can navigate to previous (older) periods
    private var canNavigatePrevious: Bool {
        guard let current = viewModel.currentPeriod,
              let currentIndex = viewModel.allPeriods.firstIndex(where: { $0.id == current.id }) else {
            return false
        }
        // Can go to previous if we're not at the last index (oldest period)
        return currentIndex < viewModel.allPeriods.count - 1
    }
    
    // Next period can always be created or navigated to
    private var canNavigateNext: Bool {
        return viewModel.currentPeriod != nil
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Previous period button (older periods)
            if canNavigatePrevious {
                Button(action: {
                    Task {
                        await viewModel.navigateToPreviousPeriod()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            } else {
                // Empty space when button is hidden
                Color.clear
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            // Current period display
            Text(viewModel.currentPeriodName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Next period button (newer periods or create new)
            Button(action: {
                Task {
                    await viewModel.navigateToNextPeriod()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canNavigateNext ? .primary : .gray)
            }
            .disabled(!canNavigateNext)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            // Loading overlay during copy process
            Group {
                if viewModel.isCopyingPlans {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                                Text("Copying Budget Plans...")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
        )
        .alert("Copy Budget Plans?", isPresented: $viewModel.showCopyPlansAlert) {
            Button("Copy Plans", role: .none) {
                Task {
                    await viewModel.copyPlansFromPreviousPeriod()
                }
            }
            Button("Start Fresh", role: .cancel) {
                viewModel.periodToCopyFrom = nil
            }
        } message: {
            Text("Would you like to copy the planned budget from the previous period? This will only copy the planned amounts, not the actual transactions.")
        }
    }
}

#Preview {
    PeriodPickerView(viewModel: BudgetViewModel())
        .padding()
}