import SwiftUI
import CoreData

struct VoiceAgentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = VoiceAgentViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Currently talking about:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.currentTopic)
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
                            .scaleEffect(viewModel.isRecording ? 1.1 + viewModel.audioLevel * 0.3 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)

                        Circle()
                            .fill(.white)
                            .frame(width: 160, height: 160)

                        if viewModel.isProcessing {
                            ProgressView()
                                .scaleEffect(2.0)
                                .tint(.blue)
                        } else if viewModel.isPlayingResponse {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 60))
                                .foregroundColor(viewModel.isRecording ? .red : .blue)
                        }
                    }
                    .onTapGesture {
                        viewModel.toggleRecording(context: viewContext)
                    }
                    .disabled(viewModel.isProcessing)

                    Text(getStatusText())
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(getStatusColor())

                    if !viewModel.userTranscript.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You said:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(viewModel.userTranscript)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .slide))
                    }

                    if !viewModel.aiResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Response:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView {
                                Text(viewModel.aiResponse)
                                    .font(.body)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .frame(maxHeight: 120)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .slide))
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    QuickActionButton(
                        title: "What's next?",
                        icon: "arrow.right.circle",
                        action: { viewModel.handleQuickAction(.whatsNext, context: viewContext) }
                    )
                    QuickActionButton(
                        title: "Show today",
                        icon: "calendar.circle",
                        action: { viewModel.handleQuickAction(.showToday, context: viewContext) }
                    )
                    QuickActionButton(
                        title: "Move task",
                        icon: "arrow.triangle.2.circlepath",
                        action: { viewModel.handleQuickAction(.moveTask, context: viewContext) }
                    )
                    QuickActionButton(
                        title: "Add new task",
                        icon: "plus.circle",
                        action: { viewModel.handleQuickAction(.addNewTask, context: viewContext) }
                    )
                }
                .padding(.horizontal)
                .disabled(viewModel.isProcessing || viewModel.isRecording)

                Spacer()
            }
            .navigationTitle("Voice Agent")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.clearConversation()
                    }
                    .disabled(viewModel.isProcessing || viewModel.isRecording)
                }
            }
            .padding()
        }
    }

    private func getStatusText() -> String {
        if viewModel.isProcessing {
            return "Processing..."
        } else if viewModel.isPlayingResponse {
            return "Speaking..."
        } else if viewModel.isRecording {
            return "Listening..."
        } else {
            return "Tap to Talk"
        }
    }

    private func getStatusColor() -> Color {
        if viewModel.isProcessing {
            return .orange
        } else if viewModel.isPlayingResponse {
            return .green
        } else if viewModel.isRecording {
            return .red
        } else {
            return .primary
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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