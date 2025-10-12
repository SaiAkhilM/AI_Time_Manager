import Foundation
import CoreData
import Combine

struct DeadlineAnalysis {
    let taskId: UUID
    let currentDeadline: Date
    let suggestedDeadline: Date?
    let riskLevel: RiskLevel
    let workloadPressure: Double
    let dependencies: [UUID]
    let recommendations: [String]

    enum RiskLevel {
        case low, medium, high, critical

        var color: String {
            switch self {
            case .low: return "systemGreen"
            case .medium: return "systemYellow"
            case .high: return "systemOrange"
            case .critical: return "systemRed"
            }
        }

        var description: String {
            switch self {
            case .low: return "On track"
            case .medium: return "Monitor closely"
            case .high: return "Action needed"
            case .critical: return "Urgent intervention"
            }
        }
    }
}

struct WorkloadForecast {
    let date: Date
    let plannedWorkload: TimeInterval
    let availableCapacity: TimeInterval
    let utilizationRate: Double
    let bottlenecks: [String]

    var isOverloaded: Bool {
        return utilizationRate > 0.9
    }

    var hasCapacity: Bool {
        return utilizationRate < 0.7
    }
}

struct DeadlineRecommendation {
    let id = UUID()
    let taskId: UUID
    let action: Action
    let reasoning: String
    let impact: Impact
    let urgency: Urgency

    enum Action {
        case extendDeadline(newDate: Date)
        case breakIntoSubtasks
        case adjustPriority(newPriority: TaskEntity.Priority)
        case reallocateResources
        case delegateTask
        case cancelTask
    }

    enum Impact {
        case minimal, moderate, significant, major
    }

    enum Urgency {
        case low, medium, high, immediate
    }
}

class SmartDeadlineManager: ObservableObject {
    @Published var deadlineAnalyses: [DeadlineAnalysis] = []
    @Published var workloadForecast: [WorkloadForecast] = []
    @Published var recommendations: [DeadlineRecommendation] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func analyzeDeadlines(for dateRange: DateInterval? = nil) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let range = dateRange ?? DateInterval(start: Date(), duration: 30 * 24 * 3600) // Next 30 days

        let analyses = await performDeadlineAnalysis(for: range)
        let forecast = await generateWorkloadForecast(for: range)
        let recommendations = await generateRecommendations(based: analyses, forecast: forecast)

