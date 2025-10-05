import Foundation

// Temporary step model for editing tasks
struct TempTaskStep: Identifiable, Equatable {
    let id: UUID
    var stepName: String
    var isCompleted: Bool
    var order: Int16

    init(stepName: String, order: Int16, isCompleted: Bool = false) {
        self.id = UUID()
        self.stepName = stepName
        self.order = order
        self.isCompleted = isCompleted
    }

    // Create from existing LocalTaskStep
    init(from localStep: LocalTaskStep) {
        self.id = UUID()
        self.stepName = localStep.stepName ?? ""
        self.order = localStep.order
        self.isCompleted = localStep.isCompleted
    }
}