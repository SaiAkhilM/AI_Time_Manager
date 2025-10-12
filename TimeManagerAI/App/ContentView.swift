import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Voice Agent Tab
            VoiceAgentView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Voice")
                }
                .tag(0)

            // Planner Tab
            Text("Document Planner")
                .font(.title)
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Planner")
                }
                .tag(1)

            // Calendar Tab
            Text("Calendar")
                .font(.title)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)

            // AI Insights Tab
            Text("AI Insights")
                .font(.title)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Insights")
                }
                .tag(3)

            // Settings Tab
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