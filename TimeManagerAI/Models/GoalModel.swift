import Foundation
import CoreData

extension Goal {
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        description: String? = nil,
        targetHoursPerWeek: Int32 = 0
    ) -> Goal {
        let goal = Goal(context: context)
        goal.id = UUID()
        goal.title = title
        goal.goalDescription = description
        goal.targetHoursPerWeek = targetHoursPerWeek
        goal.isActive = true
        goal.createdAt = Date()
        goal.updatedAt = Date()

        return goal
    }

    func updateTimestamp() {
        self.updatedAt = Date()
    }
}