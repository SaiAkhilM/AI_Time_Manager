import Foundation
import CoreData
import Combine

struct OptimizationSuggestion {
    let id = UUID()
    let type: OptimizationType
    let title: String
    let description: String
    let impact: Impact
    let actionItems: [String]
    let estimatedTimeSaved: TimeInterval
    let confidence: Double

    enum OptimizationType {
        case timeBlocking
        case taskBatching
        case energyOptimization
        case deadlineRebalancing
        case focusTimeProtection
        case breakScheduling
    }

    enum Impact {
        case low, medium, high, critical

        var color: String {
            switch self {
            case .low: return "systemGreen"
            case .medium: return "systemOrange"
            case .high: return "systemRed"
            case .critical: return "systemPurple"
            }
        }
    }
}

struct ProductivityMetrics {
    let averageTaskDuration: TimeInterval
    let completionRate: Double
    let peakProductivityHours: [Int]
    let commonTaskTypes: [String: Int]
    let averageBreakTime: TimeInterval
    let overdueTasks: Int
    let weeklyWorkload: TimeInterval
}

class ContextAwareOptimizationService: ObservableObject {
    @Published var optimizationSuggestions: [OptimizationSuggestion] = []
    @Published var productivityMetrics: ProductivityMetrics?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func analyzeAndOptimizeSchedule(for dateRange: DateInterval? = nil) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let range = dateRange ?? DateInterval(start: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(), duration: 7 * 24 * 3600)

        let metrics = await calculateProductivityMetrics(for: range)
        let suggestions = await generateOptimizationSuggestions(based: metrics, for: range)

