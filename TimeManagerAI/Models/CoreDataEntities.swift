import Foundation
import CoreData

// Manual Core Data entity definitions to resolve generation issues

@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    // Core Data will automatically synthesize these properties
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var taskDescription: String?
    @NSManaged public var priority: String
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var date: Date?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var isCompleted: Bool
    @NSManaged public var linkedURL: String?
    @NSManaged public var estimatedDuration: Int32
    @NSManaged public var actualDuration: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var parentTask: TaskEntity?
    @NSManaged public var subtasks: NSSet?
    @NSManaged public var recurrencePattern: RecurrencePattern?
    @NSManaged public var goal: Goal?
}

@objc(Event)
public class Event: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var eventDescription: String?
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date
    @NSManaged public var isRecurring: Bool
    @NSManaged public var location: String?
    @NSManaged public var isMovable: Bool
    @NSManaged public var priority: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var recurrencePattern: RecurrencePattern?
}

@objc(Goal)
public class Goal: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var goalDescription: String?
    @NSManaged public var targetHoursPerWeek: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var tasks: NSSet?
}

@objc(Settings)
public class Settings: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var sleepStartTime: Date
    @NSManaged public var sleepEndTime: Date
    @NSManaged public var sleepPriority: String
    @NSManaged public var bedtimeWarningMinutes: Int32
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var taskRemindersEnabled: Bool
    @NSManaged public var deadlineWarningsEnabled: Bool
    @NSManaged public var sleepWarningsEnabled: Bool
    @NSManaged public var voiceSpeed: Float
    @NSManaged public var aiPersonality: String
    @NSManaged public var autoReschedule: String
    @NSManaged public var calendarStartHour: Int32
    @NSManaged public var calendarEndHour: Int32
    @NSManaged public var timeIncrement: Int32
    @NSManaged public var colorTheme: String
    @NSManaged public var weeklyContextReset: Bool
    @NSManaged public var updatedAt: Date
}

@objc(RecurrencePattern)
public class RecurrencePattern: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var frequency: String
    @NSManaged public var interval: Int32
    @NSManaged public var daysOfWeek: String?
    @NSManaged public var endDate: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var task: TaskEntity?
    @NSManaged public var event: Event?
}

@objc(ConversationContext)
public class ConversationContext: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var messages: String?
    @NSManaged public var weekNumber: Int32
    @NSManaged public var lastUpdated: Date
    @NSManaged public var currentContext: String?
}

// Fetch request helpers
extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "Task")
    }
}

extension Event {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }
}

extension Goal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }
}

extension Settings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }
}

extension RecurrencePattern {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurrencePattern> {
        return NSFetchRequest<RecurrencePattern>(entityName: "RecurrencePattern")
    }
}

extension ConversationContext {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationContext> {
        return NSFetchRequest<ConversationContext>(entityName: "ConversationContext")
    }
}