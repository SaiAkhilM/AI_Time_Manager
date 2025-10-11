import Foundation
import CoreData

extension Task {
    enum Priority: String, CaseIterable {
        case high = "red"
        case medium = "orange"
        case event = "yellow"
        case none = "none"

        var displayName: String {
            switch self {
            case .high: return "High Priority"
            case .medium: return "Medium Priority"
            case .event: return "Event/Class"
            case .none: return "Normal"
            }
        }
    }

    var priorityEnum: Priority {
        get { Priority(rawValue: priority ?? "none") ?? .none }
        set { priority = newValue.rawValue }
    }

    static func create(
        in context: NSManagedObjectContext,
        title: String,
        description: String? = nil,
        priority: Priority = .none,
        startTime: Date? = nil,
        endTime: Date? = nil,
        date: Date? = nil
    ) -> Task {
        let task = Task(context: context)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.priorityEnum = priority
        task.startTime = startTime
        task.endTime = endTime
        task.date = date
        task.isRecurring = false
        task.isCompleted = false
        task.createdAt = Date()
        task.updatedAt = Date()

        return task
    }

    func updateTimestamp() {
        self.updatedAt = Date()
    }
}