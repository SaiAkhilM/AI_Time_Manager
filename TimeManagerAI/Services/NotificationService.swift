import Foundation
import UserNotifications
import CoreData

class NotificationService: ObservableObject {
    @Published var notificationPermissionGranted = false
    @Published var errorMessage: String?

    private let center = UNUserNotificationCenter.current()

    init() {
        checkNotificationPermission()
    }

    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
            return granted
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func checkNotificationPermission() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleTaskReminder(for task: Task) {
        guard notificationPermissionGranted else {
            print("⚠️ Notification permission not granted")
            return
        }

        guard let startTime = task.startTime else {
            print("⚠️ Task has no start time")
            return
        }

        let reminderTime = Calendar.current.date(byAdding: .minute, value: -15, to: startTime) ?? startTime

        guard reminderTime > Date() else {
            print("⚠️ Reminder time is in the past")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Upcoming Task"
        content.body = "\(task.title ?? "Task") starts in 15 minutes"
        content.sound = .default

        if let priority = task.priority {
            switch priority {
            case "red":
                content.title = "🔴 HIGH PRIORITY"
                content.body = "\(task.title ?? "Task") starts in 15 minutes"
            case "orange":
                content.title = "🟠 MEDIUM PRIORITY"
                content.body = "\(task.title ?? "Task") starts in 15 minutes"
            case "yellow":
                content.title = "📅 Event Starting Soon"
                content.body = "\(task.title ?? "Event") starts in 15 minutes"
            default:
                break
            }
        }

        content.userInfo = [
            "taskId": task.id?.uuidString ?? "",
            "taskTitle": task.title ?? "",
            "type": "taskReminder"
        ]

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task-reminder-\(task.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to schedule reminder: \(error.localizedDescription)"
                }
            } else {
                print("✅ Scheduled reminder for task: \(task.title ?? "Untitled")")
            }
        }
    }

    func scheduleDeadlineWarning(for task: Task, daysBeforeDeadline: Int) {
        guard notificationPermissionGranted else { return }

        guard let deadline = task.endTime else { return }

        let warningTime = Calendar.current.date(byAdding: .day, value: -daysBeforeDeadline, to: deadline) ?? deadline

        guard warningTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Deadline Approaching"

        let daysText = daysBeforeDeadline == 1 ? "tomorrow" : "in \(daysBeforeDeadline) days"
        content.body = "\(task.title ?? "Task") is due \(daysText)"
        content.sound = .default

        if task.priority == "red" {
            content.title = "🚨 URGENT DEADLINE"
            content.body = "HIGH PRIORITY: \(task.title ?? "Task") is due \(daysText)"
        }

        content.userInfo = [
            "taskId": task.id?.uuidString ?? "",
            "taskTitle": task.title ?? "",
            "type": "deadlineWarning",
            "daysUntilDeadline": daysBeforeDeadline
        ]

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: warningTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "deadline-warning-\(task.id?.uuidString ?? UUID().uuidString)-\(daysBeforeDeadline)d",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule deadline warning: \(error)")
            } else {
                print("✅ Scheduled deadline warning for task: \(task.title ?? "Untitled")")
            }
        }
    }

    func scheduleSleepTimeWarning(sleepTime: Date, warningMinutes: Int) {
        guard notificationPermissionGranted else { return }

        let warningTime = Calendar.current.date(byAdding: .minute, value: -warningMinutes, to: sleepTime) ?? sleepTime

        guard warningTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "😴 Bedtime Reminder"
        content.body = "Time to wind down. Bedtime in \(warningMinutes) minutes."
        content.sound = .default

        content.userInfo = [
            "type": "sleepWarning",
            "warningMinutes": warningMinutes
        ]

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: warningTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "sleep-warning-\(warningMinutes)m",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule sleep warning: \(error)")
            } else {
                print("✅ Scheduled daily sleep warning")
            }
        }
    }

    func scheduleIncompleteTaskAlert(for task: Task) {
        guard notificationPermissionGranted else { return }

        guard let endTime = task.endTime else { return }

        let alertTime = Calendar.current.date(byAdding: .minute, value: 30, to: endTime) ?? endTime

        guard alertTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏱️ Task Running Over"

        let timeOverText = "You've been on \(task.title ?? "this task") for 30 minutes longer than planned. Still on track?"
        content.body = timeOverText
        content.sound = .default

        content.userInfo = [
            "taskId": task.id?.uuidString ?? "",
            "taskTitle": task.title ?? "",
            "type": "incompleteTask"
        ]

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "incomplete-task-\(task.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule incomplete task alert: \(error)")
            } else {
                print("✅ Scheduled incomplete task alert for: \(task.title ?? "Untitled")")
            }
        }
    }

    func cancelNotifications(for task: Task) {
        guard let taskId = task.id?.uuidString else { return }

        let identifiers = [
            "task-reminder-\(taskId)",
            "deadline-warning-\(taskId)-1d",
            "deadline-warning-\(taskId)-3d",
            "deadline-warning-\(taskId)-7d",
            "incomplete-task-\(taskId)"
        ]

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ Cancelled notifications for task: \(task.title ?? "Untitled")")
    }

    func cancelAllSleepWarnings() {
        let identifiers = [
            "sleep-warning-15m",
            "sleep-warning-30m",
            "sleep-warning-60m"
        ]

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ Cancelled all sleep warnings")
    }

    func scheduleAllNotificationsForTask(_ task: Task) {
        scheduleTaskReminder(for: task)
        scheduleDeadlineWarning(for: task, daysBeforeDeadline: 1)
        scheduleDeadlineWarning(for: task, daysBeforeDeadline: 3)
        scheduleDeadlineWarning(for: task, daysBeforeDeadline: 7)
        scheduleIncompleteTaskAlert(for: task)
    }

    func refreshAllNotifications() {
        center.removeAllPendingNotificationRequests()

        let context = PersistenceController.shared.container.viewContext
        let taskRequest: NSFetchRequest<Task> = Task.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "isCompleted == NO AND startTime > %@", Date() as NSDate)

        do {
            let upcomingTasks = try context.fetch(taskRequest)
            for task in upcomingTasks {
                scheduleAllNotificationsForTask(task)
            }
            print("✅ Refreshed notifications for \(upcomingTasks.count) upcoming tasks")
        } catch {
            print("❌ Failed to refresh notifications: \(error)")
        }

        let settingsRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        do {
            if let settings = try context.fetch(settingsRequest).first,
               let sleepTime = settings.sleepStartTime {
                scheduleSleepTimeWarning(sleepTime: sleepTime, warningMinutes: Int(settings.bedtimeWarningMinutes))
            }
        } catch {
            print("❌ Failed to schedule sleep warnings: \(error)")
        }
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "taskReminder":
            if let taskId = userInfo["taskId"] as? String {
                print("📱 User interacted with task reminder: \(taskId)")
            }
        case "deadlineWarning":
            if let taskId = userInfo["taskId"] as? String {
                print("📱 User interacted with deadline warning: \(taskId)")
            }
        case "sleepWarning":
            print("📱 User interacted with sleep warning")
        case "incompleteTask":
            if let taskId = userInfo["taskId"] as? String {
                print("📱 User interacted with incomplete task alert: \(taskId)")
            }
        default:
            break
        }
    }
}