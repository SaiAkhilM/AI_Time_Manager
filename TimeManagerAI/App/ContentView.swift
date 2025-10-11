import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            VoiceAgentView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Voice")
                }
                .tag(0)

            DocEditorView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Planner")
                }
                .tag(1)

            CalendarContainerView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)

            AIInsightsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Insights")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}