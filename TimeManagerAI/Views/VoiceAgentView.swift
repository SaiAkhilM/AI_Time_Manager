import SwiftUI

struct VoiceAgentView: View {
    @State private var isRecording = false
    @State private var recordingText = ""
    @State private var aiResponse = ""
    @State private var currentTopic = "Ready to help"

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Currently talking about:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(currentTopic)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 180, height: 180)
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(), value: isRecording)

                        Circle()
                            .fill(.white)
                            .frame(width: 160, height: 160)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 60))
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                    .onTapGesture {
                        toggleRecording()
                    }

                    Text(isRecording ? "Listening..." : "Tap to Talk")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(isRecording ? .red : .primary)

                    if !recordingText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You said:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(recordingText)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    if !aiResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Response:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(aiResponse)
                                .font(.body)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    QuickActionButton(title: "What's next?", icon: "arrow.right.circle")
                    QuickActionButton(title: "Show today", icon: "calendar.circle")
                    QuickActionButton(title: "Move task", icon: "arrow.triangle.2.circlepath")
                    QuickActionButton(title: "Add new task", icon: "plus.circle")
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Voice Agent")
            .padding()
        }
    }

    private func toggleRecording() {
        isRecording.toggle()

        if isRecording {
            recordingText = ""
            aiResponse = ""
            currentTopic = "Listening..."
        } else {
            currentTopic = "Processing..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                recordingText = "Add workout to tomorrow at 6 AM"
                currentTopic = "Scheduling workout"

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    aiResponse = "I've added your workout to tomorrow at 6 AM. You have a free slot then, so it fits perfectly!"
                    currentTopic = "Task added successfully"
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

#Preview {
    VoiceAgentView()
}