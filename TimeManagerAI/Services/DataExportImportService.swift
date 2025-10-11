import Foundation
import CoreData
import UniformTypeIdentifiers

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let tasks: [ExportTask]
    let events: [ExportEvent]
    let goals: [ExportGoal]
    let settings: ExportSettings

    struct ExportTask: Codable {
        let id: String
        let title: String
        let description: String?
        let priority: String
        let isCompleted: Bool
        let date: Date?
        let startTime: Date?
        let endTime: Date?
        let linkedURL: String?
        let createdAt: Date
        let updatedAt: Date
    }

    struct ExportEvent: Codable {
        let id: String
        let title: String
        let description: String?
        let startTime: Date
        let endTime: Date
        let location: String?
        let createdAt: Date
        let updatedAt: Date
    }

    struct ExportGoal: Codable {
        let id: String
        let title: String
        let description: String?
        let targetDate: Date?
        let isCompleted: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    struct ExportSettings: Codable {
        let userName: String?
        let workStartTime: Date?
        let workEndTime: Date?
        let sleepStartTime: Date?
        let sleepEndTime: Date?
        let enableTaskReminders: Bool
        let enableDeadlineWarnings: Bool
        let enableBreakReminders: Bool
        let bedtimeWarningMinutes: Int
        let focusSessionDuration: Int
        let shortBreakDuration: Int
        let longBreakDuration: Int
    }
}

enum ExportFormat {
    case json
    case csv
    case calendar // ICS format

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .calendar: return "ics"
        }
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .calendar: return "text/calendar"
        }
    }
}

enum ImportError: LocalizedError {
    case invalidFormat
    case corruptedData
    case incompatibleVersion
    case missingRequiredFields
    case duplicateData

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The file format is not supported or invalid."
        case .corruptedData:
            return "The file appears to be corrupted or incomplete."
        case .incompatibleVersion:
            return "This export was created with a newer version of the app."
        case .missingRequiredFields:
            return "The file is missing required data fields."
        case .duplicateData:
            return "Some items already exist and will be skipped."
        }
    }
}

