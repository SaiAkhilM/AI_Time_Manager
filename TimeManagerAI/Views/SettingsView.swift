import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var voiceSpeed: Double = 1.0
    @State private var selectedTheme = 0

    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }

                Section("Voice Settings") {
                    VStack {
                        Text("Voice Speed: \(voiceSpeed, specifier: "%.1f")x")
                        Slider(value: $voiceSpeed, in: 0.5...2.0)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("Auto").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}