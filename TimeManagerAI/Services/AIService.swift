import Foundation
import CoreData
import Combine

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreated")
    static let taskUpdated = Notification.Name("taskUpdated")
}

class AIService: ObservableObject {
    @Published var errorMessage: String?

    private let systemPrompt = """
    You are the Time Manager AI assistant for a busy college student. Your role is to help manage their schedule, tasks, and time-blocking with zero planning overhead.

    CURRENT CONTEXT:
    - The user is a high-performing student/founder who wants to maximize execution time
    - Every 15 minutes should be productive and goal-oriented
    - You handle all scheduling complexity so they can focus on execution
    - Use time-blocking strategy with strict accountability

    CORE CAPABILITIES:
    1. Task Management: Add, modify, delete, and prioritize tasks
    2. Scheduling: Smart scheduling based on priorities and conflicts
    3. Calendar Management: View schedules, reschedule tasks, handle conflicts
    4. Goal Tracking: Help achieve weekly goals through time allocation
    5. Context Memory: Remember conversation context within the current week

    PRIORITY SYSTEM:
    - Red (high): Critical, urgent tasks - highest priority
    - Orange (medium): Important but flexible tasks
    - Yellow (events): Classes, meetings, appointments - usually immovable
    - No color (normal): Low priority, most flexible

    DECISION MAKING:
    - For obvious decisions: Auto-reschedule and ask confirmation
    - For unclear decisions: Ask questions and provide options
    - Always consider deadlines, priorities, and user's goals
    - Be concise and actionable in responses

    COMMUNICATION STYLE:
    - Direct and efficient
    - Action-oriented responses
    - Ask clarifying questions when needed
    - Confirm important changes before implementing

    Remember: You are like JARVIS to Tony Stark - intelligent, proactive, and focused on maximizing productivity.
    """

    private var conversationHistory: [ChatMessage] = []

    func sendMessage(_ message: String, context: NSManagedObjectContext) async -> String? {
        guard let openAIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !openAIKey.isEmpty else {
            errorMessage = "OpenAI API key not configured"
            return nil
        }

        conversationHistory.append(ChatMessage(role: "user", content: message))

        let currentContext = await buildCurrentContext(context: context)
        let enrichedSystemPrompt = systemPrompt + "\n\nCURRENT USER DATA:\n\(currentContext)"

        var messages: [[String: String]] = [
            ["role": "system", "content": enrichedSystemPrompt]
        ]

        messages.append(contentsOf: conversationHistory.map { ["role": $0.role, "content": $0.content] })

        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let chatResponse = try decoder.decode(ChatCompletionResponse.self, from: data)

                if let aiMessage = chatResponse.choices.first?.message.content {
                    conversationHistory.append(ChatMessage(role: "assistant", content: aiMessage))

                    await processAIResponse(aiMessage, context: context)

                    return aiMessage
                }
            } else {
                print("Chat completion failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
                errorMessage = "AI request failed"
                return nil
            }
        } catch {
            print("Chat completion error: \(error)")
            errorMessage = "AI error: \(error.localizedDescription)"
            return nil
        }

