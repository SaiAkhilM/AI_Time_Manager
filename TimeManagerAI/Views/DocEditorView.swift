import SwiftUI

struct DocEditorView: View {
    @State private var documentText: AttributedString = {
        let sampleText = """
        Monday:
        • 8:00 to 9:05 - 5C Class
          ○ Finish discussion problems (link: coursework.edu)
          ○ Review lecture slides

        Tuesday:
        • 8:30 to 11:30 - 5C Lab
        • 1:30 - Meeting with Kathryn
        • 5:20 - M24 Class

        Wednesday:
        • 8:00 to 9:05 - 5C Class
        • 10:40 - ODE Class
        • 2:00 to 5:00 - Work Block

        Future Events:
        • Dec 15 - Transfer college essays due
        • Jan 20 - Doctor appointment

        Goals This Week:
        • Exercise 5 times
        • Complete all coursework
        • Work 10 hours on startup

        Unscheduled Tasks:
        • Finish ODE homework
          ○ Chapter 3 problems
          ○ Review for midterm
        • Apply to internships
        • Update resume
        """

        var attributed = AttributedString(sampleText)

        if let range = attributed.range(of: "5C Class") {
            attributed[range].foregroundColor = .orange
            attributed[range].font = .body.weight(.medium)
        }

        if let range = attributed.range(of: "Finish ODE homework") {
            attributed[range].foregroundColor = .red
            attributed[range].font = .body.weight(.medium)
        }

        if let range = attributed.range(of: "Meeting with Kathryn") {
            attributed[range].foregroundColor = .blue
            attributed[range].font = .body.weight(.medium)
        }

        return attributed
    }()

    @State private var showingFormatToolbar = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showingFormatToolbar {
                    FormatToolbar()
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .background(Color(.systemGray6))
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(documentText)
                            .font(.system(.body, design: .default))
                            .lineSpacing(4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .onTapGesture {
                                showingFormatToolbar.toggle()
                            }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Life Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFormatToolbar.toggle() }) {
                        Image(systemName: "textformat")
                    }
                }
            }
        }
    }
}

struct FormatToolbar: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FormatButton(icon: "bold", title: "Bold")
                FormatButton(icon: "italic", title: "Italic")
                FormatButton(icon: "underline", title: "Underline")

                Divider()
                    .frame(height: 20)

                ColorButton(color: .red, title: "High")
                ColorButton(color: .orange, title: "Medium")
                ColorButton(color: .yellow, title: "Event")
                ColorButton(color: .black, title: "Normal")

                Divider()
                    .frame(height: 20)

                FormatButton(icon: "link", title: "Link")
                FormatButton(icon: "list.bullet", title: "List")
            }
            .padding(.horizontal)
        }
    }
}

struct FormatButton: View {
    let icon: String
    let title: String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.blue)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct ColorButton: View {
    let color: Color
    let title: String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
    }
}

#Preview {
    DocEditorView()
}