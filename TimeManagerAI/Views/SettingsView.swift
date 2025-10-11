import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var settings: Settings?
    @State private var sleepStartTime = Date()
    @State private var sleepEndTime = Date()
    @State private var sleepPriority: Settings.SleepPriority = .unmovable
    @State private var bedtimeWarningMinutes = 30
    @State private var notificationsEnabled = true
    @State private var taskRemindersEnabled = true
    @State private var deadlineWarningsEnabled = true
    @State private var sleepWarningsEnabled = true
    @State private var voiceSpeed: Float = 1.0
    @State private var aiPersonality: Settings.AIPersonality = .professional
    @State private var autoReschedule: Settings.AutoReschedule = .smart
    @State private var calendarStartHour = 6
    @State private var calendarEndHour = 24
    @State private var timeIncrement = 15
    @State private var colorTheme: Settings.ColorTheme = .auto
    @State private var weeklyContextReset = true

    var body: some View {
        NavigationView {
            Form {
                sleepSection
                notificationSection
                voiceAgentSection
                displaySection
                accountDataSection
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
            .onDisappear {
                saveSettings()
            }
        }
    }

    private var sleepSection: some View {
        Section(header: Text("Sleep Settings")) {
            DatePicker("Sleep Time", selection: $sleepStartTime, displayedComponents: .hourAndMinute)
            DatePicker("Wake Time", selection: $sleepEndTime, displayedComponents: .hourAndMinute)

            Picker("Sleep Priority", selection: $sleepPriority) {
                ForEach(Settings.SleepPriority.allCases, id: \.self) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }

            Stepper("Bedtime warning: \(bedtimeWarningMinutes) min", value: $bedtimeWarningMinutes, in: 0...120, step: 15)
        }
    }

    private var notificationSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Master Notifications", isOn: $notificationsEnabled)

            Group {
                Toggle("Task Reminders", isOn: $taskRemindersEnabled)
                Toggle("Deadline Warnings", isOn: $deadlineWarningsEnabled)
                Toggle("Sleep Time Warnings", isOn: $sleepWarningsEnabled)
            }
            .disabled(!notificationsEnabled)
            .opacity(notificationsEnabled ? 1.0 : 0.6)
        }
    }

    private var voiceAgentSection: some View {
        Section(header: Text("Voice Agent")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("0.5x")
                        .font(.caption)
                    Slider(value: $voiceSpeed, in: 0.5...2.0, step: 0.1)
                    Text("2.0x")
                        .font(.caption)
                }
            }

            Picker("AI Personality", selection: $aiPersonality) {
                ForEach(Settings.AIPersonality.allCases, id: \.self) { personality in
                    Text(personality.displayName).tag(personality)
                }
            }

            Picker("Auto-reschedule Behavior", selection: $autoReschedule) {
                ForEach(Settings.AutoReschedule.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
        }
    }

    private var displaySection: some View {
        Section(header: Text("Display")) {
            Stepper("Calendar starts at: \(calendarStartHour):00", value: $calendarStartHour, in: 0...12)

            Stepper("Calendar ends at: \(calendarEndHour):00", value: $calendarEndHour, in: 18...24)

            Picker("Time Increment", selection: $timeIncrement) {
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("60 minutes").tag(60)
            }

            Picker("Color Theme", selection: $colorTheme) {
                ForEach(Settings.ColorTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
        }
    }

    private var accountDataSection: some View {
        Section(header: Text("Account & Data")) {
            Toggle("Weekly Context Reset", isOn: $weeklyContextReset)

            Button("Export Schedule as PDF") {

            }
            .foregroundColor(.blue)

            Button("Clear All Data") {

            }
            .foregroundColor(.red)
        }
    }

    private func loadSettings() {
        let loadedSettings = Settings.getOrCreate(in: viewContext)
        settings = loadedSettings

        sleepStartTime = loadedSettings.sleepStartTime ?? Date()
        sleepEndTime = loadedSettings.sleepEndTime ?? Date()
        sleepPriority = loadedSettings.sleepPriorityEnum
        bedtimeWarningMinutes = Int(loadedSettings.bedtimeWarningMinutes)
        notificationsEnabled = loadedSettings.notificationsEnabled
        taskRemindersEnabled = loadedSettings.taskRemindersEnabled
        deadlineWarningsEnabled = loadedSettings.deadlineWarningsEnabled
        sleepWarningsEnabled = loadedSettings.sleepWarningsEnabled
        voiceSpeed = loadedSettings.voiceSpeed
        aiPersonality = loadedSettings.aiPersonalityEnum
        autoReschedule = loadedSettings.autoRescheduleEnum
        calendarStartHour = Int(loadedSettings.calendarStartHour)
        calendarEndHour = Int(loadedSettings.calendarEndHour)
        timeIncrement = Int(loadedSettings.timeIncrement)
        colorTheme = loadedSettings.colorThemeEnum
        weeklyContextReset = loadedSettings.weeklyContextReset
    }

    private func saveSettings() {
        guard let settings = settings else { return }

        settings.sleepStartTime = sleepStartTime
        settings.sleepEndTime = sleepEndTime
        settings.sleepPriorityEnum = sleepPriority
        settings.bedtimeWarningMinutes = Int32(bedtimeWarningMinutes)
        settings.notificationsEnabled = notificationsEnabled
        settings.taskRemindersEnabled = taskRemindersEnabled
        settings.deadlineWarningsEnabled = deadlineWarningsEnabled
        settings.sleepWarningsEnabled = sleepWarningsEnabled
        settings.voiceSpeed = voiceSpeed
        settings.aiPersonalityEnum = aiPersonality
        settings.autoRescheduleEnum = autoReschedule
        settings.calendarStartHour = Int32(calendarStartHour)
        settings.calendarEndHour = Int32(calendarEndHour)
        settings.timeIncrement = Int32(timeIncrement)
        settings.colorThemeEnum = colorTheme
        settings.weeklyContextReset = weeklyContextReset
        settings.updateTimestamp()

        do {
            try viewContext.save()
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}