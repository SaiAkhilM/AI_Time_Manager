import SwiftUI
import CoreData

struct DailyCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var calendarViewModel: CalendarViewModel
    @State private var scrollOffset: CGFloat = 0

    private let timeSlots = Array(6...23)

    init() {
        self._calendarViewModel = StateObject(wrappedValue: CalendarViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        VStack(spacing: 0) {
            DateHeader(
                selectedDate: $calendarViewModel.selectedDate,
                onDateChange: { days in
                    calendarViewModel.changeDate(by: days)
                }
            )

            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(timeSlots, id: \.self) { hour in
                                TimeSlotRow(
                                    hour: hour,
                                    tasks: getTasksForHour(hour),
                                    events: getEventsForHour(hour),
                                    width: geometry.size.width
                                )
                                .id(hour)
                            }
                        }
                    }
                    .onAppear {
                        let currentHour = Calendar.current.component(.hour, from: Date())
                        if currentHour >= 6 && currentHour <= 23 && Calendar.current.isDateInToday(calendarViewModel.selectedDate) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(currentHour, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: calendarViewModel.selectedDate) { _ in
                        if Calendar.current.isDateInToday(calendarViewModel.selectedDate) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                let currentHour = Calendar.current.component(.hour, from: Date())
                                if currentHour >= 6 && currentHour <= 23 {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        proxy.scrollTo(currentHour, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if let errorMessage = calendarViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            calendarViewModel.refreshData()
        }
    }

    private func getTasksForHour(_ hour: Int) -> [TaskEntity] {
        return calendarViewModel.tasks.filter { task in
            guard let startTime = task.startTime else { return false }
            let taskHour = Calendar.current.component(.hour, from: startTime)
            return taskHour == hour
        }
    }

    private func getEventsForHour(_ hour: Int) -> [Event] {
        return calendarViewModel.events.filter { event in
            let startTime = event.startTime
            let eventHour = Calendar.current.component(.hour, from: startTime)
            return eventHour == hour
        }
    }

}

struct DateHeader: View {
    @Binding var selectedDate: Date
    let onDateChange: (Int) -> Void

    var body: some View {
        HStack {
            Button(action: { onDateChange(-1) }) {
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

            Button(action: { onDateChange(1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct TimeSlotRow: View {
    let hour: Int
    let tasks: [TaskEntity]
    let events: [Event]
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

                    if tasks.isEmpty && events.isEmpty {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 60)
                    } else {
                        VStack(spacing: 2) {
                            ForEach(tasks, id: \.id) { task in
                                RealTaskBlock(task: task)
                            }

                            ForEach(events, id: \.id) { event in
                                RealEventBlock(event: event)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(height: 60)
    }
}

struct RealTaskBlock: View {
    let task: TaskEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let startTime = task.startTime, let endTime = task.endTime {
                    Text("\(startTime, format: .dateTime.hour().minute()) - \(endTime, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                } else if let startTime = task.startTime {
                    Text("\(startTime, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(task.priorityEnum.color)
        .cornerRadius(6)
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }
}

struct RealEventBlock: View {
    let event: Event

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.isEmpty ? "Untitled Event" : event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                let startTime = event.startTime
                let endTime = event.endTime
                if true {
                    Text("\(startTime, format: .dateTime.hour().minute()) - \(endTime, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }

                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .cornerRadius(6)
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }
}

#Preview {
    DailyCalendarView()
}