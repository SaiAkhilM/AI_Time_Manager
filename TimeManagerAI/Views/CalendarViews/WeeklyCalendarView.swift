import SwiftUI
import CoreData

struct WeeklyCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var calendarViewModel: CalendarViewModel
    @State private var currentWeek = Date()
    private let calendar = Calendar.current

    init() {
        self._calendarViewModel = StateObject(wrappedValue: CalendarViewModel(context: PersistenceController.shared.container.viewContext))
    }

    private var weekDays: [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: currentWeek)?.start else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            WeekHeader(currentWeek: $currentWeek, weekDays: weekDays)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                    ForEach(weekDays, id: \.self) { day in
                        DayColumn(date: day, calendarViewModel: calendarViewModel)
                    }
                }
            }
        }
        .onAppear {
            calendarViewModel.refreshData()
        }
        .onChange(of: currentWeek) { _ in
            calendarViewModel.refreshData()
        }
    }
}

struct WeekHeader: View {
    @Binding var currentWeek: Date
    let weekDays: [Date]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(weekDays.first ?? Date(), format: .dateTime.month().day())
                + Text(" - ")
                + Text(weekDays.last ?? Date(), format: .dateTime.month().day())

                Spacer()

                Button(action: { changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()

            HStack(spacing: 1) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text(day, format: .dateTime.day())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Calendar.current.isDateInToday(day) ? .blue : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Calendar.current.isDateInToday(day) ? Color.blue.opacity(0.1) : Color.clear)
                }
            }
            .background(Color(.systemGray6))
        }
    }

    private func changeWeek(by weeks: Int) {
        if let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: currentWeek) {
            currentWeek = newWeek
        }
    }
}

struct DayColumn: View {
    let date: Date
    let calendarViewModel: CalendarViewModel
    @State private var showingTaskSheet = false
    @State private var selectedTask: Task?

    private var dayTasks: [Task] {
        return calendarViewModel.getTasksForDate(date)
    }

    private var dayEvents: [Event] {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)

        do {
            return try calendarViewModel.context.fetch(request)
        } catch {
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(dayTasks, id: \.id) { task in
                WeekTaskBlock(task: task)
                    .onTapGesture {
                        selectedTask = task
                        showingTaskSheet = true
                    }
            }

            ForEach(dayEvents, id: \.id) { event in
                WeekEventBlockReal(event: event)
            }

            Spacer(minLength: 200)
        }
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .top)
        .padding(.horizontal, 2)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingTaskSheet) {
            if let task = selectedTask {
                TaskDetailSheet(task: task, calendarViewModel: calendarViewModel)
            }
        }
    }
}

struct WeekTaskBlock: View {
    let task: Task

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(task.title ?? "Untitled Task")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let startTime = task.startTime {
                    Text(startTime.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(task.priorityEnum.color)
        .cornerRadius(4)
    }
}

struct WeekEventBlockReal: View {
    let event: Event

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled Event")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let startTime = event.startTime {
                    Text(startTime.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(Color.blue)
        .cornerRadius(4)
    }
}

struct TaskDetailSheet: View {
    let task: Task
    let calendarViewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Details")
                        .font(.headline)

                    Text(task.title ?? "Untitled Task")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(task.priorityEnum.color)
                }

                if let description = task.taskDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                    }
                }

                if let startTime = task.startTime, let endTime = task.endTime {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.headline)
                        Text("\(startTime.formatted(.dateTime.hour().minute())) - \(endTime.formatted(.dateTime.hour().minute()))")
                            .font(.body)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.headline)
                    Text(task.priorityEnum.displayName)
                        .font(.body)
                        .foregroundColor(task.priorityEnum.color)
                }

                if let linkedURL = task.linkedURL, !linkedURL.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link")
                            .font(.headline)
                        Link(linkedURL, destination: URL(string: linkedURL) ?? URL(string: "https://example.com")!)
                            .font(.body)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    if !task.isCompleted {
                        Button(action: {
                            calendarViewModel.completeTask(task)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark Complete")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }

                    Button(action: {
                        calendarViewModel.deleteTask(task)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Task")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle("Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WeeklyCalendarView()
}