        DispatchQueue.main.async {
            self.deadlineAnalyses = analyses
            self.workloadForecast = forecast
            self.recommendations = recommendations
        }
    }

    private func performDeadlineAnalysis(for dateRange: DateInterval) async -> [DeadlineAnalysis] {
        let tasks = getTasksWithDeadlines(in: dateRange)
        var analyses: [DeadlineAnalysis] = []

        for task in tasks {
            let taskId = task.id
            guard let deadline = task.endTime else { continue }

            let analysis = await analyzeTaskDeadline(task, deadline: deadline, in: dateRange)
            analyses.append(analysis)
        }

        return analyses.sorted { analysis1, analysis2 in
            let order: [DeadlineAnalysis.RiskLevel] = [.critical, .high, .medium, .low]
            let index1 = order.firstIndex(of: analysis1.riskLevel) ?? 999
            let index2 = order.firstIndex(of: analysis2.riskLevel) ?? 999
            return index1 < index2
        }
    }

    private func analyzeTaskDeadline(_ task: TaskEntity, deadline: Date, in dateRange: DateInterval) async -> DeadlineAnalysis {
        let now = Date()
        let timeToDeadline = deadline.timeIntervalSince(now)
        let estimatedDuration = estimateTaskDuration(task)

        // Calculate workload pressure
        let workloadPressure = calculateWorkloadPressure(for: task, in: dateRange)

        // Determine risk level
        let riskLevel = determineRiskLevel(
            timeToDeadline: timeToDeadline,
            estimatedDuration: estimatedDuration,
            workloadPressure: workloadPressure,
            task: task
        )

        // Find dependencies
        let dependencies = findTaskDependencies(task)

        // Generate recommendations
        let recommendations = generateTaskRecommendations(
            for: task,
            riskLevel: riskLevel,
            workloadPressure: workloadPressure
        )

        // Suggest new deadline if needed
        let suggestedDeadline = suggestOptimalDeadline(
            for: task,
            currentDeadline: deadline,
            estimatedDuration: estimatedDuration,
            workloadPressure: workloadPressure
        )

        return DeadlineAnalysis(
            taskId: task.id,
            currentDeadline: deadline,
            suggestedDeadline: suggestedDeadline,
            riskLevel: riskLevel,
            workloadPressure: workloadPressure,
            dependencies: dependencies,
            recommendations: recommendations
        )
    }

    private func calculateWorkloadPressure(for task: TaskEntity, in dateRange: DateInterval) -> Double {
        let allTasks = getTasksWithDeadlines(in: dateRange)
        let totalEstimatedWork = allTasks.compactMap { estimateTaskDuration($0) }.reduce(0, +)
        let availableTime = dateRange.duration

        let utilizationRate = totalEstimatedWork / availableTime

        // Factor in task priority
        let priorityMultiplier: Double
        switch task.priorityEnum {
        case .high: priorityMultiplier = 1.5
        case .medium: priorityMultiplier = 1.0
        case .event: priorityMultiplier = 0.7
        case .none: priorityMultiplier = 0.8
        }

        return min(1.0, utilizationRate * priorityMultiplier)
    }

    private func determineRiskLevel(timeToDeadline: TimeInterval, estimatedDuration: TimeInterval, workloadPressure: Double, task: TaskEntity) -> DeadlineAnalysis.RiskLevel {
        let daysToDeadline = timeToDeadline / (24 * 3600)
        let estimatedDays = estimatedDuration / (8 * 3600) // Assuming 8-hour work days

        // Critical: Not enough time even working full capacity
        if estimatedDays > daysToDeadline * 1.2 {
            return .critical
        }

        // High: Very tight timeline with high workload pressure
        if estimatedDays > daysToDeadline * 0.8 && workloadPressure > 0.8 {
            return .high
        }

        // Medium: Manageable but requires attention
        if estimatedDays > daysToDeadline * 0.6 || workloadPressure > 0.7 {
            return .medium
        }

        // Low: Comfortable timeline
        return .low
    }

    private func findTaskDependencies(_ task: TaskEntity) -> [UUID] {
        // In a real implementation, this would analyze task descriptions, titles, or explicit dependencies
        // For now, we'll return an empty array
        return []
    }

    private func generateTaskRecommendations(for task: TaskEntity, riskLevel: DeadlineAnalysis.RiskLevel, workloadPressure: Double) -> [String] {
        var recommendations: [String] = []

        switch riskLevel {
        case .critical:
            recommendations.append("Immediate action required - consider extending deadline")
            recommendations.append("Break task into smaller, manageable chunks")
            recommendations.append("Allocate additional resources or delegate portions")

        case .high:
            recommendations.append("Schedule focused work sessions for this task")
            recommendations.append("Eliminate non-essential activities this week")
            recommendations.append("Consider requesting deadline extension")

        case .medium:
            recommendations.append("Monitor progress closely")
            recommendations.append("Ensure adequate time is blocked in calendar")
            recommendations.append("Prepare contingency plan if delays occur")

        case .low:
            recommendations.append("Continue with current plan")
            recommendations.append("Use any extra time to improve quality")
        }

        if workloadPressure > 0.8 {
            recommendations.append("Current workload is high - consider redistributing tasks")
        }

        if task.priorityEnum == .high {
            recommendations.append("High priority task - ensure this gets primary focus")
        }

        return recommendations
    }

    private func suggestOptimalDeadline(for task: TaskEntity, currentDeadline: Date, estimatedDuration: TimeInterval, workloadPressure: Double) -> Date? {
        let now = Date()
        let timeToCurrentDeadline = currentDeadline.timeIntervalSince(now)
        let requiredBuffer = estimatedDuration * (1 + workloadPressure)

        // Only suggest new deadline if current one is problematic
        guard requiredBuffer > timeToCurrentDeadline else { return nil }

        // Calculate optimal deadline with appropriate buffer
        let optimalBuffer = estimatedDuration * 1.3 // 30% buffer
        return now.addingTimeInterval(optimalBuffer)
    }

    private func generateWorkloadForecast(for dateRange: DateInterval) async -> [WorkloadForecast] {
        var forecasts: [WorkloadForecast] = []
        let calendar = Calendar.current

        var currentDate = dateRange.start
        while currentDate < dateRange.end {
            let forecast = await generateDailyForecast(for: currentDate)
            forecasts.append(forecast)

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        return forecasts
    }

    private func generateDailyForecast(for date: Date) async -> WorkloadForecast {
        let tasks = getTasksForDate(date)
        let events = getEventsForDate(date)

        let plannedWorkload = tasks.compactMap { task -> TimeInterval? in
            guard let start = task.startTime, let end = task.endTime else { return nil }
            return end.timeIntervalSince(start)
        }.reduce(0, +)

        let eventTime = events.compactMap { event -> TimeInterval? in
            let start = event.startTime
            let end = event.endTime
            return end.timeIntervalSince(start)
        }.reduce(0, +)

        let totalScheduledTime = plannedWorkload + eventTime
        let availableWorkHours: TimeInterval = 8 * 3600 // 8 hours
        let utilizationRate = totalScheduledTime / availableWorkHours

        var bottlenecks: [String] = []
        if utilizationRate > 1.0 {
            bottlenecks.append("Overbooked schedule")
        }
        if tasks.filter({ $0.priorityEnum == .high }).count > 3 {
            bottlenecks.append("Too many high-priority tasks")
        }
        if totalScheduledTime > 6 * 3600 { // More than 6 hours of meetings/tasks
            bottlenecks.append("Limited time for deep work")
        }

        return WorkloadForecast(
            date: date,
            plannedWorkload: plannedWorkload,
            availableCapacity: availableWorkHours,
            utilizationRate: utilizationRate,
            bottlenecks: bottlenecks
        )
    }

    private func generateRecommendations(based analyses: [DeadlineAnalysis], forecast: [WorkloadForecast]) async -> [DeadlineRecommendation] {
        var recommendations: [DeadlineRecommendation] = []

        // Generate recommendations for critical and high-risk tasks
        for analysis in analyses {
            switch analysis.riskLevel {
            case .critical:
                recommendations.append(contentsOf: generateCriticalRecommendations(for: analysis))
            case .high:
                recommendations.append(contentsOf: generateHighRiskRecommendations(for: analysis))
            case .medium:
                recommendations.append(contentsOf: generateMediumRiskRecommendations(for: analysis))
            case .low:
                break // No specific recommendations needed
            }
        }

        // Generate recommendations based on workload forecast
        let overloadedDays = forecast.filter { $0.isOverloaded }
        if !overloadedDays.isEmpty {
            recommendations.append(generateWorkloadRecommendation(for: overloadedDays))
        }

        return recommendations.sorted { recommendation1, recommendation2 in
            if recommendation1.urgency != recommendation2.urgency {
                let urgencyOrder: [DeadlineRecommendation.Urgency] = [.immediate, .high, .medium, .low]
                let index1 = urgencyOrder.firstIndex(of: recommendation1.urgency) ?? 999
                let index2 = urgencyOrder.firstIndex(of: recommendation2.urgency) ?? 999
                return index1 < index2
            }
            let impactOrder: [DeadlineRecommendation.Impact] = [.major, .significant, .moderate, .minimal]
            let impactIndex1 = impactOrder.firstIndex(of: recommendation1.impact) ?? 999
            let impactIndex2 = impactOrder.firstIndex(of: recommendation2.impact) ?? 999
            return impactIndex1 < impactIndex2
        }
    }

    private func generateCriticalRecommendations(for analysis: DeadlineAnalysis) -> [DeadlineRecommendation] {
        var recommendations: [DeadlineRecommendation] = []

        if let suggestedDeadline = analysis.suggestedDeadline {
            recommendations.append(DeadlineRecommendation(
                taskId: analysis.taskId,
                action: .extendDeadline(newDate: suggestedDeadline),
                reasoning: "Current deadline is not achievable given the estimated work required and current workload.",
                impact: .major,
                urgency: .immediate
            ))
        }

        recommendations.append(DeadlineRecommendation(
            taskId: analysis.taskId,
            action: .breakIntoSubtasks,
            reasoning: "Breaking this large task into smaller chunks will make it more manageable and allow for better progress tracking.",
            impact: .significant,
            urgency: .immediate
        ))

        return recommendations
    }

    private func generateHighRiskRecommendations(for analysis: DeadlineAnalysis) -> [DeadlineRecommendation] {
        var recommendations: [DeadlineRecommendation] = []

        if analysis.workloadPressure > 0.8 {
            recommendations.append(DeadlineRecommendation(
                taskId: analysis.taskId,
                action: .adjustPriority(newPriority: .high),
                reasoning: "High workload pressure requires elevating this task's priority to ensure completion.",
                impact: .moderate,
                urgency: .high
            ))
        }

        if let suggestedDeadline = analysis.suggestedDeadline {
            recommendations.append(DeadlineRecommendation(
                taskId: analysis.taskId,
                action: .extendDeadline(newDate: suggestedDeadline),
                reasoning: "Timeline is tight. A modest extension would reduce risk significantly.",
                impact: .moderate,
                urgency: .medium
            ))
        }

        return recommendations
    }

    private func generateMediumRiskRecommendations(for analysis: DeadlineAnalysis) -> [DeadlineRecommendation] {
        return [DeadlineRecommendation(
            taskId: analysis.taskId,
            action: .reallocateResources,
            reasoning: "Consider allocating more focused time blocks to ensure timely completion.",
            impact: .minimal,
            urgency: .medium
        )]
    }

    private func generateWorkloadRecommendation(for overloadedDays: [WorkloadForecast]) -> DeadlineRecommendation {
        let taskId = UUID() // Placeholder for general workload recommendation

        return DeadlineRecommendation(
            taskId: taskId,
            action: .reallocateResources,
            reasoning: "You have \(overloadedDays.count) overloaded days in your forecast. Consider redistributing some tasks to maintain work-life balance.",
            impact: .significant,
            urgency: .medium
        )
    }

    private func estimateTaskDuration(_ task: TaskEntity) -> TimeInterval {
        if let start = task.startTime, let end = task.endTime {
            return end.timeIntervalSince(start)
        }

        // Use the intelligent scheduling service's estimation if available
        return 3600 // Default 1 hour
    }

    private func getTasksWithDeadlines(in dateRange: DateInterval) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "endTime >= %@ AND endTime <= %@ AND isCompleted == NO",
                                       dateRange.start as NSDate,
                                       dateRange.end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.endTime, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tasks with deadlines: \(error)")
            return []
        }
    }

    private func getTasksForDate(_ date: Date) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)

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
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch events for date: \(error)")
            return []
        }
    }
}