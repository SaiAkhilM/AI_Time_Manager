import SwiftUI
import CoreData

struct DocEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var documentViewModel: DocumentViewModel
    @State private var isEditing = false

    init() {
        self._documentViewModel = StateObject(wrappedValue: DocumentViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if documentViewModel.documentContent.length > 0 {
                    if isEditing {
                        RichTextEditor(attributedText: $documentViewModel.documentContent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                AttributedTextView(attributedText: documentViewModel.documentContent)
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
                    VStack {
                        ProgressView("Generating weekly document...")
                            .padding()

                        Text("Loading your schedule and tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let errorMessage = documentViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Life Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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
                        documentViewModel.generateWeeklyDocument()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                documentViewModel.generateWeeklyDocument()
            }
        }
    }
}

struct AttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = [.link, .phoneNumber]
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
    }
}

#Preview {
    DocEditorView()
}