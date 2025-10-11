import Foundation
import CoreData

class SampleDataManager {
    static func createSampleTasks(in context: NSManagedObjectContext) {
        clearExistingData(in: context)

        let today = Date()
        let calendar = Calendar.current

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let sampleTasks = [
            ("5C Class", today, 8, 9, Task.Priority.medium),
            ("ODE Class", today, 10, 11, Task.Priority.medium),
            ("Meeting with Kathryn", today, 13, 14, Task.Priority.event),
            ("Work Block", today, 14, 17, Task.Priority.high),
            ("M24 Class", today, 17, 18, Task.Priority.event),
            ("Gym", today, 19, 20, Task.Priority.none),

            ("5C Lab", tomorrow, 8, 11, Task.Priority.medium),
            ("ODE Office Hours", tomorrow, 13, 14, Task.Priority.medium),
            ("Deep Work", tomorrow, 15, 17, Task.Priority.high),
            ("Startup Club", tomorrow, 19, 20, Task.Priority.event)
        ]

        for (title, date, startHour, endHour, priority) in sampleTasks {
            let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
            let endTime = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: date) ?? date

            let task = Task.create(
                in: context,
                title: title,
                description: nil,
                priority: priority,
                startTime: startTime,
                endTime: endTime,
                date: date
            )
        }

        let sampleEvents = [
            ("Transfer College Essays Due", calendar.date(byAdding: .day, value: 15, to: today) ?? today, 23, 23),
            ("Doctor Appointment", calendar.date(byAdding: .day, value: 30, to: today) ?? today, 14, 15),
        ]

        for (title, date, startHour, endHour) in sampleEvents {
            let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
            let endTime = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: date) ?? date

            let event = Event.create(
                in: context,
                title: title,
                description: nil,
                startTime: startTime,
                endTime: endTime,
                location: nil
            )
        }

        let unscheduledTasks = [
            ("Finish ODE homework", Task.Priority.high),
            ("Apply to internships", Task.Priority.medium),
            ("Update resume", Task.Priority.medium),
            ("Call mom", Task.Priority.none),
            ("Plan weekend trip", Task.Priority.none)
        ]

        for (title, priority) in unscheduledTasks {
            let task = Task.create(
                in: context,
                title: title,
                description: nil,
                priority: priority
            )
        }

        do {
            try context.save()
            print("✅ Sample data created successfully")
        } catch {
            print("❌ Failed to save sample data: \(error)")
        }
    }

    private static func clearExistingData(in context: NSManagedObjectContext) {
        let taskRequest: NSFetchRequest<NSFetchRequestResult> = Task.fetchRequest()
        let deleteTasksRequest = NSBatchDeleteRequest(fetchRequest: taskRequest)

        let eventRequest: NSFetchRequest<NSFetchRequestResult> = Event.fetchRequest()
        let deleteEventsRequest = NSBatchDeleteRequest(fetchRequest: eventRequest)

        do {
            try context.execute(deleteTasksRequest)
            try context.execute(deleteEventsRequest)
            try context.save()
            print("✅ Existing data cleared")
        } catch {
            print("❌ Failed to clear existing data: \(error)")
        }
    }

    static func shouldCreateSampleData(in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            return count == 0
        } catch {
            print("Failed to check existing data: \(error)")
            return false
        }
    }
}