class DataExportImportService: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var exportProgress: Double = 0.0
    @Published var importProgress: Double = 0.0
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Export Functions

    func exportData(format: ExportFormat) async throws -> URL {
        isExporting = true
        exportProgress = 0.0

        defer {
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportProgress = 0.0
            }
        }

        do {
            let exportData = try await prepareExportData()

            DispatchQueue.main.async {
                self.exportProgress = 0.7
            }

            let url = try await writeExportFile(data: exportData, format: format)

            DispatchQueue.main.async {
                self.exportProgress = 1.0
            }

            return url
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    private func prepareExportData() async throws -> ExportData {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let tasks = try self.fetchAllTasks()
                    let events = try self.fetchAllEvents()
                    let goals = try self.fetchAllGoals()
                    let settings = try self.fetchSettings()

                    DispatchQueue.main.async {
                        self.exportProgress = 0.5
                    }

                    let exportData = ExportData(
                        exportDate: Date(),
                        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                        tasks: tasks,
                        events: events,
                        goals: goals,
                        settings: settings
                    )

                    continuation.resume(returning: exportData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchAllTasks() throws -> [ExportData.ExportTask] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try context.fetch(request)

        return tasks.map { task in
            ExportData.ExportTask(
                id: task.id?.uuidString ?? UUID().uuidString,
                title: task.title ?? "",
                description: task.taskDescription,
                priority: task.priority ?? "medium",
                isCompleted: task.isCompleted,
                date: task.date,
                startTime: task.startTime,
                endTime: task.endTime,
                linkedURL: task.linkedURL,
                createdAt: task.createdAt ?? Date(),
                updatedAt: task.updatedAt ?? Date()
            )
        }
    }

    private func fetchAllEvents() throws -> [ExportData.ExportEvent] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        let events = try context.fetch(request)

        return events.map { event in
            ExportData.ExportEvent(
                id: event.id?.uuidString ?? UUID().uuidString,
                title: event.title ?? "",
                description: event.eventDescription,
                startTime: event.startTime ?? Date(),
                endTime: event.endTime ?? Date(),
                location: event.location,
                createdAt: event.createdAt ?? Date(),
                updatedAt: event.updatedAt ?? Date()
            )
        }
    }

    private func fetchAllGoals() throws -> [ExportData.ExportGoal] {
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        let goals = try context.fetch(request)

        return goals.map { goal in
            ExportData.ExportGoal(
                id: goal.id?.uuidString ?? UUID().uuidString,
                title: goal.title ?? "",
                description: goal.goalDescription,
                targetDate: goal.targetDate,
                isCompleted: goal.isCompleted,
                createdAt: goal.createdAt ?? Date(),
                updatedAt: goal.updatedAt ?? Date()
            )
        }
    }

    private func fetchSettings() throws -> ExportData.ExportSettings {
        let settings = Settings.getOrCreate(in: context)

        return ExportData.ExportSettings(
            userName: settings.userName,
            workStartTime: settings.workStartTime,
            workEndTime: settings.workEndTime,
            sleepStartTime: settings.sleepStartTime,
            sleepEndTime: settings.sleepEndTime,
            enableTaskReminders: settings.enableTaskReminders,
            enableDeadlineWarnings: settings.enableDeadlineWarnings,
            enableBreakReminders: settings.enableBreakReminders,
            bedtimeWarningMinutes: Int(settings.bedtimeWarningMinutes),
            focusSessionDuration: Int(settings.focusSessionDuration),
            shortBreakDuration: Int(settings.shortBreakDuration),
            longBreakDuration: Int(settings.longBreakDuration)
        )
    }

    private func writeExportFile(data: ExportData, format: ExportFormat) async throws -> URL {
        let fileName = "TimeManagerAI_Export_\(DateFormatter.fileNameFormatter.string(from: Date()))"
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension(format.fileExtension)

        switch format {
        case .json:
            try await writeJSONFile(data: data, to: fileURL)
        case .csv:
            try await writeCSVFile(data: data, to: fileURL)
        case .calendar:
            try await writeCalendarFile(data: data, to: fileURL)
        }

        return fileURL
    }

    private func writeJSONFile(data: ExportData, to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(data)
        try jsonData.write(to: url)
    }

    private func writeCSVFile(data: ExportData, to url: URL) async throws {
        var csvContent = ""

        // Tasks CSV
        csvContent += "TYPE,ID,TITLE,DESCRIPTION,PRIORITY,COMPLETED,DATE,START_TIME,END_TIME,URL,CREATED,UPDATED\n"

        for task in data.tasks {
            let row = [
                "TASK",
                task.id,
                escapCSV(task.title),
                escapCSV(task.description ?? ""),
                task.priority,
                task.isCompleted ? "TRUE" : "FALSE",
                task.date?.iso8601String ?? "",
                task.startTime?.iso8601String ?? "",
                task.endTime?.iso8601String ?? "",
                escapCSV(task.linkedURL ?? ""),
                task.createdAt.iso8601String,
                task.updatedAt.iso8601String
            ].joined(separator: ",")
            csvContent += row + "\n"
        }

        // Events CSV
        for event in data.events {
            let row = [
                "EVENT",
                event.id,
                escapCSV(event.title),
                escapCSV(event.description ?? ""),
                "",
                "FALSE",
                event.startTime.iso8601String,
                event.startTime.iso8601String,
                event.endTime.iso8601String,
                escapCSV(event.location ?? ""),
                event.createdAt.iso8601String,
                event.updatedAt.iso8601String
            ].joined(separator: ",")
            csvContent += row + "\n"
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeCalendarFile(data: ExportData, to url: URL) async throws {
        var icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Time Manager AI//Time Manager AI//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH

        """

        // Add tasks as events
        for task in data.tasks {
            if let startTime = task.startTime, let endTime = task.endTime {
                icsContent += """
                BEGIN:VEVENT
                UID:\(task.id)@timemanagerai.app
                DTSTART:\(formatDateForICS(startTime))
                DTEND:\(formatDateForICS(endTime))
                SUMMARY:\(task.title)
                DESCRIPTION:\(task.description?.replacingOccurrences(of: "\n", with: "\\n") ?? "")
                PRIORITY:\(task.priority == "high" ? "1" : task.priority == "medium" ? "5" : "9")
                STATUS:\(task.isCompleted ? "COMPLETED" : "CONFIRMED")
                CREATED:\(formatDateForICS(task.createdAt))
                LAST-MODIFIED:\(formatDateForICS(task.updatedAt))
                END:VEVENT

                """
            }
        }

        // Add events
        for event in data.events {
            icsContent += """
            BEGIN:VEVENT
            UID:\(event.id)@timemanagerai.app
            DTSTART:\(formatDateForICS(event.startTime))
            DTEND:\(formatDateForICS(event.endTime))
            SUMMARY:\(event.title)
            DESCRIPTION:\(event.description?.replacingOccurrences(of: "\n", with: "\\n") ?? "")
            LOCATION:\(event.location ?? "")
            CREATED:\(formatDateForICS(event.createdAt))
            LAST-MODIFIED:\(formatDateForICS(event.updatedAt))
            END:VEVENT

            """
        }

        icsContent += "END:VCALENDAR"

        try icsContent.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Import Functions

    func importData(from url: URL) async throws -> ImportResult {
        isImporting = true
        importProgress = 0.0

        defer {
            DispatchQueue.main.async {
                self.isImporting = false
                self.importProgress = 0.0
            }
        }

        do {
            let data = try Data(contentsOf: url)

            DispatchQueue.main.async {
                self.importProgress = 0.2
            }

            let exportData = try decodeImportData(data)

            DispatchQueue.main.async {
                self.importProgress = 0.4
            }

            let result = try await importExportData(exportData)

            DispatchQueue.main.async {
                self.importProgress = 1.0
            }

            return result
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    private func decodeImportData(_ data: Data) throws -> ExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ExportData.self, from: data)
        } catch {
            throw ImportError.invalidFormat
        }
    }

    private func importExportData(_ exportData: ExportData) async throws -> ImportResult {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    var result = ImportResult()

                    DispatchQueue.main.async {
                        self.importProgress = 0.6
                    }

                    // Import tasks
                    for taskData in exportData.tasks {
                        if self.taskExists(id: taskData.id) {
                            result.duplicateItems += 1
                            continue
                        }

                        let task = Task(context: self.context)
                        task.id = UUID(uuidString: taskData.id)
                        task.title = taskData.title
                        task.taskDescription = taskData.description
                        task.priority = taskData.priority
                        task.isCompleted = taskData.isCompleted
                        task.date = taskData.date
                        task.startTime = taskData.startTime
                        task.endTime = taskData.endTime
                        task.linkedURL = taskData.linkedURL
                        task.createdAt = taskData.createdAt
                        task.updatedAt = taskData.updatedAt

                        result.tasksImported += 1
                    }

                    DispatchQueue.main.async {
                        self.importProgress = 0.7
                    }

                    // Import events
                    for eventData in exportData.events {
                        if self.eventExists(id: eventData.id) {
                            result.duplicateItems += 1
                            continue
                        }

                        let event = Event(context: self.context)
                        event.id = UUID(uuidString: eventData.id)
                        event.title = eventData.title
                        event.eventDescription = eventData.description
                        event.startTime = eventData.startTime
                        event.endTime = eventData.endTime
                        event.location = eventData.location
                        event.createdAt = eventData.createdAt
                        event.updatedAt = eventData.updatedAt

                        result.eventsImported += 1
                    }

                    DispatchQueue.main.async {
                        self.importProgress = 0.8
                    }

                    // Import goals
                    for goalData in exportData.goals {
                        if self.goalExists(id: goalData.id) {
                            result.duplicateItems += 1
                            continue
                        }

                        let goal = Goal(context: self.context)
                        goal.id = UUID(uuidString: goalData.id)
                        goal.title = goalData.title
                        goal.goalDescription = goalData.description
                        goal.targetDate = goalData.targetDate
                        goal.isCompleted = goalData.isCompleted
                        goal.createdAt = goalData.createdAt
                        goal.updatedAt = goalData.updatedAt

                        result.goalsImported += 1
                    }

                    DispatchQueue.main.async {
                        self.importProgress = 0.9
                    }

                    // Save context
                    try self.context.save()

                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func taskExists(id: String) -> Bool {
        guard let uuid = UUID(uuidString: id) else { return false }
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1

        return (try? context.count(for: request)) ?? 0 > 0
    }

    private func eventExists(id: String) -> Bool {
        guard let uuid = UUID(uuidString: id) else { return false }
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1

        return (try? context.count(for: request)) ?? 0 > 0
    }

    private func goalExists(id: String) -> Bool {
        guard let uuid = UUID(uuidString: id) else { return false }
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1

        return (try? context.count(for: request)) ?? 0 > 0
    }

    // MARK: - Helper Functions

    private func escapCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    private func formatDateForICS(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
}

struct ImportResult {
    var tasksImported: Int = 0
    var eventsImported: Int = 0
    var goalsImported: Int = 0
    var duplicateItems: Int = 0

    var totalImported: Int {
        return tasksImported + eventsImported + goalsImported
    }

    var summary: String {
        var parts: [String] = []

        if tasksImported > 0 {
            parts.append("\(tasksImported) task\(tasksImported == 1 ? "" : "s")")
        }
        if eventsImported > 0 {
            parts.append("\(eventsImported) event\(eventsImported == 1 ? "" : "s")")
        }
        if goalsImported > 0 {
            parts.append("\(goalsImported) goal\(goalsImported == 1 ? "" : "s")")
        }

        let importedText = parts.joined(separator: ", ")
        var result = "Imported \(importedText)"

        if duplicateItems > 0 {
            result += ". Skipped \(duplicateItems) duplicate item\(duplicateItems == 1 ? "" : "s")"
        }

        return result
    }
}

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

extension Date {
    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
}