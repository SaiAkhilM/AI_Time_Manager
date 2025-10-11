import Foundation
import CoreData
import Combine

struct SchedulingSuggestion {
    let id = UUID()
    let taskId: UUID
    let suggestedStartTime: Date
    let suggestedEndTime: Date
    let confidence: Double
    let reason: String
    let priority: Int

    enum SuggestionType {
        case optimal, alternative, emergency
    }

    let type: SuggestionType
}

struct TimeSlot {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let isAvailable: Bool
    let conflictingTasks: [Task]
    let conflictingEvents: [Event]

    var quality: Double {
        if !isAvailable { return 0.0 }
        let conflictPenalty = Double(conflictingTasks.count + conflictingEvents.count) * 0.2
        return max(0.0, 1.0 - conflictPenalty)
    }
}

class IntelligentSchedulingService: ObservableObject {
    @Published var suggestions: [SchedulingSuggestion] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func generateSchedulingSuggestions(for task: Task) async -> [SchedulingSuggestion] {
        guard let taskId = task.id else { return [] }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let taskDuration = estimateTaskDuration(task)
        let availableSlots = findAvailableTimeSlots(
            duration: taskDuration,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        )

        let prioritizedSlots = prioritizeTimeSlots(availableSlots, for: task)
        let suggestions = createSuggestions(from: prioritizedSlots, for: taskId, duration: taskDuration)

        DispatchQueue.main.async {
            self.suggestions = suggestions
        }

        return suggestions
    }

    func optimizeExistingSchedule(for date: Date) async -> [SchedulingSuggestion] {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let tasks = getTasksForDate(date)
        let events = getEventsForDate(date)

        let optimizedSchedule = await analyzeAndOptimizeSchedule(tasks: tasks, events: events, date: date)

        DispatchQueue.main.async {
            self.suggestions = optimizedSchedule
        }

        return optimizedSchedule
    }

    private func estimateTaskDuration(_ task: Task) -> TimeInterval {
        if let startTime = task.startTime, let endTime = task.endTime {
            return endTime.timeIntervalSince(startTime)
        }

        let baseEstimate = estimateBasedOnTitle(task.title ?? "")
        let priorityMultiplier = getPriorityMultiplier(task.priorityEnum)
        let historicalData = getHistoricalDurationForSimilarTasks(task)

        let estimate = (baseEstimate + historicalData) / 2 * priorityMultiplier
        return max(1800, min(14400, estimate)) // Between 30 minutes and 4 hours
    }

    private func estimateBasedOnTitle(_ title: String) -> TimeInterval {
        let lowercaseTitle = title.lowercased()

        // Quick tasks (30-60 minutes)
        let quickKeywords = ["call", "email", "message", "check", "review", "quick", "brief"]
        if quickKeywords.contains(where: lowercaseTitle.contains) {
            return 2700 // 45 minutes
        }

        // Medium tasks (1-2 hours)
        let mediumKeywords = ["meeting", "write", "plan", "design", "research", "analyze"]
        if mediumKeywords.contains(where: lowercaseTitle.contains) {
            return 5400 // 1.5 hours
        }

        // Long tasks (2-4 hours)
        let longKeywords = ["develop", "implement", "create", "build", "project", "study", "learn"]
        if longKeywords.contains(where: lowercaseTitle.contains) {
            return 7200 // 2 hours
        }

        return 3600 // Default 1 hour
    }

    private func getPriorityMultiplier(_ priority: Task.Priority) -> Double {
        switch priority {
        case .high: return 1.2
        case .medium: return 1.0
        case .low: return 0.8
        case .none: return 1.0
        }
    }

    private func getHistoricalDurationForSimilarTasks(_ task: Task) -> TimeInterval {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES AND startTime != nil AND endTime != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]
        request.fetchLimit = 10

