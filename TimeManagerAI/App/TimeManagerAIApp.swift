import SwiftUI
import CoreData

@main
struct TimeManagerAIApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .overlay(
                            TutorialTriggerView()
                        )
                } else {
                    OnboardingView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
            .onAppear {
                if hasCompletedOnboarding {
                    createSampleDataIfNeeded()
                }
            }
        }
    }

    private func createSampleDataIfNeeded() {
        let context = persistenceController.container.viewContext

        if SampleDataManager.shouldCreateSampleData(in: context) {
            SampleDataManager.createSampleTasks(in: context)
        }
    }
}

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}