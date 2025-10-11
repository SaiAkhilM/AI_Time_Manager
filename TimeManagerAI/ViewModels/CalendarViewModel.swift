import Foundation
import CoreData
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var events: [Event] = []
    @Published var selectedDate = Date()
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    let context: NSManagedObjectContext
    private let notificationService = NotificationService()
    private var liveActivityService: Any?
    private let intelligentSchedulingService: IntelligentSchedulingService
    private let contextAwareOptimizationService: ContextAwareOptimizationService
    private let smartDeadlineManager: SmartDeadlineManager
    private let predictiveTimeEstimationService: PredictiveTimeEstimationService // LiveActivityService for iOS 16.1+

    init(context: NSManagedObjectContext) {
        self.context = context
        self.intelligentSchedulingService = IntelligentSchedulingService(context: context)
        self.contextAwareOptimizationService = ContextAwareOptimizationService(context: context)
        self.smartDeadlineManager = SmartDeadlineManager(context: context)
        self.predictiveTimeEstimationService = PredictiveTimeEstimationService(context: context)

        if #available(iOS 16.1, *) {
            liveActivityService = LiveActivityService()
        }

        loadDataForSelectedDate()
        setupDateChangeObserver()
        setupNotificationObservers()
        setupNotificationPermissions()
    }

    private func setupDateChangeObserver() {
        $selectedDate
            .sink { [weak self] _ in
                self?.loadDataForSelectedDate()
            }
            .store(in: &cancellables)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .taskCreated)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.refreshData()

                    if let task = notification.object as? Task {
                        self?.notificationService.scheduleAllNotificationsForTask(task)

                        if #available(iOS 16.1, *),
                           let service = self?.liveActivityService as? LiveActivityService {
                            service.startTaskActivity(for: task)
                        }
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .taskUpdated)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.refreshData()

                    if let task = notification.object as? Task {
                        self?.notificationService.cancelNotifications(for: task)
                        if !task.isCompleted {
                            self?.notificationService.scheduleAllNotificationsForTask(task)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func setupNotificationPermissions() {
        Task {
            await notificationService.requestNotificationPermission()
        }
    }

    func loadDataForSelectedDate() {
        loadTasks()
        loadEvents()
    }

    private func loadTasks() {
        let request: NSFetchRequest<Task> = Task.fetchRequest()

        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.startTime, ascending: true)]

        do {
            tasks = try context.fetch(request)
        } catch {
            print("Failed to fetch tasks: \(error)")
            errorMessage = "Failed to load tasks"
            tasks = []
        }
    }

    private func loadEvents() {
        let request: NSFetchRequest<Event> = Event.fetchRequest()

        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.startTime, ascending: true)]

        do {
            events = try context.fetch(request)
        } catch {
            print("Failed to fetch events: \(error)")
            errorMessage = "Failed to load events"
            events = []
        }
    }

    func loadWeekData(for date: Date) -> [Date: [Task]] {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start else {
            return [:]
        }

        var weekData: [Date: [Task]] = [:]

        for i in 0..<7 {
            if let day = Calendar.current.date(byAdding: .day, value: i, to: weekStart) {
                let dayTasks = getTasksForDate(day)
                weekData[day] = dayTasks
            }
        }

        return weekData
    }

    func getTasksForDate(_ date: Date) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.startTime, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tasks for date \(date): \(error)")
            return []
        }
    }

    func createTask(title: String, description: String? = nil, priority: Task.Priority, date: Date, startTime: Date? = nil, endTime: Date? = nil) {
        let task = Task.create(
            in: context,
            title: title,
            description: description,
            priority: priority,
            startTime: startTime,
            endTime: endTime,
            date: date
        )

        saveContext()
        loadDataForSelectedDate()
    }

    func createEvent(title: String, description: String? = nil, startTime: Date, endTime: Date, location: String? = nil) {
        let event = Event.create(
            in: context,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            location: location
        )

        saveContext()
        loadDataForSelectedDate()
    }

    func updateTask(_ task: Task, title: String? = nil, priority: Task.Priority? = nil, startTime: Date? = nil, endTime: Date? = nil) {
        if let title = title {
            task.title = title
        }
        if let priority = priority {
            task.priorityEnum = priority
        }
        if let startTime = startTime {
            task.startTime = startTime
        }
        if let endTime = endTime {
            task.endTime = endTime
        }

        task.updateTimestamp()
        saveContext()
        loadDataForSelectedDate()
    }

    func deleteTask(_ task: Task) {
        context.delete(task)
        saveContext()
        loadDataForSelectedDate()
    }

    func completeTask(_ task: Task) {
        task.isCompleted = true
        task.updateTimestamp()
        saveContext()
        loadDataForSelectedDate()
    }

    func getUnscheduledTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "date == nil AND isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch unscheduled tasks: \(error)")
            return []
        }
    }

    func scheduleTask(_ task: Task, to date: Date, startTime: Date? = nil, endTime: Date? = nil) {
        task.date = date
        task.startTime = startTime
        task.endTime = endTime
        task.updateTimestamp()

        saveContext()
        loadDataForSelectedDate()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
            errorMessage = "Failed to save changes"
        }
    }

    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func goToToday() {
        selectedDate = Date()
    }

    func refreshData() {
        loadDataForSelectedDate()
    }

    func getSchedulingSuggestions(for task: Task) async -> [SchedulingSuggestion] {
        return await intelligentSchedulingService.generateSchedulingSuggestions(for: task)
    }

    func optimizeSchedule(for date: Date) async -> [SchedulingSuggestion] {
        return await intelligentSchedulingService.optimizeExistingSchedule(for: date)
    }

    func getOptimizationSuggestions() async {
        await contextAwareOptimizationService.analyzeAndOptimizeSchedule()
    }

    func analyzeDeadlines() async {
        await smartDeadlineManager.analyzeDeadlines()
    }

    func estimateTaskDuration(title: String, description: String? = nil, priority: Task.Priority = .medium) async -> TimeEstimate {
        return await predictiveTimeEstimationService.estimateTaskDuration(
            title: title,
            description: description,
            priority: priority
        )
    }

    func createTaskWithAI(title: String, description: String? = nil, priority: Task.Priority, date: Date) async {
        let estimate = await estimateTaskDuration(title: title, description: description, priority: priority)
        let suggestions = await getSchedulingSuggestionsForNewTask(title: title, estimatedDuration: estimate.estimatedDuration, date: date)

        if let bestSuggestion = suggestions.first {
            createTask(
                title: title,
                description: description,
                priority: priority,
                date: date,
                startTime: bestSuggestion.suggestedStartTime,
                endTime: bestSuggestion.suggestedEndTime
            )
        } else {
            createTask(
                title: title,
                description: description,
                priority: priority,
                date: date,
                startTime: nil,
                endTime: Date().addingTimeInterval(estimate.estimatedDuration)
            )
        }
    }

    private func getSchedulingSuggestionsForNewTask(title: String, estimatedDuration: TimeInterval, date: Date) async -> [SchedulingSuggestion] {
        let tempTask = Task(context: context)
        tempTask.title = title
        tempTask.id = UUID()
        tempTask.date = date

        let suggestions = await intelligentSchedulingService.generateSchedulingSuggestions(for: tempTask)
        context.delete(tempTask)
        return suggestions
    }

    func updateTaskCompletionTime(_ task: Task, actualDuration: TimeInterval) {
        guard let title = task.title else { return }

        let estimatedDuration = task.endTime?.timeIntervalSince(task.startTime ?? Date()) ?? 3600
        predictiveTimeEstimationService.updateEstimationAccuracy(
            actualDuration: actualDuration,
            estimatedDuration: estimatedDuration,
            taskTitle: title
        )
    }
}