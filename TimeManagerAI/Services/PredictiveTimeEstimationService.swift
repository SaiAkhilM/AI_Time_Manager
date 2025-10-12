import Foundation
import CoreData
import Combine

struct TimeEstimate {
    let taskId: UUID?
    let estimatedDuration: TimeInterval
    let confidence: Double
    let factors: [EstimationFactor]
    let historicalBasis: HistoricalBasis
    let adjustmentReasons: [String]

    var formattedDuration: String {
        let hours = Int(estimatedDuration) / 3600
        let minutes = (Int(estimatedDuration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct EstimationFactor {
    let name: String
    let impact: Double // -1.0 to 1.0
    let description: String

    static let complexityMultiplier = EstimationFactor(
        name: "Task Complexity",
        impact: 0.0,
        description: "Based on keywords and description analysis"
    )

    static let historicalAccuracy = EstimationFactor(
        name: "Historical Accuracy",
        impact: 0.0,
        description: "Your past estimation accuracy for similar tasks"
    )

    static let currentWorkload = EstimationFactor(
        name: "Current Workload",
        impact: 0.0,
        description: "Impact of your current schedule density"
    )

    static let timeOfDay = EstimationFactor(
        name: "Time of Day",
        impact: 0.0,
        description: "Your productivity patterns throughout the day"
    )

    static let taskType = EstimationFactor(
        name: "Task Type",
        impact: 0.0,
        description: "Category-specific historical performance"
    )
}

struct HistoricalBasis {
    let similarTasksCount: Int
    let averageDuration: TimeInterval
    let accuracyRate: Double
    let lastUpdated: Date
}

struct ProductivityPattern {
    let hour: Int
    let averageEfficiency: Double
    let taskCompletionRate: Double
    let typicalTaskDuration: TimeInterval
}

class PredictiveTimeEstimationService: ObservableObject {
    @Published var recentEstimates: [TimeEstimate] = []
    @Published var productivityPatterns: [ProductivityPattern] = []
    @Published var estimationAccuracy: Double = 0.75
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    // ML-like estimation models
    private var taskTypeBaselines: [String: TimeInterval] = [:]
    private var userEfficiencyFactors: [String: Double] = [:]
    private var historicalAccuracy: [String: Double] = [:]

    init(context: NSManagedObjectContext) {
        self.context = context
        loadHistoricalPatterns()
    }

    func estimateTaskDuration(title: String, description: String? = nil, priority: TaskEntity.Priority = .medium, scheduledTime: Date? = nil) async -> TimeEstimate {
        isAnalyzing = true
        defer { isAnalyzing = false }

        // 1. Base estimation from task analysis
        let baseEstimate = analyzeTaskContent(title: title, description: description)

        // 2. Apply historical learning
        let historicalAdjustment = applyHistoricalLearning(for: title, baseEstimate: baseEstimate)

        // 3. Apply contextual factors
        let contextualFactors = analyzeContextualFactors(
            priority: priority,
            scheduledTime: scheduledTime,
            taskTitle: title
        )

        // 4. Calculate final estimate
        let finalEstimate = applyFactors(
            baseEstimate: historicalAdjustment.estimatedDuration,
            factors: contextualFactors
        )

        // 5. Determine confidence level
        let confidence = calculateConfidence(
            historicalBasis: historicalAdjustment.historicalBasis,
            factors: contextualFactors
        )

        let estimate = TimeEstimate(
            taskId: nil,
            estimatedDuration: finalEstimate,
            confidence: confidence,
            factors: contextualFactors,
            historicalBasis: historicalAdjustment.historicalBasis,
            adjustmentReasons: generateAdjustmentReasons(contextualFactors)
        )

        DispatchQueue.main.async {
            self.recentEstimates.insert(estimate, at: 0)
            if self.recentEstimates.count > 10 {
                self.recentEstimates.removeLast()
            }
        }

        return estimate
    }

    func estimateExistingTask(_ task: TaskEntity) async -> TimeEstimate {
        let title = task.title ?? "Task" ?? "Untitled Task"
        let description = task.taskDescription
        let priority = task.priorityEnum
        let scheduledTime = task.startTime

        return await estimateTaskDuration(
            title: title,
            description: description,
            priority: priority,
            scheduledTime: scheduledTime
        )
    }

    func updateEstimationAccuracy(actualDuration: TimeInterval, estimatedDuration: TimeInterval, taskTitle: String) {
        let accuracy = 1.0 - abs(actualDuration - estimatedDuration) / max(actualDuration, estimatedDuration)
        let taskType = categorizeTask(taskTitle)

        // Update historical accuracy
        let currentAccuracy = historicalAccuracy[taskType] ?? 0.75
        historicalAccuracy[taskType] = (currentAccuracy * 0.8) + (accuracy * 0.2) // Weighted average

        // Update overall estimation accuracy
        let overallAccuracy = historicalAccuracy.values.reduce(0, +) / Double(historicalAccuracy.count)
        DispatchQueue.main.async {
            self.estimationAccuracy = overallAccuracy
        }

        // Learn from this data point
        learnFromActualDuration(taskTitle: taskTitle, actualDuration: actualDuration, estimatedDuration: estimatedDuration)
    }

    private func loadHistoricalPatterns() {
        // Load productivity patterns from completed tasks
        Task {
            await analyzeHistoricalData()
        }
    }

    private func analyzeHistoricalData() async {
        let completedTasks = await fetchCompletedTasks()

        // Analyze productivity patterns by hour
        var hourlyPatterns: [Int: [TimeInterval]] = [:]
        var hourlyCompletions: [Int: Int] = [:]

        for task in completedTasks {
            guard let start = task.startTime,
                  let end = task.endTime else { continue }

            let hour = Calendar.current.component(.hour, from: start)
            let duration = end.timeIntervalSince(start)

            hourlyPatterns[hour, default: []].append(duration)
            hourlyCompletions[hour, default: 0] += 1
        }

        // Calculate patterns
        var patterns: [ProductivityPattern] = []
        for hour in 8...20 { // Working hours
            let durations = hourlyPatterns[hour] ?? []
            let avgDuration = durations.isEmpty ? 3600 : durations.reduce(0, +) / Double(durations.count)
            let completions = hourlyCompletions[hour] ?? 0

            // Calculate efficiency based on task completion rate and duration accuracy
            let efficiency = calculateHourlyEfficiency(hour: hour, from: completedTasks)

            patterns.append(ProductivityPattern(
                hour: hour,
                averageEfficiency: efficiency,
                taskCompletionRate: Double(completions) / Double(max(1, completedTasks.count)),
                typicalTaskDuration: avgDuration
            ))
        }

        DispatchQueue.main.async {
            self.productivityPatterns = patterns
        }

        // Update task type baselines
        updateTaskTypeBaselines(from: completedTasks)
    }

    private func calculateHourlyEfficiency(hour: Int, from tasks: [TaskEntity]) -> Double {
        let hourTasks = tasks.filter { task in
            guard let start = task.startTime else { return false }
            return Calendar.current.component(.hour, from: start) == hour
        }

        if hourTasks.isEmpty { return 0.75 } // Default efficiency

        let completionRate = Double(hourTasks.filter { $0.isCompleted }.count) / Double(hourTasks.count)
        return completionRate
    }

    private func updateTaskTypeBaselines(from tasks: [TaskEntity]) -> Void {
        var typeGroups: [String: [TimeInterval]] = [:]

        for task in tasks {
            let title = task.title ?? "Task"
            guard let start = task.startTime,
                  let end = task.endTime else { continue }

            let taskType = categorizeTask(title)
            let duration = end.timeIntervalSince(start)
            typeGroups[taskType, default: []].append(duration)
        }

        for (type, durations) in typeGroups {
            let avgDuration = durations.reduce(0, +) / Double(durations.count)
            taskTypeBaselines[type] = avgDuration
        }
    }

    private func analyzeTaskContent(title: String, description: String?) -> TimeInterval {
        let taskType = categorizeTask(title)
        let baselineForType = taskTypeBaselines[taskType] ?? getDefaultDurationForType(taskType)

        // Analyze complexity indicators
        let complexityMultiplier = analyzeComplexity(title: title, description: description)

        return baselineForType * complexityMultiplier
    }

    private func categorizeTask(_ title: String) -> String {
        let lowercaseTitle = title.lowercased()

        let categories = [
            "meeting": ["meeting", "call", "interview", "discussion"],
            "communication": ["email", "message", "respond", "reply"],
            "planning": ["plan", "strategy", "brainstorm", "design"],
            "development": ["code", "develop", "implement", "build", "program"],
            "review": ["review", "check", "analyze", "examine"],
            "writing": ["write", "document", "report", "article"],
            "research": ["research", "study", "learn", "investigate"],
            "administrative": ["admin", "organize", "file", "update"]
        ]

        for (category, keywords) in categories {
            if keywords.contains(where: lowercaseTitle.contains) {
                return category
            }
        }

        return "general"
    }

    private func getDefaultDurationForType(_ type: String) -> TimeInterval {
        switch type {
        case "meeting": return 3600 // 1 hour
        case "communication": return 1800 // 30 minutes
        case "planning": return 5400 // 1.5 hours
        case "development": return 7200 // 2 hours
        case "review": return 2700 // 45 minutes
        case "writing": return 5400 // 1.5 hours
        case "research": return 7200 // 2 hours
        case "administrative": return 1800 // 30 minutes
        default: return 3600 // 1 hour
        }
    }

    private func analyzeComplexity(title: String, description: String?) -> Double {
        var complexityScore = 1.0

        let lowercaseTitle = title.lowercased()

        // Complexity indicators
        let highComplexityKeywords = ["complex", "difficult", "challenging", "comprehensive", "detailed", "full", "complete"]
        let mediumComplexityKeywords = ["review", "update", "improve", "enhance", "modify"]
        let lowComplexityKeywords = ["quick", "simple", "brief", "short", "easy"]

        if highComplexityKeywords.contains(where: lowercaseTitle.contains) {
            complexityScore *= 1.4
        } else if mediumComplexityKeywords.contains(where: lowercaseTitle.contains) {
            complexityScore *= 1.1
        } else if lowComplexityKeywords.contains(where: lowercaseTitle.contains) {
            complexityScore *= 0.7
        }

        // Description analysis
        if let description = description, !description.isEmpty {
            let wordCount = description.components(separatedBy: .whitespacesAndNewlines).count
            if wordCount > 50 {
                complexityScore *= 1.2
            } else if wordCount > 20 {
                complexityScore *= 1.1
            }
        }

        return max(0.5, min(2.0, complexityScore))
    }

    private func applyHistoricalLearning(for title: String, baseEstimate: TimeInterval) -> TimeEstimate {
        let taskType = categorizeTask(title)
        let similarTasks = findSimilarTasks(title: title, taskType: taskType)

        if similarTasks.isEmpty {
            return TimeEstimate(
                taskId: nil,
                estimatedDuration: baseEstimate,
                confidence: 0.6,
                factors: [],
                historicalBasis: HistoricalBasis(
                    similarTasksCount: 0,
                    averageDuration: baseEstimate,
                    accuracyRate: 0.75,
                    lastUpdated: Date()
                ),
                adjustmentReasons: []
            )
        }

        let avgHistoricalDuration = similarTasks.compactMap { task -> TimeInterval? in
            guard let start = task.startTime, let end = task.endTime else { return nil }
            return end.timeIntervalSince(start)
        }.reduce(0, +) / Double(similarTasks.count)

        // Blend base estimate with historical data
        let confidence = min(0.95, 0.5 + Double(similarTasks.count) * 0.1)
        let blendedEstimate = (baseEstimate * (1 - confidence)) + (avgHistoricalDuration * confidence)

        return TimeEstimate(
            taskId: nil,
            estimatedDuration: blendedEstimate,
            confidence: confidence,
            factors: [],
            historicalBasis: HistoricalBasis(
                similarTasksCount: similarTasks.count,
                averageDuration: avgHistoricalDuration,
                accuracyRate: historicalAccuracy[taskType] ?? 0.75,
                lastUpdated: Date()
            ),
            adjustmentReasons: []
        )
    }

    private func analyzeContextualFactors(priority: TaskEntity.Priority, scheduledTime: Date?, taskTitle: String) -> [EstimationFactor] {
        var factors: [EstimationFactor] = []

        // Priority factor
        let priorityImpact: Double
        switch priority {
        case .high: priorityImpact = 0.1 // High priority tasks might take longer due to perfectionism
        case .medium: priorityImpact = 0.0
        case .event: priorityImpact = -0.1 // Event tasks might be done more quickly
        case .none: priorityImpact = 0.0
        }

        factors.append(EstimationFactor(
            name: "Task Priority",
            impact: priorityImpact,
            description: "Priority level impact on duration"
        ))

        // Time of day factor
        if let scheduledTime = scheduledTime {
            let hour = Calendar.current.component(.hour, from: scheduledTime)
            let pattern = productivityPatterns.first { $0.hour == hour }
            let efficiencyImpact = (pattern?.averageEfficiency ?? 0.75) - 0.75

            factors.append(EstimationFactor(
                name: "Time of Day",
                impact: -efficiencyImpact * 0.3, // Higher efficiency = shorter duration
                description: "Your productivity at \(hour):00"
            ))
        }

        // Current workload factor
        let currentWorkload = calculateCurrentWorkload()
        let workloadImpact = min(0.3, max(-0.2, (currentWorkload - 0.7) * 0.5))

        factors.append(EstimationFactor(
            name: "Current Workload",
            impact: workloadImpact,
            description: "Impact of your current schedule density"
        ))

        return factors
    }

    private func applyFactors(baseEstimate: TimeInterval, factors: [EstimationFactor]) -> TimeInterval {
        var adjustedEstimate = baseEstimate

        for factor in factors {
            adjustedEstimate *= (1.0 + factor.impact)
        }

        // Ensure reasonable bounds
        return max(900, min(14400, adjustedEstimate)) // Between 15 minutes and 4 hours
    }

    private func calculateConfidence(historicalBasis: HistoricalBasis, factors: [EstimationFactor]) -> Double {
        var confidence = 0.5 // Base confidence

        // Historical data confidence
        if historicalBasis.similarTasksCount > 0 {
            confidence += min(0.3, Double(historicalBasis.similarTasksCount) * 0.05)
        }

        // Accuracy rate confidence
        confidence += (historicalBasis.accuracyRate - 0.5) * 0.4

        // Factor reliability
        let factorConfidence = factors.map { abs($0.impact) < 0.2 ? 0.1 : 0.05 }.reduce(0, +)
        confidence += factorConfidence

        return max(0.1, min(0.95, confidence))
    }

    private func generateAdjustmentReasons(_ factors: [EstimationFactor]) -> [String] {
        return factors.compactMap { factor in
            if abs(factor.impact) > 0.1 {
                let direction = factor.impact > 0 ? "increased" : "decreased"
                return "Duration \(direction) due to \(factor.name.lowercased())"
            }
            return nil
        }
    }

    private func calculateCurrentWorkload() -> Double {
        let now = Date()
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        let upcomingTasks = getTasksInDateRange(start: now, end: endOfWeek)
        let totalPlannedTime = upcomingTasks.compactMap { task -> TimeInterval? in
            guard let start = task.startTime, let end = task.endTime else { return nil }
            return end.timeIntervalSince(start)
        }.reduce(0, +)

        let availableWorkTime: TimeInterval = 7 * 8 * 3600 // 7 days * 8 hours
        return totalPlannedTime / availableWorkTime
    }

    private func findSimilarTasks(title: String, taskType: String) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES AND startTime != nil AND endTime != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]
        request.fetchLimit = 20

        do {
            let completedTasks = try context.fetch(request)
            return completedTasks.filter { task in
                let taskTitle = task.title ?? "Task"
                let similarity = calculateTaskSimilarity(title, taskTitle)
                return similarity > 0.4 || categorizeTask(taskTitle) == taskType
            }
        } catch {
            print("Failed to fetch similar tasks: \(error)")
            return []
        }
    }

    private func calculateTaskSimilarity(_ title1: String, _ title2: String) -> Double {
        let words1 = Set(title1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(title2.lowercased().components(separatedBy: .whitespacesAndNewlines))

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    private func learnFromActualDuration(taskTitle: String, actualDuration: TimeInterval, estimatedDuration: TimeInterval) {
        let taskType = categorizeTask(taskTitle)
        let accuracy = 1.0 - abs(actualDuration - estimatedDuration) / max(actualDuration, estimatedDuration)

        // Update efficiency factors
        let currentFactor = userEfficiencyFactors[taskType] ?? 1.0
        let learningRate = 0.1
        let newFactor = currentFactor * (1 - learningRate) + (actualDuration / estimatedDuration) * learningRate
        userEfficiencyFactors[taskType] = newFactor

        // Update task type baselines
        let currentBaseline = taskTypeBaselines[taskType] ?? actualDuration
        taskTypeBaselines[taskType] = currentBaseline * 0.9 + actualDuration * 0.1
    }

    private func fetchCompletedTasks() async -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES AND startTime != nil AND endTime != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch completed tasks: \(error)")
            return []
        }
    }

    private func getTasksInDateRange(start: Date, end: Date) -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tasks in date range: \(error)")
            return []
        }
    }
}