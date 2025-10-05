import Foundation
import CoreData
import Combine

@MainActor
class LocalTaskService: ObservableObject {
    @Published var tasks: [LocalTask] = []
    @Published var completedTasks: [LocalTask] = []
    @Published var favoriteTasks: [LocalTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadTasks()
    }

    // MARK: - Data Loading

    func loadTasks() {
        isLoading = true
        errorMessage = nil

        let context = persistenceController.viewContext

        // Load all tasks
        let allTasksRequest: NSFetchRequest<LocalTask> = LocalTask.fetchRequest()
        allTasksRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalTask.createdDate, ascending: false)
        ]

        // Load completed tasks
        let completedTasksRequest: NSFetchRequest<LocalTask> = LocalTask.fetchRequest()
        completedTasksRequest.predicate = NSPredicate(format: "isCompleted == YES")
        completedTasksRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalTask.completedDate, ascending: false)
        ]

        // Load favorite tasks
        let favoriteTasksRequest: NSFetchRequest<LocalTask> = LocalTask.fetchRequest()
        favoriteTasksRequest.predicate = NSPredicate(format: "isFavorite == YES AND isCompleted == NO")
        favoriteTasksRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalTask.createdDate, ascending: false)
        ]

        do {
            let allTasks = try context.fetch(allTasksRequest)
            let completed = try context.fetch(completedTasksRequest)
            let favorites = try context.fetch(favoriteTasksRequest)

            DispatchQueue.main.async { [weak self] in
                self?.tasks = allTasks
                self?.completedTasks = completed
                self?.favoriteTasks = favorites
                self?.isLoading = false
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                self?.isLoading = false
            }
        }
    }

    // MARK: - CRUD Operations

    func createTask(
        title: String,
        detail: String? = nil,
        category: String? = nil,
        priority: Int16 = 1,
        dueDate: Date? = nil,
        remindMeOn: Date? = nil,
        notes: String? = nil,
        steps: [TempTaskStep] = [],
        attachments: [TempTaskAttachment] = []
    ) {
        let context = persistenceController.viewContext

        let task = LocalTask(context: context)
        task.id = UUID()
        task.title = title
        task.detail = detail
        task.category = category
        task.priority = priority
        task.dueDate = dueDate
        task.remindMeOn = remindMeOn
        task.notes = notes
        task.isCompleted = false
        task.isFavorite = false
        task.pointEarned = 0
        task.sourceType = "local"
        task.createdDate = Date()
        task.modifiedDate = Date()

        // Add steps
        for tempStep in steps {
            let step = LocalTaskStep(context: context)
            step.id = UUID()
            step.stepName = tempStep.stepName
            step.isCompleted = tempStep.isCompleted
            step.order = tempStep.order
            step.task = task
        }

        // Add attachments
        for tempAttachment in attachments {
            let attachment = LocalTaskAttachment(context: context)
            attachment.id = UUID()
            attachment.fileName = tempAttachment.fileName
            attachment.mimeType = tempAttachment.mimeType
            attachment.size = tempAttachment.size
            attachment.fileData = tempAttachment.fileData
            attachment.createdDate = Date()
            attachment.task = task
        }

        do {
            try context.save()

            // Log activity
            LocalActivity.logTaskActivity(
                context: context,
                action: "created",
                taskTitle: title,
                description: "New task created"
            )

            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
    }

    func updateTask(
        _ task: LocalTask,
        title: String,
        detail: String?,
        category: String?,
        priority: Int16,
        dueDate: Date?,
        remindMeOn: Date?,
        notes: String?
    ) {
        let context = persistenceController.viewContext

        // Always update all fields (including setting dates to nil)
        task.title = title
        task.detail = detail
        task.category = category
        task.priority = priority
        task.dueDate = dueDate
        task.remindMeOn = remindMeOn
        task.notes = notes

        task.modifiedDate = Date()

        do {
            try context.save()

            // Log activity
            LocalActivity.logTaskActivity(
                context: context,
                action: "updated",
                taskTitle: title,
                description: "Task updated"
            )

            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }

    func deleteTask(_ task: LocalTask) {
        let context = persistenceController.viewContext
        context.delete(task)

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    func toggleTaskCompletion(_ task: LocalTask) {
        let context = persistenceController.viewContext

        if task.isCompleted {
            task.markAsIncomplete()
        } else {
            task.markAsCompleted()

            // Send notification for task completion celebration
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskCompleted"),
                object: nil,
                userInfo: [
                    "task": task,
                    "pointsEarned": task.pointEarned
                ]
            )
        }

        do {
            try context.save()

            // Log activity
            let action = task.isCompleted ? "completed" : "reopened"
            let description = task.isCompleted ? "Task completed" : "Task reopened"
            LocalActivity.logTaskActivity(
                context: context,
                action: action,
                taskTitle: task.title ?? "",
                description: description
            )

            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to toggle task completion: \(error.localizedDescription)"
        }
    }

    func toggleTaskFavorite(_ task: LocalTask) {
        task.isFavorite.toggle()
        task.modifiedDate = Date()

        let context = persistenceController.viewContext

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to toggle task favorite: \(error.localizedDescription)"
        }
    }

    // MARK: - Task Steps Management

    func addStep(to task: LocalTask, stepName: String) {
        task.addStep(name: stepName)

        let context = persistenceController.viewContext

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to add step: \(error.localizedDescription)"
        }
    }

    func removeStep(_ step: LocalTaskStep, from task: LocalTask) {
        task.removeStep(step)

        let context = persistenceController.viewContext

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to remove step: \(error.localizedDescription)"
        }
    }

    func toggleStepCompletion(_ step: LocalTaskStep) {
        step.toggleCompletion()

        let context = persistenceController.viewContext

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to toggle step completion: \(error.localizedDescription)"
        }
    }

    // MARK: - Filtering & Search

    func getTasksByCategory(_ category: String) -> [LocalTask] {
        return tasks.filter { $0.category == category }
    }

    func getTasksByPriority(_ priority: Int16) -> [LocalTask] {
        return tasks.filter { $0.priority == priority }
    }

    func getPendingTasks() -> [LocalTask] {
        return tasks.filter { !$0.isCompleted }
    }

    func getOverdueTasks() -> [LocalTask] {
        let now = Date()
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return !task.isCompleted && dueDate < now
            }
            return false
        }
    }

    func getTasksDueToday() -> [LocalTask] {
        let calendar = Calendar.current
        let today = Date()

        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return !task.isCompleted && calendar.isDate(dueDate, inSameDayAs: today)
            }
            return false
        }
    }

    func getTasksDueThisWeek() -> [LocalTask] {
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .weekOfYear, value: 1, to: today) ?? today

        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return !task.isCompleted && dueDate >= today && dueDate <= weekFromNow
            }
            return false
        }
    }

    func searchTasks(_ searchText: String) -> [LocalTask] {
        if searchText.isEmpty {
            return tasks
        }

        return tasks.filter { task in
            let titleMatch = task.title?.localizedCaseInsensitiveContains(searchText) ?? false
            let detailMatch = task.detail?.localizedCaseInsensitiveContains(searchText) ?? false
            let notesMatch = task.notes?.localizedCaseInsensitiveContains(searchText) ?? false
            let categoryMatch = task.category?.localizedCaseInsensitiveContains(searchText) ?? false

            return titleMatch || detailMatch || notesMatch || categoryMatch
        }
    }

    // MARK: - Statistics

    func getTotalTasksCount() -> Int {
        return tasks.count
    }

    func getCompletedTasksCount() -> Int {
        return completedTasks.count
    }

    func getPendingTasksCount() -> Int {
        return getPendingTasks().count
    }

    func getOverdueTasksCount() -> Int {
        return getOverdueTasks().count
    }

    func getTotalPointsEarned() -> Int32 {
        return completedTasks.reduce(0) { $0 + $1.pointEarned }
    }

    func getCompletionRate() -> Double {
        let total = getTotalTasksCount()
        guard total > 0 else { return 0.0 }

        let completed = getCompletedTasksCount()
        return Double(completed) / Double(total)
    }

    // MARK: - Categories

    func getAllCategories() -> [String] {
        let categories = tasks.compactMap { $0.category }
        return Array(Set(categories)).sorted()
    }

    func getTasksCountByCategory() -> [String: Int] {
        var categoryCount: [String: Int] = [:]

        for task in tasks {
            let category = task.category ?? "Uncategorized"
            categoryCount[category] = (categoryCount[category] ?? 0) + 1
        }

        return categoryCount
    }

    // MARK: - Bulk Operations

    func markAllTasksAsCompleted(in category: String? = nil) {
        let tasksToComplete: [LocalTask]

        if let category = category {
            tasksToComplete = getPendingTasks().filter { $0.category == category }
        } else {
            tasksToComplete = getPendingTasks()
        }

        let context = persistenceController.viewContext

        for task in tasksToComplete {
            task.markAsCompleted()
        }

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to mark tasks as completed: \(error.localizedDescription)"
        }
    }

    func deleteAllCompletedTasks() {
        let context = persistenceController.viewContext

        for task in completedTasks {
            context.delete(task)
        }

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to delete completed tasks: \(error.localizedDescription)"
        }
    }

    // MARK: - Attachment Management

    func addAttachment(to task: LocalTask, attachment: TempTaskAttachment) {
        // Check max 3 files limit
        let currentAttachments = task.attachments?.allObjects as? [LocalTaskAttachment] ?? []
        guard currentAttachments.count < 3 else {
            errorMessage = "Maximum 3 attachments allowed per task"
            return
        }

        let context = persistenceController.viewContext

        let localAttachment = LocalTaskAttachment(context: context)
        localAttachment.id = UUID()
        localAttachment.fileName = attachment.fileName
        localAttachment.mimeType = attachment.mimeType
        localAttachment.size = attachment.size
        localAttachment.fileData = attachment.fileData
        localAttachment.createdDate = Date()
        localAttachment.task = task

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to add attachment: \(error.localizedDescription)"
        }
    }

    func removeAttachment(_ attachment: LocalTaskAttachment) {
        let context = persistenceController.viewContext
        context.delete(attachment)

        do {
            try context.save()
            loadTasks() // Refresh the tasks list
        } catch {
            errorMessage = "Failed to remove attachment: \(error.localizedDescription)"
        }
    }

    func getAttachmentData(for attachment: LocalTaskAttachment) -> Data? {
        return attachment.fileData
    }
}