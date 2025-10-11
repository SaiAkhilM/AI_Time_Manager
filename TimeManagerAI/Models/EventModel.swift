import Foundation
import CoreData

extension Event {
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        description: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        isMovable: Bool = false
    ) -> Event {
        let event = Event(context: context)
        event.id = UUID()
        event.title = title
        event.eventDescription = description
        event.startTime = startTime
        event.endTime = endTime
        event.location = location
        event.isMovable = isMovable
        event.priority = "yellow"
        event.isRecurring = false
        event.createdAt = Date()
        event.updatedAt = Date()

        return event
    }

    func updateTimestamp() {
        self.updatedAt = Date()
    }
}