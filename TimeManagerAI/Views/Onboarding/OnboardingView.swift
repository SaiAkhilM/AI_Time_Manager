import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingPermissions = false
    @State private var userName = ""
    @State private var selectedWorkHours = WorkHours.standard
    @State private var selectedNotificationPreferences = NotificationPreferences.standard

    private let pages = OnboardingPage.allPages

    var body: some View {
        NavigationView {
            if currentPage < pages.count {
                OnboardingPageView(
                    page: pages[currentPage],
                    currentPage: $currentPage,
                    totalPages: pages.count,
                    userName: $userName,
                    selectedWorkHours: $selectedWorkHours,
                    selectedNotificationPreferences: $selectedNotificationPreferences,
                    onNext: nextPage,
                    onComplete: completeOnboarding
                )
            } else {
                OnboardingCompletionView(onComplete: completeOnboarding)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        saveUserPreferences()
        hasCompletedOnboarding = true
    }

    private func saveUserPreferences() {
        let settings = Settings.getOrCreate(in: viewContext)
        // Configure basic settings
        settings.calendarStartHour = Int32(Calendar.current.component(.hour, from: selectedWorkHours.startTime))
        settings.calendarEndHour = Int32(Calendar.current.component(.hour, from: selectedWorkHours.endTime))
        settings.taskRemindersEnabled = selectedNotificationPreferences.taskReminders
        settings.deadlineWarningsEnabled = selectedNotificationPreferences.deadlineWarnings
        settings.sleepWarningsEnabled = selectedNotificationPreferences.breakReminders
        settings.bedtimeWarningMinutes = Int32(selectedNotificationPreferences.bedtimeWarning)

        do {
            try viewContext.save()
        } catch {
            print("Failed to save user preferences: \(error)")
        }
    }
}

struct OnboardingPage {
    let id: Int
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let type: PageType

    enum PageType {
        case welcome
        case features
        case permissions
        case preferences
        case aiPower
        case completion
    }

    static let allPages = [
        OnboardingPage(
            id: 0,
            title: "Welcome to Time Manager AI",
            subtitle: "Your Intelligent Productivity Companion",
            description: "Transform your schedule into a powerful productivity system with AI-driven insights, voice commands, and smart automation.",
            imageName: "brain.head.profile",
            type: .welcome
        ),
        OnboardingPage(
            id: 1,
            title: "Voice-Powered Scheduling",
            subtitle: "Speak Your Tasks Into Existence",
            description: "Simply speak to create tasks, schedule events, and get instant AI feedback. No more typing - just talk and watch your calendar organize itself.",
            imageName: "mic.fill",
            type: .features
        ),
        OnboardingPage(
            id: 2,
            title: "AI-Driven Insights",
            subtitle: "Learn From Your Patterns",
            description: "Get personalized productivity insights, optimal scheduling suggestions, and deadline risk analysis powered by advanced AI.",
            imageName: "chart.line.uptrend.xyaxis",
            type: .aiPower
        ),
        OnboardingPage(
            id: 3,
            title: "Live Activities & Notifications",
            subtitle: "Stay In The Flow",
            description: "See your current tasks in the Dynamic Island, get smart reminders, and never miss a deadline with our intelligent notification system.",
            imageName: "bell.badge",
            type: .features
        ),
        OnboardingPage(
            id: 4,
            title: "Enable Permissions",
            subtitle: "Unlock Full Functionality",
            description: "We need a few permissions to provide you with the best experience. Don't worry - your privacy is our priority.",
            imageName: "shield.checkered",
            type: .permissions
        ),
        OnboardingPage(
            id: 5,
            title: "Customize Your Experience",
            subtitle: "Make It Yours",
            description: "Set up your work hours, notification preferences, and personal details to get the most out of Time Manager AI.",
            imageName: "slider.horizontal.3",
            type: .preferences
        )
    ]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var currentPage: Int
    let totalPages: Int
    @Binding var userName: String
    @Binding var selectedWorkHours: WorkHours
    @Binding var selectedNotificationPreferences: NotificationPreferences
    let onNext: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            OnboardingProgressView(currentPage: currentPage, totalPages: totalPages)
                .padding()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 20)

                    // Icon
                    Image(systemName: page.imageName)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.blue)
                        .padding(.bottom, 10)

                    // Content
                    VStack(spacing: 16) {
                        Text(page.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text(page.subtitle)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text(page.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    // Page-specific content
                    switch page.type {
                    case .permissions:
                        PermissionsView()
                    case .preferences:
                        PreferencesView(
                            userName: $userName,
                            selectedWorkHours: $selectedWorkHours,
                            selectedNotificationPreferences: $selectedNotificationPreferences
                        )
                    default:
                        EmptyView()
                    }

                    Spacer(minLength: 40)
                }
            }

            // Navigation Buttons
            OnboardingNavigationView(
                currentPage: currentPage,
                totalPages: totalPages,
                onNext: onNext,
                onComplete: onComplete
            )
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingProgressView: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
}

