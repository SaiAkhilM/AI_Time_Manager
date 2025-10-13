import SwiftUI

// Ultra-Safe Static Document Editor - NO Core Data dependencies
struct DocEditorView: View {
    @State private var documentContent = ""
    @State private var isEditing = false
    @State private var featuresEnabled = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if featuresEnabled {
                    if isEditing {
                        TextEditor(text: $documentContent)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(documentContent.isEmpty ? sampleDocument : documentContent)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .onTapGesture {
                                        isEditing = true
                                    }

                                Spacer(minLength: 100)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Document Editor")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Create and edit your weekly planning documents")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Enable Document Features") {
                            enableFeatures()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Life Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if featuresEnabled {
                        if isEditing {
                            Button("Done") {
                                isEditing = false
                            }
                        } else {
                            Button("Edit") {
                                isEditing = true
                            }
                        }

                        Button(action: {
                            generateSampleDocument()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }

    private func enableFeatures() {
        featuresEnabled = true
        if documentContent.isEmpty {
            documentContent = sampleDocument
        }
    }

    private func generateSampleDocument() {
        documentContent = sampleDocument
    }

    private var sampleDocument: String {
        """
        # Weekly Planning Document

        ## This Week's Goals
        • Complete important project milestones
        • Maintain work-life balance
        • Focus on high-priority tasks

        ## Monday Tasks
        - Morning: Team standup meeting
        - Afternoon: Project review and planning
        - Evening: Personal time

        ## Tuesday Tasks
        - Focus work block: 9 AM - 12 PM
        - Lunch meeting with clients
        - Administrative tasks

        ## Notes
        Document editing features are ready! You can:
        • Edit this text by tapping "Edit"
        • Generate new content with the refresh button
        • Full rich text features coming soon

        ---

        Features will be connected to Core Data for automatic generation from your actual tasks and schedule.
        """
    }
}

#Preview {
    DocEditorView()
}