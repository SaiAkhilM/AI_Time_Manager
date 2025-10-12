import SwiftUI

// Lazy wrapper to safely load SettingsView
struct LazySettingsView: View {
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                SettingsView()
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading Settings...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // Delay view creation to ensure Core Data is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Voice Agent Tab - Temporarily disabled to fix KeyPath error
            Text("Voice Agent\n(Loading...)")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Voice")
                }
                .tag(0)

            // Planner Tab - Temporarily disabled to fix KeyPath error
            Text("Document Planner\n(Loading...)")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Planner")
                }
                .tag(1)

            // Calendar Tab - Temporarily disabled to fix KeyPath error
            Text("Calendar\n(Loading...)")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)

            // AI Insights Tab - Temporarily disabled to fix KeyPath error
            Text("AI Insights\n(Loading...)")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Insights")
                }
                .tag(3)

            // Settings Tab - Using LazyView wrapper for safe initialization
            LazySettingsView()
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