import SwiftUI
import CoreData

@main
struct TimeManagerAIApp: App {
    private let persistenceController = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    Group {
                        ContentView()
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onAppear {
                        print("✅ Loading ContentView")
                    }
                } else {
                    OnboardingView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .onAppear {
                            print("✅ Loading OnboardingView")
                        }
                }
            }
            .onAppear {
                print("✅ App started, hasCompletedOnboarding: \(hasCompletedOnboarding)")
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

