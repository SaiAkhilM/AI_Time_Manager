import SwiftUI
import CoreData

// Progressive Voice Agent - Core Data added ONLY after feature activation
struct FunctionalVoiceAgentView: View {
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var currentTopic = "Ready to help"
    @State private var featuresEnabled = false
    @State private var userTranscript = ""
    @State private var aiResponse = ""
    @StateObject private var voiceViewModel = VoiceAgentViewModel()
    @State private var coreDataReady = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Topic display
                VStack(spacing: 10) {
                    Text("Current Topic")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(currentTopic)
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Microphone button
                microphoneSection

                // Quick actions or enable button
                if featuresEnabled {
                    quickActionButtons
                } else {
                    enableFeaturesSection
                }

                Spacer()

                // Transcripts (if available)
                if coreDataReady && (voiceViewModel.isProcessing || !voiceViewModel.userTranscript.isEmpty || !voiceViewModel.aiResponse.isEmpty) {
                    realTranscriptSection
                } else if !userTranscript.isEmpty || !aiResponse.isEmpty {
                    transcriptSection
                }
            }
            .navigationTitle("Voice Agent")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        clearConversation()
                    }
                    .disabled(!featuresEnabled)
                }
            }
            .padding()
        }
    }

    private var microphoneSection: some View {
        VStack(spacing: 20) {
            Button(action: {
                if featuresEnabled {
                    toggleRecording()
                } else {
                    showEnableFeaturesMessage()
                }
            }) {
                Circle()
                    .fill(isRecording ? .red : (featuresEnabled ? .blue : .gray))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
            }
            .disabled(isProcessing)

            if isProcessing {
                ProgressView("Processing...")
                    .font(.caption)
            } else if !featuresEnabled {
                Text("Tap 'Enable Voice Features' below")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var enableFeaturesSection: some View {
        VStack(spacing: 15) {
            Text("Voice Features Ready")
                .font(.headline)
                .foregroundColor(.blue)

            Text("Voice recording and AI processing are available")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Enable Voice Features") {
                enableFeatures()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var quickActionButtons: some View {
        HStack(spacing: 15) {
            Button("Add Task") {
                handleQuickAction("Add a new task")
            }
            .buttonStyle(.bordered)

            Button("Schedule") {
                handleQuickAction("Show my schedule")
            }
            .buttonStyle(.bordered)

            Button("Goals") {
                handleQuickAction("Review my goals")
            }
            .buttonStyle(.bordered)
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !userTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(userTranscript)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if !aiResponse.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("AI Response:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(aiResponse)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    private var realTranscriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !voiceViewModel.userTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(voiceViewModel.userTranscript)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if !voiceViewModel.aiResponse.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("AI Response:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(voiceViewModel.aiResponse)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if voiceViewModel.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing your request...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Actions (Static for now)

    private func enableFeatures() {
        featuresEnabled = true
        currentTopic = "Initializing voice features..."

        // Initialize Core Data safely after UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            coreDataReady = true
            currentTopic = "Voice features enabled - Ready to help!"
        }
    }

    private func toggleRecording() {
        isRecording.toggle()

        if isRecording {
            currentTopic = "Listening..."

            if coreDataReady {
                // Use real voice functionality
                voiceViewModel.toggleRecording(context: PersistenceController.shared.container.viewContext)
            } else {
                // Simulate recording for demo
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isRecording {
                        isRecording = false
                        processRecording()
                    }
                }
            }
        } else {
            if coreDataReady {
                voiceViewModel.toggleRecording(context: PersistenceController.shared.container.viewContext)
                currentTopic = "Processing..."
            } else {
                processRecording()
            }
        }
    }

    private func processRecording() {
        isProcessing = true
        currentTopic = "Processing..."

        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            userTranscript = "Sample voice input - features will be connected later"
            aiResponse = "I understand your request. Voice-to-AI features are being prepared."
            currentTopic = "Response ready"
            isProcessing = false

            // Auto-clear after demo
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                currentTopic = "Ready to help"
            }
        }
    }

    private func handleQuickAction(_ action: String) {
        if coreDataReady {
            // Use real voice processing with appropriate QuickAction
            let quickAction: QuickAction
            switch action {
            case "Add a new task":
                quickAction = .addNewTask
            case "Show my schedule":
                quickAction = .showToday
            case "Review my goals":
                quickAction = .whatsNext
            default:
                quickAction = .whatsNext
            }
            voiceViewModel.handleQuickAction(quickAction, context: PersistenceController.shared.container.viewContext)
            currentTopic = "Processing your request..."
        } else {
            // Static demo response
            userTranscript = action
            aiResponse = "Quick action received: \(action). Full functionality coming soon!"
            currentTopic = "Quick action processed"

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                currentTopic = "Ready to help"
            }
        }
    }

    private func clearConversation() {
        if coreDataReady {
            voiceViewModel.clearConversation()
        } else {
            userTranscript = ""
            aiResponse = ""
        }
        currentTopic = "Ready to help"
    }

    private func showEnableFeaturesMessage() {
        currentTopic = "Please enable voice features first"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            currentTopic = "Ready to help"
        }
    }
}

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}

// Lazy wrapper to safely load Calendar
struct LazyCalendarView: View {
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

// Lazy wrapper to safely load Document Editor
struct LazyDocEditorView: View {
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

// Lazy wrapper to safely load AI Insights
struct LazyAIInsightsView: View {
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

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Voice Agent Tab
            FunctionalVoiceAgentView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Voice")
                }
                .tag(0)

            // Planner Tab
            LazyDocEditorView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Planner")
                }
                .tag(1)

            // Calendar Tab
            LazyCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)

            // AI Insights Tab
            LazyAIInsightsView()
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