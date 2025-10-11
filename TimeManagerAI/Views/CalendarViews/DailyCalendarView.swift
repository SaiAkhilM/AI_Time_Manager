import SwiftUI

struct DailyCalendarView: View {
    @State private var selectedDate = Date()
    @State private var scrollOffset: CGFloat = 0

    private let timeSlots = Array(6...23)
    private let sampleTasks: [SampleTimeBlock] = [
        SampleTimeBlock(title: "5C Class", startHour: 8, endHour: 9, priority: .medium),
        SampleTimeBlock(title: "ODE Class", startHour: 10, endHour: 11, priority: .medium),
        SampleTimeBlock(title: "Meeting with Kathryn", startHour: 13, endHour: 14, priority: .event),
        SampleTimeBlock(title: "Work Block", startHour: 14, endHour: 17, priority: .high),
        SampleTimeBlock(title: "M24 Class", startHour: 17, endHour: 18, priority: .event),
        SampleTimeBlock(title: "Gym", startHour: 19, endHour: 20, priority: .none)
    ]

    var body: some View {
        VStack(spacing: 0) {
            DateHeader(selectedDate: $selectedDate)

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(timeSlots, id: \.self) { hour in
                            TimeSlotRow(
                                hour: hour,
                                tasks: sampleTasks.filter { $0.startHour == hour },
                                width: geometry.size.width
                            )
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollToCurrentTime()
                        }
                    }
                }
            }
        }
    }

    private func scrollToCurrentTime() {
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 6 && currentHour <= 23 {
            let targetOffset = CGFloat(currentHour - 6) * 60
            scrollOffset = targetOffset
        }
    }
}

struct DateHeader: View {
    @Binding var selectedDate: Date

    var body: some View {
        HStack {
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDate, format: .dateTime.weekday(.wide))
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(selectedDate, format: .dateTime.month().day())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct TimeSlotRow: View {
    let hour: Int
    let tasks: [SampleTimeBlock]
    let width: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                Text("\(hour):00")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50)

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 45)
            }

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 0.5)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 60)

                    ForEach(tasks, id: \.title) { task in
                        TaskBlock(task: task)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(height: 60)
    }
}

struct TaskBlock: View {
    let task: SampleTimeBlock

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("\(task.startHour):00 - \(task.endHour):00")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(task.priority.color)
        .cornerRadius(6)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

struct SampleTimeBlock {
    let title: String
    let startHour: Int
    let endHour: Int
    let priority: TaskPriority
}

enum TaskPriority {
    case high, medium, event, none

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .event: return .blue
        case .none: return .gray
        }
    }
}

#Preview {
    DailyCalendarView()
}