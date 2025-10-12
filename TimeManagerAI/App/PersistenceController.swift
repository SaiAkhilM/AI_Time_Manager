import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "DataModel")

        container.loadPersistentStores { _, error in
            if let error = error {
                // Don't crash, just print the error for now
                print("Core Data error (non-fatal): \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}