        return nil
    }

    private func buildCurrentContext(context: NSManagedObjectContext) async -> String {
        var contextString = ""

        let taskRequest: NSFetchRequest<Task> = Task.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                           Calendar.current.startOfDay(for: Date()) as NSDate,
                                           Calendar.current.date(byAdding: .day, value: 7, to: Date()) as NSDate? ?? Date() as NSDate)

        let eventRequest: NSFetchRequest<Event> = Event.fetchRequest()
        eventRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@",
                                            Calendar.current.startOfDay(for: Date()) as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 7, to: Date()) as NSDate? ?? Date() as NSDate)

        do {
            let tasks = try context.fetch(taskRequest)
            let events = try context.fetch(eventRequest)

            contextString += "CURRENT WEEK SCHEDULE:\n"

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMM d"

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            for i in 0..<7 {
                if let date = Calendar.current.date(byAdding: .day, value: i, to: Calendar.current.startOfDay(for: Date())) {
                    contextString += "\n\(dateFormatter.string(from: date)):\n"

                    let dayTasks = tasks.filter { task in
                        guard let taskDate = task.date else { return false }
                        return Calendar.current.isDate(taskDate, inSameDayAs: date)
                    }

                    let dayEvents = events.filter { event in
                        Calendar.current.isDate(event.startTime ?? Date(), inSameDayAs: date)
                    }

                    for task in dayTasks.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }) {
                        let timeString = task.startTime != nil ? timeFormatter.string(from: task.startTime!) : "No time"
                        let priority = task.priorityEnum.rawValue
                        contextString += "- \(timeString): \(task.title ?? "Untitled") [\(priority) priority]\n"
                    }

                    for event in dayEvents.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }) {
                        let timeString = timeFormatter.string(from: event.startTime ?? Date())
                        contextString += "- \(timeString): \(event.title ?? "Untitled") [event]\n"
                    }

                    if dayTasks.isEmpty && dayEvents.isEmpty {
                        contextString += "- No scheduled items\n"
                    }
                }
            }

            let unscheduledTasks = tasks.filter { $0.date == nil }
            if !unscheduledTasks.isEmpty {
                contextString += "\nUNSCHEDULED TASKS:\n"
                for task in unscheduledTasks {
                    let priority = task.priorityEnum.rawValue
                    contextString += "- \(task.title ?? "Untitled") [\(priority) priority]\n"
                }
            }

        } catch {
            print("Failed to fetch context data: \(error)")
            contextString = "Error loading current schedule"
        }

        return contextString
    }

    private func processAIResponse(_ response: String, context: NSManagedObjectContext) async {
        await parseAndExecuteCommands(response: response, context: context)
    }

    private func parseAndExecuteCommands(response: String, context: NSManagedObjectContext) async {
        let lowerResponse = response.lowercased()

        if lowerResponse.contains("i've added") || lowerResponse.contains("i'll add") || lowerResponse.contains("adding") {
            await parseTaskCreation(response: response, context: context)
        } else if lowerResponse.contains("i've moved") || lowerResponse.contains("i'll move") || lowerResponse.contains("moving") {
            await parseTaskMoving(response: response, context: context)
        } else if lowerResponse.contains("i've scheduled") || lowerResponse.contains("i'll schedule") || lowerResponse.contains("scheduling") {
            await parseTaskScheduling(response: response, context: context)
        }
    }

    private func parseTaskCreation(response: String, context: NSManagedObjectContext) async {

        let patterns = [
            #"added ([^.]+) to (\w+day) at (\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)"#,
            #"adding ([^.]+) to (\w+day) at (\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)"#,
            #"add ([^.]+) to (\w+day) at (\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = response as NSString
                let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: nsString.length))

                for match in matches {
                    if match.numberOfRanges >= 4 {
                        let taskTitle = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                        let dayString = nsString.substring(with: match.range(at: 2)).lowercased()
                        let timeString = nsString.substring(with: match.range(at: 3))

                        if let taskDate = parseRelativeDay(dayString),
                           let taskTime = parseTime(timeString) {

                            let fullDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: taskTime),
                                                                   minute: Calendar.current.component(.minute, from: taskTime),
                                                                   second: 0,
                                                                   of: taskDate) ?? taskDate

                            let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: fullDateTime)

                            await MainActor.run {
                                let task = Task.create(
                                    in: context,
                                    title: taskTitle,
                                    description: nil,
                                    priority: .none,
                                    startTime: fullDateTime,
                                    endTime: endTime,
                                    date: taskDate
                                )

                                do {
                                    try context.save()
                                    print("✅ Created task: \(taskTitle) on \(taskDate) at \(timeString)")

                                    NotificationCenter.default.post(name: .taskCreated, object: task)
                                } catch {
                                    print("❌ Failed to save task: \(error)")
                                }
                            }
                            return
                        }
                    }
                }
            }
        }
    }

    private func parseTaskMoving(response: String, context: NSManagedObjectContext) async {

    }

    private func parseTaskScheduling(response: String, context: NSManagedObjectContext) async {

    }

    private func parseRelativeDay(_ dayString: String) -> Date? {
        let today = Date()
        let calendar = Calendar.current

        switch dayString.lowercased() {
        case "today":
            return today
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: today)
        case "monday":
            return getNextWeekday(.monday, from: today)
        case "tuesday":
            return getNextWeekday(.tuesday, from: today)
        case "wednesday":
            return getNextWeekday(.wednesday, from: today)
        case "thursday":
            return getNextWeekday(.thursday, from: today)
        case "friday":
            return getNextWeekday(.friday, from: today)
        case "saturday":
            return getNextWeekday(.saturday, from: today)
        case "sunday":
            return getNextWeekday(.sunday, from: today)
        default:
            return nil
        }
    }

    private func getNextWeekday(_ targetWeekday: Calendar.Component, from date: Date) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        let weekdayValue: Int
        switch targetWeekday {
        case .sunday: weekdayValue = 1
        case .monday: weekdayValue = 2
        case .tuesday: weekdayValue = 3
        case .wednesday: weekdayValue = 4
        case .thursday: weekdayValue = 5
        case .friday: weekdayValue = 6
        case .saturday: weekdayValue = 7
        default: return nil
        }

        let currentWeekday = calendar.component(.weekday, from: today)
        let daysUntilTarget = (weekdayValue - currentWeekday + 7) % 7

        if daysUntilTarget == 0 {
            return today
        } else {
            return calendar.date(byAdding: .day, value: daysUntilTarget, to: today)
        }
    }

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        if let date = formatter.date(from: timeString) {
            return date
        }

        formatter.dateFormat = "h a"
        if let date = formatter.date(from: timeString) {
            return date
        }

        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeString) {
            return date
        }

        formatter.dateFormat = "H"
        if let date = formatter.date(from: timeString) {
            return date
        }

        return nil
    }

    func clearConversationHistory() {
        conversationHistory.removeAll()
    }

    func resetWeeklyContext() {
        clearConversationHistory()
    }
}

struct ChatMessage {
    let role: String
    let content: String
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }
}