        DispatchQueue.main.async {
            self.productivityMetrics = metrics
            self.optimizationSuggestions = suggestions
        }
    }

    private func calculateProductivityMetrics(for dateRange: DateInterval) async -> ProductivityMetrics {
        let tasks = getTasksInRange(dateRange)
        let completedTasks = tasks.filter { $0.isCompleted }

        let averageTaskDuration = calculateAverageTaskDuration(from: completedTasks)
        let completionRate = tasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(tasks.count)
        let peakHours = calculatePeakProductivityHours(from: completedTasks)
        let taskTypes = analyzeCommonTaskTypes(from: tasks)
        let breakTime = calculateAverageBreakTime(from: tasks)
        let overdueCount = tasks.filter { isTaskOverdue($0) }.count
        let weeklyWorkload = calculateTotalWorkload(from: tasks)

        return ProductivityMetrics(
            averageTaskDuration: averageTaskDuration,
            completionRate: completionRate,
            peakProductivityHours: peakHours,
            commonTaskTypes: taskTypes,
            averageBreakTime: breakTime,
            overdueTasks: overdueCount,
            weeklyWorkload: weeklyWorkload
        )
    }

    private func generateOptimizationSuggestions(based metrics: ProductivityMetrics, for dateRange: DateInterval) async -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []

        // Analyze completion rate
        if metrics.completionRate < 0.7 {
            suggestions.append(createCompletionRateOptimization(metrics))
        }

        // Analyze peak productivity hours
        if !metrics.peakProductivityHours.isEmpty {
            suggestions.append(createPeakHoursOptimization(metrics))
        }

        // Analyze task batching opportunities
        if metrics.commonTaskTypes.count > 3 {
            suggestions.append(createTaskBatchingOptimization(metrics))
        }

        // Analyze break scheduling
        if metrics.averageBreakTime < 900 { // Less than 15 minutes
            suggestions.append(createBreakOptimization(metrics))
        }

        // Analyze overdue tasks
        if metrics.overdueTasks > 0 {
            suggestions.append(createDeadlineOptimization(metrics))
        }

        // Analyze workload balance
        if metrics.weeklyWorkload > 40 * 3600 { // More than 40 hours
            suggestions.append(createWorkloadOptimization(metrics))
        }

        // Analyze energy optimization
        suggestions.append(createEnergyOptimization(metrics))

        return suggestions.sorted { $0.impact.rawValue > $1.impact.rawValue }
    }

    private func createCompletionRateOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        let impact: OptimizationSuggestion.Impact = metrics.completionRate < 0.5 ? .critical : .high

        return OptimizationSuggestion(
            type: .timeBlocking,
            title: "Improve Task Completion Rate",
            description: "Your current completion rate is \(Int(metrics.completionRate * 100))%. Time blocking can help you stay focused and complete more tasks.",
            impact: impact,
            actionItems: [
                "Block 2-3 hour focused work sessions in your calendar",
                "Start with your most important tasks during peak hours",
                "Use the Pomodoro technique for better focus",
                "Eliminate distractions during blocked time"
            ],
            estimatedTimeSaved: 3600, // 1 hour per day
            confidence: 0.85
        )
    }

    private func createPeakHoursOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        let peakHoursText = metrics.peakProductivityHours.map { "\($0):00" }.joined(separator: ", ")

        return OptimizationSuggestion(
            type: .energyOptimization,
            title: "Optimize Peak Productivity Hours",
            description: "Your most productive hours are \(peakHoursText). Schedule your most important tasks during these times.",
            impact: .high,
            actionItems: [
                "Schedule high-priority tasks between \(peakHoursText)",
                "Reserve meetings and low-priority tasks for other hours",
                "Block your calendar during peak hours for deep work",
                "Avoid scheduling breaks during peak productivity time"
            ],
            estimatedTimeSaved: 2700, // 45 minutes per day
            confidence: 0.9
        )
    }

    private func createTaskBatchingOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        let topTaskTypes = metrics.commonTaskTypes.sorted { $0.value > $1.value }.prefix(3)
        let taskTypesList = topTaskTypes.map { "\($0.key) (\($0.value) tasks)" }.joined(separator: ", ")

        return OptimizationSuggestion(
            type: .taskBatching,
            title: "Batch Similar Tasks",
            description: "You have many similar tasks: \(taskTypesList). Batching similar tasks reduces context switching.",
            impact: .medium,
            actionItems: [
                "Group similar tasks together in your schedule",
                "Dedicate specific time blocks for each task type",
                "Process all emails/calls in dedicated sessions",
                "Batch administrative tasks into single blocks"
            ],
            estimatedTimeSaved: 1800, // 30 minutes per day
            confidence: 0.8
        )
    }

    private func createBreakOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        let currentBreakMinutes = Int(metrics.averageBreakTime / 60)

        return OptimizationSuggestion(
            type: .breakScheduling,
            title: "Schedule Regular Breaks",
            description: "You're averaging only \(currentBreakMinutes) minutes of breaks. Regular breaks improve focus and prevent burnout.",
            impact: .medium,
            actionItems: [
                "Schedule 15-minute breaks every 2 hours",
                "Take a 30-60 minute lunch break",
                "Use break time for movement or mindfulness",
                "Set reminders to step away from work"
            ],
            estimatedTimeSaved: 0, // Improves quality, not necessarily time
            confidence: 0.75
        )
    }

    private func createDeadlineOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        let impact: OptimizationSuggestion.Impact = metrics.overdueTasks > 3 ? .critical : .high

        return OptimizationSuggestion(
            type: .deadlineRebalancing,
            title: "Address Overdue Tasks",
            description: "You have \(metrics.overdueTasks) overdue tasks. Let's rebalance your schedule to catch up.",
            impact: impact,
            actionItems: [
                "Review and prioritize all overdue tasks",
                "Break large overdue tasks into smaller chunks",
                "Schedule dedicated catch-up sessions",
                "Consider delegating or eliminating low-priority overdue items"
            ],
            estimatedTimeSaved: 5400, // 1.5 hours saved from better prioritization
            confidence: 0.9
        )
    }

    private func createWorkloadOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        let weeklyHours = Int(metrics.weeklyWorkload / 3600)

        return OptimizationSuggestion(
            type: .timeBlocking,
            title: "Manage Workload Balance",
            description: "You're working \(weeklyHours) hours per week. Let's optimize your schedule for better work-life balance.",
            impact: .high,
            actionItems: [
                "Set clear boundaries for work hours",
                "Identify tasks that can be eliminated or delegated",
                "Use time blocking to create more efficient work sessions",
                "Schedule buffer time for unexpected tasks"
            ],
            estimatedTimeSaved: 7200, // 2 hours saved from efficiency
            confidence: 0.8
        )
    }

    private func createEnergyOptimization(_ metrics: ProductivityMetrics) -> OptimizationSuggestion {
        return OptimizationSuggestion(
            type: .energyOptimization,
            title: "Optimize Energy Management",
            description: "Align your task types with your natural energy patterns for maximum efficiency.",
            impact: .medium,
            actionItems: [
                "Schedule creative tasks during your peak energy hours",
                "Handle routine tasks when energy is lower",
                "Plan demanding meetings when you're most alert",
                "Use low-energy times for planning and organizing"
            ],
            estimatedTimeSaved: 1800, // 30 minutes from better energy alignment
            confidence: 0.7
        )
    }

    private func calculateAverageTaskDuration(from tasks: [Task]) -> TimeInterval {
        let tasksWithDuration = tasks.compactMap { task -> TimeInterval? in
            guard let start = task.startTime, let end = task.endTime else { return nil }
            return end.timeIntervalSince(start)
        }

        return tasksWithDuration.isEmpty ? 3600 : tasksWithDuration.reduce(0, +) / Double(tasksWithDuration.count)
    }

    private func calculatePeakProductivityHours(from tasks: [Task]) -> [Int] {
        var hourlyCompletions: [Int: Int] = [:]

        for task in tasks {
            if let completionTime = task.startTime ?? task.endTime {
                let hour = Calendar.current.component(.hour, from: completionTime)
                hourlyCompletions[hour, default: 0] += 1
            }
        }

        let sortedHours = hourlyCompletions.sorted { $0.value > $1.value }
        return Array(sortedHours.prefix(3).map { $0.key })
    }

    private func analyzeCommonTaskTypes(from tasks: [Task]) -> [String: Int] {
        var taskTypes: [String: Int] = [:]

        for task in tasks {
            guard let title = task.title else { continue }
            let type = categorizeTask(title)
            taskTypes[type, default: 0] += 1
        }

        return taskTypes
    }

    private func categorizeTask(_ title: String) -> String {
        let lowercaseTitle = title.lowercased()

        if lowercaseTitle.contains("meeting") || lowercaseTitle.contains("call") {
            return "Meetings"
        } else if lowercaseTitle.contains("email") || lowercaseTitle.contains("message") {
            return "Communication"
        } else if lowercaseTitle.contains("review") || lowercaseTitle.contains("check") {
            return "Review"
        } else if lowercaseTitle.contains("write") || lowercaseTitle.contains("document") {
            return "Writing"
        } else if lowercaseTitle.contains("plan") || lowercaseTitle.contains("strategy") {
            return "Planning"
        } else if lowercaseTitle.contains("develop") || lowercaseTitle.contains("code") {
            return "Development"
        } else {
            return "General"
        }
    }

    private func calculateAverageBreakTime(from tasks: [Task]) -> TimeInterval {
        // Calculate gaps between consecutive tasks as potential break time
        let sortedTasks = tasks.compactMap { task -> (start: Date, end: Date)? in
            guard let start = task.startTime, let end = task.endTime else { return nil }
            return (start: start, end: end)
        }.sorted { $0.start < $1.start }

        var totalBreakTime: TimeInterval = 0
        var breakCount = 0

        for i in 0..<(sortedTasks.count - 1) {
            let currentEnd = sortedTasks[i].end
            let nextStart = sortedTasks[i + 1].start

            let gap = nextStart.timeIntervalSince(currentEnd)
            if gap > 300 && gap < 7200 { // Between 5 minutes and 2 hours
                totalBreakTime += gap
                breakCount += 1
            }
        }

        return breakCount > 0 ? totalBreakTime / Double(breakCount) : 900 // Default 15 minutes
    }

    private func calculateTotalWorkload(from tasks: [Task]) -> TimeInterval {
        return tasks.compactMap { task -> TimeInterval? in
            guard let start = task.startTime, let end = task.endTime else { return nil }
            return end.timeIntervalSince(start)
        }.reduce(0, +)
    }

    private func isTaskOverdue(_ task: Task) -> Bool {
        guard let endTime = task.endTime else { return false }
        return !task.isCompleted && endTime < Date()
    }

    private func getTasksInRange(_ dateRange: DateInterval) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                       dateRange.start as NSDate,
                                       dateRange.end as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tasks in range: \(error)")
            return []
        }
    }

    func applyOptimizationSuggestion(_ suggestion: OptimizationSuggestion) async {
        // Implementation would depend on the specific optimization type
        switch suggestion.type {
        case .timeBlocking:
            await implementTimeBlocking()
        case .taskBatching:
            await implementTaskBatching()
        case .energyOptimization:
            await implementEnergyOptimization()
        case .deadlineRebalancing:
            await implementDeadlineRebalancing()
        case .focusTimeProtection:
            await implementFocusTimeProtection()
        case .breakScheduling:
            await implementBreakScheduling()
        }
    }

    private func implementTimeBlocking() async {
        // Create focused work blocks in the calendar
    }

    private func implementTaskBatching() async {
        // Group similar tasks together
    }

    private func implementEnergyOptimization() async {
        // Reschedule tasks based on energy levels
    }

    private func implementDeadlineRebalancing() async {
        // Redistribute overdue tasks
    }

    private func implementFocusTimeProtection() async {
        // Block calendar for deep work
    }

    private func implementBreakScheduling() async {
        // Add break events to calendar
    }
}