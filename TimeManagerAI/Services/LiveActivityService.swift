import Foundation
import ActivityKit
import WidgetKit
import CoreData

@available(iOS 16.1, *)
class LiveActivityService: ObservableObject {
    @Published var currentActivity: Activity<TaskAttributes>?
    @Published var errorMessage: String?

    init() {
        observeActivityUpdates()
    }

    func startTaskActivity(for task: TaskEntity) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "Live Activities are not enabled"
            return
        }

        let attributes = TaskAttributes(taskId: task.id.uuidString)
        let contentState = TaskAttributes.ContentState(
            taskTitle: task.title ?? "Untitled Task",
            startTime: task.startTime ?? Date(),
            endTime: task.endTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: task.startTime ?? Date()) ?? Date(),
            priority: task.priority ?? "none",
            isCompleted: task.isCompleted
        )

        do {
            let activity = try Activity<TaskAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
            print("✅ Live Activity started for task: \(task.title ?? "Untitled")")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            errorMessage = "Failed to start Live Activity: \(error.localizedDescription)"
        }
    }

    func updateTaskEntityActivity(task: TaskEntity, isCompleted: Bool) {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to update")
            return
        }

        let updatedContentState = TaskAttributes.ContentState(
            taskTitle: task.title ?? "Untitled Task",
            startTime: task.startTime ?? Date(),
            endTime: task.endTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: task.startTime ?? Date()) ?? Date(),
            priority: task.priority ?? "none",
            isCompleted: isCompleted
        )

        Task {
            await activity.update(using: updatedContentState)
            print("✅ Live Activity updated for task: \(task.title ?? "Untitled")")
        }
    }

    func endCurrentActivity() {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to end")
            return
        }

        Task {
            await activity.end(dismissalPolicy: .immediate)
            DispatchQueue.main.async {
                self.currentActivity = nil
            }
            print("✅ Live Activity ended")
        }
    }

    func startNextTaskEntityIfNeeded() {
        guard currentActivity == nil else {
            print("⚠️ Live Activity already running")
            return
        }

        let currentTaskEntity = getCurrentActiveTaskEntity()
        if let task = currentTaskEntity {
            startTaskActivity(for: task)
        }
    }

    private func getCurrentActiveTaskEntity() -> TaskEntity? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()

        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND isCompleted == NO AND startTime <= %@",
                                       startOfToday as NSDate,
                                       endOfToday as NSDate,
                                       now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.startTime, ascending: true)]
        request.fetchLimit = 1

        do {
            let tasks = try context.fetch(request)
            return tasks.first
        } catch {
            print("❌ Failed to fetch current task: \(error)")
            return nil
        }
    }

    private func observeActivityUpdates() {
        Task {
            for await activity in Activity<TaskAttributes>.activityUpdates {
                DispatchQueue.main.async {
                    self.currentActivity = activity
                }
            }
        }
    }
}

@available(iOS 16.1, *)
struct TaskAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let taskTitle: String
        let startTime: Date
        let endTime: Date
        let priority: String
        let isCompleted: Bool

        var timeProgress: Double {
            let now = Date()
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsedDuration = now.timeIntervalSince(startTime)

            if elapsedDuration <= 0 {
                return 0.0
            } else if elapsedDuration >= totalDuration {
                return 1.0
            } else {
                return elapsedDuration / totalDuration
            }
        }

        var timeRemaining: String {
            let now = Date()
            let remaining = endTime.timeIntervalSince(now)

            if remaining <= 0 {
                return "Overdue"
            } else if remaining < 60 {
                return "\(Int(remaining))s"
            } else if remaining < 3600 {
                return "\(Int(remaining / 60))m"
            } else {
                let hours = Int(remaining / 3600)
                let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
                return "\(hours)h \(minutes)m"
            }
        }

        var priorityColor: String {
            switch priority {
            case "red": return "systemRed"
            case "orange": return "systemOrange"
            case "yellow": return "systemYellow"
            default: return "systemGray"
            }
        }
    }

    let taskId: String
}