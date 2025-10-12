import SwiftUI
import CoreData

// Lazy wrappers to prevent immediate initialization of views with Core Data dependencies

struct LazyVoiceAgentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                VoiceAgentView()
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading Voice Agent...")
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

struct LazyDocEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                DocEditorView()
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading Document Editor...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}

struct LazyCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                CalendarContainerView()
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading Calendar...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}

struct LazyAIInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                AIInsightsView()
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading AI Insights...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}

struct LazySettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}