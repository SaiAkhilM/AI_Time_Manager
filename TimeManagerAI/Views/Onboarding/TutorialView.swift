import SwiftUI
import CoreData

struct TutorialView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @State private var currentStep = 0
    @State private var showingOverlay = true
    @State private var highlightedArea: CGRect = .zero

    private let steps = TutorialStep.allSteps

    var body: some View {
        ZStack {
            // Main content (the actual app interface)
            ContentView()
                .disabled(showingOverlay)
                .blur(radius: showingOverlay ? 1 : 0)

            if showingOverlay && currentStep < steps.count {
                TutorialOverlayView(
                    step: steps[currentStep],
                    currentStep: currentStep,
                    totalSteps: steps.count,
                    onNext: nextStep,
                    onSkip: completeTutorial,
                    onComplete: completeTutorial
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingOverlay)
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeTutorial()
        }
    }

    private func completeTutorial() {
        withAnimation {
            showingOverlay = false
            hasCompletedTutorial = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

struct TutorialStep {
    let id: Int
    let title: String
    let description: String
    let targetView: String
    let highlightArea: CGRect?
    let position: OverlayPosition

    enum OverlayPosition {
        case top
        case center
        case bottom
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    static let allSteps = [
        TutorialStep(
            id: 0,
            title: "Welcome to Time Manager AI! 🎉",
            description: "Let's take a quick tour to help you get the most out of your new productivity companion. This will only take a minute!",
            targetView: "",
            highlightArea: nil,
            position: .center
        ),
        TutorialStep(
            id: 1,
            title: "Voice Commands",
            description: "Tap the Voice tab to create tasks, schedule events, and get AI assistance just by speaking. Try saying: 'Schedule a meeting tomorrow at 2 PM'",
            targetView: "voice_tab",
            highlightArea: CGRect(x: 0, y: 0, width: 100, height: 80),
            position: .bottom
        ),
        TutorialStep(
            id: 2,
            title: "Your AI Planner",
            description: "The Planner automatically generates intelligent weekly documents based on your tasks and schedule. It updates in real-time as you make changes!",
            targetView: "planner_tab",
            highlightArea: CGRect(x: 100, y: 0, width: 100, height: 80),
            position: .bottom
        ),
        TutorialStep(
            id: 3,
            title: "Smart Calendar",
            description: "View your tasks and events in daily or weekly formats. Tap any task to mark it complete, edit details, or get AI scheduling suggestions.",
            targetView: "calendar_tab",
            highlightArea: CGRect(x: 200, y: 0, width: 100, height: 80),
            position: .bottom
        ),
        TutorialStep(
            id: 4,
            title: "AI Insights Dashboard",
            description: "Get productivity insights, optimization suggestions, and deadline risk analysis. Your personal AI productivity coach lives here!",
            targetView: "insights_tab",
            highlightArea: CGRect(x: 300, y: 0, width: 100, height: 80),
            position: .bottom
        ),
        TutorialStep(
            id: 5,
            title: "Dynamic Island Integration",
            description: "When you have active tasks, they'll appear in the Dynamic Island showing progress, time remaining, and completion status. Stay focused without switching apps!",
            targetView: "dynamic_island",
            highlightArea: nil,
            position: .top
        ),
        TutorialStep(
            id: 6,
            title: "Smart Notifications",
            description: "Get intelligent reminders 15 minutes before tasks, deadline warnings, and overdue alerts. The AI learns your patterns to optimize notification timing.",
            targetView: "",
            highlightArea: nil,
            position: .center
        ),
        TutorialStep(
            id: 7,
            title: "You're Ready! 🚀",
            description: "Start by creating your first task with voice commands, or explore the AI Insights to see optimization suggestions. Remember: speak naturally, the AI understands context!",
            targetView: "",
            highlightArea: nil,
            position: .center
        )
    ]
}

struct TutorialOverlayView: View {
    let step: TutorialStep
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissal by tapping background for non-intro steps
                    if step.id > 0 {
                        onSkip()
                    }
                }

            // Tutorial content
            VStack {
                if step.position == .bottom || step.position == .bottomLeading || step.position == .bottomTrailing {
                    Spacer()
                }

                if step.position == .center {
                    Spacer()
                }

                TutorialContentCard(
                    step: step,
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    onNext: onNext,
                    onSkip: onSkip,
                    onComplete: onComplete
                )
                .padding(.horizontal, 20)

                if step.position == .top || step.position == .topLeading || step.position == .topTrailing {
                    Spacer()
                }

                if step.position == .center {
                    Spacer()
                }
            }
        }
    }
}

struct TutorialContentCard: View {
    let step: TutorialStep
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            if totalSteps > 1 {
                TutorialProgressView(currentStep: currentStep, totalSteps: totalSteps)
            }

            // Content
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Skip Tour") {
                        onSkip()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button(action: onNext) {
                        HStack(spacing: 8) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(20)
                    }
                } else {
                    Button(action: onComplete) {
                        HStack(spacing: 8) {
                            Text("Start Exploring")
                            Image(systemName: "checkmark")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct TutorialProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// Tutorial trigger views
struct TutorialTriggerView: View {
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @State private var showingTutorial = false

    var body: some View {
        EmptyView()
            .onAppear {
                if !hasCompletedTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showingTutorial = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingTutorial) {
                TutorialView()
            }
    }
}

// Feature highlight views
struct FeatureHighlightView: View {
    let feature: Feature
    @Binding var isShowing: Bool
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                    onComplete()
                }

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    // Feature icon
                    Image(systemName: feature.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    // Feature info
                    VStack(spacing: 12) {
                        Text(feature.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(feature.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        if !feature.tips.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tips:")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                ForEach(feature.tips, id: \.self) { tip in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(tip)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }

                    Button("Got it!") {
                        withAnimation {
                            isShowing = false
                        }
                        onComplete()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 10)
                )
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .transition(.opacity)
    }
}

struct Feature {
    let id: String
    let title: String
    let description: String
    let icon: String
    let tips: [String]

    static let voiceCommands = Feature(
        id: "voice_commands",
        title: "Voice Commands",
        description: "Create and manage tasks naturally with your voice. The AI understands context and can schedule complex requests.",
        icon: "mic.fill",
        tips: [
            "Say 'Add gym workout tomorrow at 7 AM' for quick scheduling",
            "Use 'Move my 3 PM meeting to Friday' to reschedule",
            "Try 'What's my schedule today?' for agenda overview"
        ]
    )

    static let aiInsights = Feature(
        id: "ai_insights",
        title: "AI Insights",
        description: "Get personalized productivity recommendations based on your work patterns and schedule analysis.",
        icon: "brain.head.profile",
        tips: [
            "Check weekly to see productivity optimization suggestions",
            "Review deadline risk assessments to stay on track",
            "Use time estimation insights to improve planning accuracy"
        ]
    )

    static let liveActivities = Feature(
        id: "live_activities",
        title: "Live Activities",
        description: "See your current tasks in the Dynamic Island with progress tracking and time remaining.",
        icon: "rectangle.inset.filled.badge.record",
        tips: [
            "Active tasks automatically appear in the Dynamic Island",
            "Progress bars show how much time has elapsed",
            "Tap to quickly mark tasks as complete"
        ]
    )
}

// Tutorial management
class TutorialManager: ObservableObject {
    @Published var shouldShowFeatureHighlight: [String: Bool] = [:]

    func triggerFeatureHighlight(for featureId: String) {
        shouldShowFeatureHighlight[featureId] = true
    }

    func completeFeatureHighlight(for featureId: String) {
        shouldShowFeatureHighlight[featureId] = false
        UserDefaults.standard.set(true, forKey: "highlighted_\(featureId)")
    }

    func hasShownHighlight(for featureId: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "highlighted_\(featureId)")
    }
}

#Preview {
    TutorialView()
}