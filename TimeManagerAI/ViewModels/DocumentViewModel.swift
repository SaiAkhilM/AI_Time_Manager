import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
class DocumentViewModel: ObservableObject {
    @Published var documentContent: NSAttributedString = NSAttributedString()
    @Published var isEditing = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private let currentWeekNumber: Int

    init(context: NSManagedObjectContext) {
        self.context = context
        self.currentWeekNumber = Calendar.current.component(.weekOfYear, from: Date())
        setupNotificationObservers()
        // Defer document generation until view appears - prevents KeyPath errors during init
    }

    /// Call this method when the view appears to safely load Core Data
    func viewDidAppear() {
        generateWeeklyDocument()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .taskCreated)
            .sink { [weak self] _ in
                self?.generateWeeklyDocument()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .taskUpdated)
            .sink { [weak self] _ in
                self?.generateWeeklyDocument()
            }
            .store(in: &cancellables)
    }

    func generateWeeklyDocument() {
        let document = createWeeklyDocumentContent()
        documentContent = document
    }

    private func createWeeklyDocumentContent() -> NSAttributedString {
        let document = NSMutableAttributedString()
        let calendar = Calendar.current

        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return NSAttributedString(string: "Error loading weekly schedule")
        }

        let weekDays = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }

        let headerStyle = createHeaderStyle()
        let taskStyle = createTaskStyle()
        let timeStyle = createTimeStyle()
        let linkStyle = createLinkStyle()

        for (index, date) in weekDays.enumerated() {
            let dayName = date.formatted(.dateTime.weekday(.wide))
            let dayHeader = NSAttributedString(string: "\(dayName):\n", attributes: headerStyle)
            document.append(dayHeader)

            let dayTasks = getTasksForDate(date)
            let dayEvents = getEventsForDate(date)

            let allItems = (dayTasks.map { ItemWrapper.task($0) } + dayEvents.map { ItemWrapper.event($0) })
                .sorted { item1, item2 in
                    let time1 = item1.startTime ?? Date.distantPast
                    let time2 = item2.startTime ?? Date.distantPast
                    return time1 < time2
                }

            if allItems.isEmpty {
                let emptyText = NSAttributedString(string: "• No scheduled items\n", attributes: taskStyle)
                document.append(emptyText)
            } else {
                for item in allItems {
                    let bullet = NSAttributedString(string: "• ", attributes: taskStyle)
                    document.append(bullet)

                    if let startTime = item.startTime, let endTime = item.endTime {
                        let timeText = NSAttributedString(
                            string: "\(startTime.formatted(.dateTime.hour().minute())) to \(endTime.formatted(.dateTime.hour().minute())) - ",
                            attributes: timeStyle
                        )
                        document.append(timeText)
                    } else if let startTime = item.startTime {
                        let timeText = NSAttributedString(
                            string: "\(startTime.formatted(.dateTime.hour().minute())) - ",
                            attributes: timeStyle
                        )
                        document.append(timeText)
                    }

                    var titleAttributes = taskStyle
                    titleAttributes[.foregroundColor] = item.priorityColor

                    let titleText = NSAttributedString(string: item.title, attributes: titleAttributes)
                    document.append(titleText)

                    if item.isCompleted {
                        let completedText = NSAttributedString(string: " ✓", attributes: [.foregroundColor: UIColor.systemGreen])
                        document.append(completedText)
                    }

                    document.append(NSAttributedString(string: "\n"))

                    if let description = item.description, !description.isEmpty {
                        let descIndent = NSAttributedString(string: "  ○ \(description)\n", attributes: taskStyle)
                        document.append(descIndent)
                    }

                    if let linkedURL = item.linkedURL, !linkedURL.isEmpty {
                        let linkIndent = NSAttributedString(string: "  ○ ", attributes: taskStyle)
                        document.append(linkIndent)
                        let linkText = NSAttributedString(string: "\(linkedURL)\n", attributes: linkStyle)
                        document.append(linkText)
                    }
                }
            }

            document.append(NSAttributedString(string: "\n"))
        }

        addFutureEventsSection(to: document, headerStyle: headerStyle, taskStyle: taskStyle, timeStyle: timeStyle)
        addGoalsSection(to: document, headerStyle: headerStyle, taskStyle: taskStyle)
        addUnscheduledTasksSection(to: document, headerStyle: headerStyle, taskStyle: taskStyle, linkStyle: linkStyle)

        return document
    }

    private func addFutureEventsSection(to document: NSMutableAttributedString, headerStyle: [NSAttributedString.Key: Any], taskStyle: [NSAttributedString.Key: Any], timeStyle: [NSAttributedString.Key: Any]) {
        let futureEvents = getFutureEvents()
        if !futureEvents.isEmpty {
            let header = NSAttributedString(string: "Future Events:\n", attributes: headerStyle)
            document.append(header)

            for event in futureEvents {
                let bullet = NSAttributedString(string: "• ", attributes: taskStyle)
                document.append(bullet)

                let startTime = event.startTime
                let dateText = NSAttributedString(
                    string: "\(startTime.formatted(.dateTime.month().day())) - ",
                    attributes: timeStyle
                )
                document.append(dateText)

                let titleText = NSAttributedString(string: "\(event.title)\n", attributes: taskStyle)
                document.append(titleText)
            }

            document.append(NSAttributedString(string: "\n"))
        }
    }

    private func addGoalsSection(to document: NSMutableAttributedString, headerStyle: [NSAttributedString.Key: Any], taskStyle: [NSAttributedString.Key: Any]) {
        let header = NSAttributedString(string: "Goals This Week:\n", attributes: headerStyle)
        document.append(header)

        let goals = getActiveGoals()
        if goals.isEmpty {
            let goalText = NSAttributedString(string: "• Exercise 5 times\n• Complete all coursework\n• Work 10 hours on startup\n\n", attributes: taskStyle)
            document.append(goalText)
        } else {
            for goal in goals {
                let bullet = NSAttributedString(string: "• ", attributes: taskStyle)
                document.append(bullet)
                let goalText = NSAttributedString(string: "\(goal.title ?? "Untitled Goal")\n", attributes: taskStyle)
                document.append(goalText)
            }
            document.append(NSAttributedString(string: "\n"))
        }
    }

    private func addUnscheduledTasksSection(to document: NSMutableAttributedString, headerStyle: [NSAttributedString.Key: Any], taskStyle: [NSAttributedString.Key: Any], linkStyle: [NSAttributedString.Key: Any]) {
        let unscheduledTasks = getUnscheduledTasks()
        if !unscheduledTasks.isEmpty {
            let header = NSAttributedString(string: "Unscheduled Tasks:\n", attributes: headerStyle)
            document.append(header)

            for task in unscheduledTasks {
                let bullet = NSAttributedString(string: "• ", attributes: taskStyle)
                document.append(bullet)

                var titleAttributes = taskStyle
                titleAttributes[.foregroundColor] = task.priorityEnum.uiColor

                let titleText = NSAttributedString(string: task.title, attributes: titleAttributes)
                document.append(titleText)

                if task.isCompleted {
                    let completedText = NSAttributedString(string: " ✓", attributes: [.foregroundColor: UIColor.systemGreen])
                    document.append(completedText)
                }

                document.append(NSAttributedString(string: "\n"))

                if let description = task.taskDescription, !description.isEmpty {
                    let descIndent = NSAttributedString(string: "  ○ \(description)\n", attributes: taskStyle)
                    document.append(descIndent)
                }

                if let linkedURL = task.linkedURL, !linkedURL.isEmpty {
                    let linkIndent = NSAttributedString(string: "  ○ ", attributes: taskStyle)
                    document.append(linkIndent)
                    let linkText = NSAttributedString(string: "\(linkedURL)\n", attributes: linkStyle)
                    document.append(linkText)
                }
            }
        }
    }

    private func getTasksForDate(_ date: Date) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.startTime, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tasks for date: \(error)")
            return []
        }
    }

    private func getEventsForDate(_ date: Date) -> [Event] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.startTime, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch events for date: \(error)")
            return []
        }
    }

    private func getFutureEvents() -> [Event] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()

        request.predicate = NSPredicate(format: "startTime >= %@", nextWeek as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.startTime, ascending: true)]
        request.fetchLimit = 10

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch future events: \(error)")
            return []
        }
    }

    private func getActiveGoals() -> [Goal] {
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Goal.title, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch goals: \(error)")
            return []
        }
    }

    private func getUnscheduledTasks() -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date == nil AND isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.priorityEnum, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch unscheduled tasks: \(error)")
            return []
        }
    }

    private func createHeaderStyle() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]
    }

    private func createTaskStyle() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
    }

    private func createTimeStyle() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
    }

    private func createLinkStyle() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
}

private struct ItemWrapper {
    let title: String
    let description: String?
    let startTime: Date?
    let endTime: Date?
    let priorityColor: UIColor
    let isCompleted: Bool
    let linkedURL: String?

    static func task(_ task: TaskEntity) -> ItemWrapper {
        return ItemWrapper(
            title: task.title ?? "Untitled Task",
            description: task.taskDescription,
            startTime: task.startTime,
            endTime: task.endTime,
            priorityColor: task.priorityEnum.uiColor,
            isCompleted: task.isCompleted,
            linkedURL: task.linkedURL
        )
    }

    static func event(_ event: Event) -> ItemWrapper {
        return ItemWrapper(
            title: event.title ?? "Untitled Event",
            description: event.eventDescription,
            startTime: event.startTime,
            endTime: event.endTime,
            priorityColor: UIColor.systemBlue,
            isCompleted: false,
            linkedURL: nil
        )
    }
}

extension TaskEntity.Priority {
    var uiColor: UIColor {
        switch self {
        case .high: return UIColor.systemRed
        case .medium: return UIColor.systemOrange
        case .event: return UIColor.systemYellow
        case .none: return UIColor.label
        }
    }
}