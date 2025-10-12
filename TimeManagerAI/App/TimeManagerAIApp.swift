import SwiftUI
import CoreData

@main
struct TimeManagerAIApp: App {
    private let persistenceController = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
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