        do {
            let completedTasks = try context.fetch(request)
            let similarTasks = completedTasks.filter { completedTask in
                guard let title = completedTask.title, let currentTitle = task.title else { return false }
                return calculateSimilarity(title, currentTitle) > 0.5
            }

            if !similarTasks.isEmpty {
                let totalDuration = similarTasks.compactMap { task in
                    guard let start = task.startTime, let end = task.endTime else { return nil }
                    return end.timeIntervalSince(start)
                }.reduce(0, +)

                return totalDuration / Double(similarTasks.count)
            }
        } catch {
            print("Failed to fetch historical tasks: \(error)")
        }

        return 3600 // Default 1 hour
    }

    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    private func findAvailableTimeSlots(duration: TimeInterval, startDate: Date, endDate: Date) -> [TimeSlot] {
        var timeSlots: [TimeSlot] = []
        let calendar = Calendar.current

        var currentDate = startDate
        while currentDate < endDate {
            let daySlots = findDailyAvailableSlots(for: currentDate, requiredDuration: duration)
            timeSlots.append(contentsOf: daySlots)

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        return timeSlots.filter { $0.duration >= duration }
    }

    private func findDailyAvailableSlots(for date: Date, requiredDuration: TimeInterval) -> [TimeSlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Working hours: 8 AM to 8 PM
        guard let workStart = calendar.date(byAdding: .hour, value: 8, to: startOfDay),
              let workEnd = calendar.date(byAdding: .hour, value: 20, to: startOfDay) else {
            return []
        }

        let tasks = getTasksForDate(date)
        let events = getEventsForDate(date)

        var occupiedIntervals: [(start: Date, end: Date)] = []

        // Add task intervals
        for task in tasks {
            if let startTime = task.startTime, let endTime = task.endTime {
                occupiedIntervals.append((start: startTime, end: endTime))
            }
        }

        // Add event intervals
        for event in events {
            if let startTime = event.startTime, let endTime = event.endTime {
                occupiedIntervals.append((start: startTime, end: endTime))
            }
        }

        // Sort intervals by start time
        occupiedIntervals.sort { $0.start < $1.start }

        var availableSlots: [TimeSlot] = []
        var currentTime = workStart

        for interval in occupiedIntervals {
            // Add slot before this interval if there's enough time
            if interval.start > currentTime {
                let duration = interval.start.timeIntervalSince(currentTime)
                if duration >= requiredDuration {
                    let slot = TimeSlot(
                        startTime: currentTime,
                        endTime: interval.start,
                        duration: duration,
                        isAvailable: true,
                        conflictingTasks: [],
                        conflictingEvents: []
                    )
                    availableSlots.append(slot)
                }
            }

            currentTime = max(currentTime, interval.end)
        }

        // Add final slot if there's time left in the day
        if currentTime < workEnd {
            let duration = workEnd.timeIntervalSince(currentTime)
            if duration >= requiredDuration {
                let slot = TimeSlot(
                    startTime: currentTime,
                    endTime: workEnd,
                    duration: duration,
                    isAvailable: true,
                    conflictingTasks: [],
                    conflictingEvents: []
                )
                availableSlots.append(slot)
            }
        }

        return availableSlots
    }

    private func prioritizeTimeSlots(_ slots: [TimeSlot], for task: Task) -> [TimeSlot] {
        return slots.sorted { slot1, slot2 in
            let score1 = calculateSlotScore(slot1, for: task)
            let score2 = calculateSlotScore(slot2, for: task)
            return score1 > score2
        }
    }

    private func calculateSlotScore(_ slot: TimeSlot, for task: Task) -> Double {
        var score = slot.quality

        // Prefer morning slots for high priority tasks
        if task.priorityEnum == .high {
            let hour = Calendar.current.component(.hour, from: slot.startTime)
            if hour >= 8 && hour <= 12 {
                score += 0.3
            }
        }

        // Prefer afternoon for medium priority
        if task.priorityEnum == .medium {
            let hour = Calendar.current.component(.hour, from: slot.startTime)
            if hour >= 13 && hour <= 17 {
                score += 0.2
            }
        }

        // Bonus for longer slots
        if slot.duration > 7200 { // More than 2 hours
            score += 0.1
        }

        return score
    }

    private func createSuggestions(from slots: [TimeSlot], for taskId: UUID, duration: TimeInterval) -> [SchedulingSuggestion] {
        let topSlots = Array(slots.prefix(3))

        return topSlots.enumerated().map { index, slot in
            let endTime = slot.startTime.addingTimeInterval(duration)
            let confidence = slot.quality * (1.0 - Double(index) * 0.1)

            let type: SchedulingSuggestion.SuggestionType = index == 0 ? .optimal : .alternative
            let reason = generateReasonForSlot(slot, index: index)

            return SchedulingSuggestion(
                taskId: taskId,
                suggestedStartTime: slot.startTime,
                suggestedEndTime: endTime,
                confidence: confidence,
                reason: reason,
                priority: index,
                type: type
            )
        }
    }

    private func generateReasonForSlot(_ slot: TimeSlot, index: Int) -> String {
        let hour = Calendar.current.component(.hour, from: slot.startTime)

        switch index {
        case 0:
            if hour >= 8 && hour <= 10 {
                return "Optimal morning slot - peak productivity hours"
            } else if hour >= 13 && hour <= 15 {
                return "Good afternoon slot - post-lunch focus time"
            } else {
                return "Best available time slot with no conflicts"
            }
        case 1:
            return "Alternative time with good availability"
        default:
            return "Backup option if other times don't work"
        }
    }

    private func analyzeAndOptimizeSchedule(tasks: [Task], events: [Event], date: Date) async -> [SchedulingSuggestion] {
        var suggestions: [SchedulingSuggestion] = []

        // Look for scheduling conflicts and optimization opportunities
        let allTimeItems = createTimeItems(from: tasks, events: events)
        let conflicts = detectConflicts(in: allTimeItems)

        // Generate suggestions to resolve conflicts
        for conflict in conflicts {
            if let task = conflict as? Task, let taskId = task.id {
                let duration = estimateTaskDuration(task)
                let alternativeSlots = findAvailableTimeSlots(
                    duration: duration,
                    startDate: Calendar.current.startOfDay(for: date),
                    endDate: Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                )

                if let bestSlot = alternativeSlots.first {
                    let suggestion = SchedulingSuggestion(
                        taskId: taskId,
                        suggestedStartTime: bestSlot.startTime,
                        suggestedEndTime: bestSlot.startTime.addingTimeInterval(duration),
                        confidence: 0.8,
                        reason: "Resolving scheduling conflict",
                        priority: 0,
                        type: .emergency
                    )
                    suggestions.append(suggestion)
                }
            }
        }

        return suggestions
    }

    private func createTimeItems(from tasks: [Task], events: [Event]) -> [(start: Date, end: Date, item: Any)] {
        var items: [(start: Date, end: Date, item: Any)] = []

        for task in tasks {
            if let start = task.startTime, let end = task.endTime {
                items.append((start: start, end: end, item: task))
            }
        }

        for event in events {
            if let start = event.startTime, let end = event.endTime {
                items.append((start: start, end: end, item: event))
            }
        }

        return items.sorted { $0.start < $1.start }
    }

    private func detectConflicts(in items: [(start: Date, end: Date, item: Any)]) -> [Any] {
        var conflicts: [Any] = []

        for i in 0..<items.count {
            for j in (i+1)..<items.count {
                let item1 = items[i]
                let item2 = items[j]

                // Check for overlap
                if item1.start < item2.end && item2.start < item1.end {
                    conflicts.append(item2.item)
                }
            }
        }

        return conflicts
    }

    private func getTasksForDate(_ date: Date) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.startTime, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }

    private func getEventsForDate(_ date: Date) -> [Event] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.startTime, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch events: \(error)")
            return []
        }
    }
}