import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct DataManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var exportImportService: DataExportImportService
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingImportResult = false
    @State private var importResult: ImportResult?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    init() {
        let context = PersistenceController.shared.container.viewContext
        self._exportImportService = StateObject(wrappedValue: DataExportImportService(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Backup & Restore")) {
                    // Export Data
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export Data")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Save your tasks, events, and settings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if exportImportService.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(exportImportService.isExporting)
                    .buttonStyle(PlainButtonStyle())

                    // Import Data
                    Button(action: { showingImportPicker = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import Data")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Restore from a backup file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if exportImportService.isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(exportImportService.isImporting)
                    .buttonStyle(PlainButtonStyle())
                }

                Section(header: Text("Data Statistics")) {
                    DataStatsView()
                }

                Section(header: Text("Data Management"), footer: Text("These actions cannot be undone. Make sure to export your data first.")) {
                    // Clear All Data
                    Button(action: showClearDataAlert) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)

                            Text("Clear All Data")
                                .foregroundColor(.red)

                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Reset Settings
                    Button(action: showResetSettingsAlert) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)

                            Text("Reset Settings")
                                .foregroundColor(.orange)

                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if exportImportService.isExporting || exportImportService.isImporting {
                    Section {
                        ProgressCard(
                            isExporting: exportImportService.isExporting,
                            isImporting: exportImportService.isImporting,
                            exportProgress: exportImportService.exportProgress,
                            importProgress: exportImportService.importProgress
                        )
                    }
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(
                onExport: exportData,
                isExporting: exportImportService.isExporting
            )
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingImportResult) {
            if let result = importResult {
                ImportResultSheet(result: result) {
                    showingImportResult = false
                    importResult = nil
                }
            }
        }
    }

    private func exportData(format: ExportFormat) {
        Task {
            do {
                let url = try await exportImportService.exportData(format: format)
                DispatchQueue.main.async {
                    self.exportedFileURL = url
                    self.showingShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertTitle = "Export Failed"
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
            }
        }
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importData(from: url)
        case .failure(let error):
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func importData(from url: URL) {
        Task {
            do {
                let result = try await exportImportService.importData(from: url)
                DispatchQueue.main.async {
                    self.importResult = result
                    self.showingImportResult = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertTitle = "Import Failed"
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
            }
        }
    }

    private func showClearDataAlert() {
        let alert = UIAlertController(
            title: "Clear All Data",
            message: "This will permanently delete all your tasks, events, goals, and conversation history. This action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear Data", style: .destructive) { _ in
            clearAllData()
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func showResetSettingsAlert() {
        let alert = UIAlertController(
            title: "Reset Settings",
            message: "This will reset all your preferences to default values. Your tasks and events will remain unchanged.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            resetSettings()
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func clearAllData() {
        let entities = ["Task", "Event", "Goal", "ConversationContext"]

        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try viewContext.execute(deleteRequest)
            } catch {
                print("Failed to clear \(entityName): \(error)")
            }
        }

        do {
            try viewContext.save()
            alertTitle = "Success"
            alertMessage = "All data has been cleared."
            showingAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to clear data: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func resetSettings() {
        let settings = Settings.getOrCreate(in: viewContext)

        // Reset to default values
        // Reset to default values
        settings.calendarStartHour = 9
        settings.calendarEndHour = 17
        settings.sleepStartTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        settings.sleepEndTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        settings.taskRemindersEnabled = true
        settings.deadlineWarningsEnabled = true
        settings.sleepWarningsEnabled = true
        settings.bedtimeWarningMinutes = 30
        settings.timeIncrement = 25

        do {
            try viewContext.save()
            alertTitle = "Success"
            alertMessage = "Settings have been reset to defaults."
            showingAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to reset settings: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct DataStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var taskCount = 0
    @State private var eventCount = 0
    @State private var goalCount = 0
    @State private var completedTaskCount = 0

    var body: some View {
        VStack(spacing: 12) {
            StatRow(title: "Total Tasks", value: "\(taskCount)", color: .blue)
            StatRow(title: "Completed Tasks", value: "\(completedTaskCount)", color: .green)
            StatRow(title: "Events", value: "\(eventCount)", color: .orange)
            StatRow(title: "Goals", value: "\(goalCount)", color: .purple)
        }
        .onAppear {
            loadStats()
        }
    }

    private func loadStats() {
        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        taskCount = (try? viewContext.count(for: taskRequest)) ?? 0

        let completedTaskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        completedTaskRequest.predicate = NSPredicate(format: "isCompleted == YES")
        completedTaskCount = (try? viewContext.count(for: completedTaskRequest)) ?? 0

        let eventRequest: NSFetchRequest<Event> = Event.fetchRequest()
        eventCount = (try? viewContext.count(for: eventRequest)) ?? 0

        let goalRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        goalCount = (try? viewContext.count(for: goalRequest)) ?? 0
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct ProgressCard: View {
    let isExporting: Bool
    let isImporting: Bool
    let exportProgress: Double
    let importProgress: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isExporting ? "square.and.arrow.up" : "square.and.arrow.down")
                    .foregroundColor(isExporting ? .blue : .green)

                Text(isExporting ? "Exporting Data..." : "Importing Data...")
                    .font(.headline)

                Spacer()
            }

            ProgressView(value: isExporting ? exportProgress : importProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: isExporting ? .blue : .green))
                .scaleEffect(y: 2)

            Text("\(Int((isExporting ? exportProgress : importProgress) * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ExportOptionsSheet: View {
    let onExport: (ExportFormat) -> Void
    let isExporting: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Choose Export Format")) {
                    ExportFormatRow(
                        format: .json,
                        title: "JSON Format",
                        description: "Complete backup with all data and settings",
                        icon: "doc.text",
                        onExport: onExport
                    )

                    ExportFormatRow(
                        format: .csv,
                        title: "CSV Format",
                        description: "Spreadsheet-compatible format for data analysis",
                        icon: "tablecells",
                        onExport: onExport
                    )

                    ExportFormatRow(
                        format: .calendar,
                        title: "Calendar Format (ICS)",
                        description: "Import into other calendar apps",
                        icon: "calendar",
                        onExport: onExport
                    )
                }
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExportFormatRow: View {
    let format: ExportFormat
    let title: String
    let description: String
    let icon: String
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: {
            onExport(format)
            dismiss()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImportResultSheet: View {
    let result: ImportResult
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }

                // Result Summary
                VStack(spacing: 12) {
                    Text("Import Successful!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(result.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Detailed Stats
                if result.totalImported > 0 {
                    VStack(spacing: 8) {
                        if result.tasksImported > 0 {
                            StatRow(title: "Tasks", value: "\(result.tasksImported)", color: .blue)
                        }
                        if result.eventsImported > 0 {
                            StatRow(title: "Events", value: "\(result.eventsImported)", color: .orange)
                        }
                        if result.goalsImported > 0 {
                            StatRow(title: "Goals", value: "\(result.goalsImported)", color: .purple)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer()

                Button("Done") {
                    onDismiss()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Import Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataManagementView()
}