struct PermissionsView: View {
    @State private var microphoneGranted = false
    @State private var notificationsGranted = false

    var body: some View {
        VStack(spacing: 20) {
            PermissionRow(
                icon: "mic.fill",
                title: "Microphone Access",
                description: "For voice commands and task creation",
                isGranted: $microphoneGranted,
                action: requestMicrophonePermission
            )

            PermissionRow(
                icon: "bell.fill",
                title: "Notifications",
                description: "For reminders and deadline alerts",
                isGranted: $notificationsGranted,
                action: requestNotificationPermission
            )
        }
        .padding(.horizontal, 20)
        .onAppear {
            checkPermissions()
        }
    }

    private func checkPermissions() {
        // Check microphone permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphoneGranted = true
        case .denied, .undetermined:
            microphoneGranted = false
        @unknown default:
            microphoneGranted = false
        }

        // Check notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                microphoneGranted = granted
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsGranted = granted
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: action) {
                HStack(spacing: 6) {
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Granted")
                    } else {
                        Text("Enable")
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isGranted ? .green : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isGranted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                )
            }
            .disabled(isGranted)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PreferencesView: View {
    @Binding var userName: String
    @Binding var selectedWorkHours: WorkHours
    @Binding var selectedNotificationPreferences: NotificationPreferences

    var body: some View {
        VStack(spacing: 24) {
            // Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you?")
                    .font(.headline)
                    .fontWeight(.semibold)

                TextField("Enter your name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }

            // Work Hours
            VStack(alignment: .leading, spacing: 12) {
                Text("Work Hours")
                    .font(.headline)
                    .fontWeight(.semibold)

                Picker("Work Hours", selection: $selectedWorkHours) {
                    ForEach(WorkHours.allCases, id: \.self) { workHours in
                        Text(workHours.displayName).tag(workHours)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Notification Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Notification Preferences")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    NotificationToggle(
                        title: "Task Reminders",
                        description: "Get notified 15 minutes before tasks",
                        isOn: $selectedNotificationPreferences.taskReminders
                    )

                    NotificationToggle(
                        title: "Deadline Warnings",
                        description: "Alerts for approaching deadlines",
                        isOn: $selectedNotificationPreferences.deadlineWarnings
                    )

                    NotificationToggle(
                        title: "Break Reminders",
                        description: "Gentle nudges to take breaks",
                        isOn: $selectedNotificationPreferences.breakReminders
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct NotificationToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OnboardingNavigationView: View {
    let currentPage: Int
    let totalPages: Int
    let onNext: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button("Skip") {
                    onComplete()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }

            Spacer()

            if currentPage < totalPages - 1 {
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            } else {
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                        Image(systemName: "checkmark")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(25)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .background(Color(.systemBackground))
    }
}

struct OnboardingCompletionView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Success Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Welcome to your new productivity journey")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onComplete) {
                Text("Start Using Time Manager AI")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

// Supporting Types
enum WorkHours: CaseIterable {
    case earlyBird    // 6AM - 2PM
    case standard     // 9AM - 5PM
    case flexible     // 10AM - 6PM
    case nightOwl     // 12PM - 8PM

    var displayName: String {
        switch self {
        case .earlyBird: return "Early Bird"
        case .standard: return "Standard"
        case .flexible: return "Flexible"
        case .nightOwl: return "Night Owl"
        }
    }

    var startTime: Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        switch self {
        case .earlyBird: return calendar.date(byAdding: .hour, value: 6, to: startOfDay) ?? now
        case .standard: return calendar.date(byAdding: .hour, value: 9, to: startOfDay) ?? now
        case .flexible: return calendar.date(byAdding: .hour, value: 10, to: startOfDay) ?? now
        case .nightOwl: return calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? now
        }
    }

    var endTime: Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        switch self {
        case .earlyBird: return calendar.date(byAdding: .hour, value: 14, to: startOfDay) ?? now
        case .standard: return calendar.date(byAdding: .hour, value: 17, to: startOfDay) ?? now
        case .flexible: return calendar.date(byAdding: .hour, value: 18, to: startOfDay) ?? now
        case .nightOwl: return calendar.date(byAdding: .hour, value: 20, to: startOfDay) ?? now
        }
    }
}

struct NotificationPreferences {
    var taskReminders: Bool
    var deadlineWarnings: Bool
    var breakReminders: Bool
    var bedtimeWarning: Int // minutes before bedtime

    static let standard = NotificationPreferences(
        taskReminders: true,
        deadlineWarnings: true,
        breakReminders: true,
        bedtimeWarning: 30
    )
}

import AVFoundation
import UserNotifications

#Preview {
    OnboardingView()
}