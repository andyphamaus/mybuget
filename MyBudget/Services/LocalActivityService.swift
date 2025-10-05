import Foundation
import CoreData
import Combine

@MainActor
class LocalActivityService: ObservableObject {
    @Published var activities: [LocalActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let persistenceController = PersistenceController.shared

    init() {
        loadActivities()
    }

    func loadActivities() {
        isLoading = true
        errorMessage = nil

        let context = persistenceController.viewContext
        let request: NSFetchRequest<LocalActivity> = LocalActivity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \LocalActivity.timestamp, ascending: false)
        ]
        request.fetchLimit = 50 // Limit to 50 most recent activities

        do {
            let fetchedActivities = try context.fetch(request)
            self.activities = fetchedActivities
            isLoading = false
        } catch {
            self.errorMessage = "Failed to load activities: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func refreshActivities() async {
        await Task { @MainActor in
            loadActivities()
        }.value
    }

    func deleteActivity(_ activity: LocalActivity) {
        let context = persistenceController.viewContext
        context.delete(activity)

        do {
            try context.save()
            loadActivities()
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }

    func clearAllActivities() {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = LocalActivity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            try context.save()
            loadActivities()
        } catch {
            errorMessage = "Failed to clear activities: \(error.localizedDescription)"
        }
    }

    func getActivitiesGroupedByDate() -> [Date: [LocalActivity]] {
        let calendar = Calendar.current
        return Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.timestamp ?? Date())
        }
    }

    func getActivitiesByModule(_ module: String) -> [LocalActivity] {
        return activities.filter { $0.module == module }
    }

    func getRecentActivities(limit: Int = 10) -> [LocalActivity] {
        return Array(activities.prefix(limit))
    }
}