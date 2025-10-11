import SwiftUI

struct WeeklyCalendarView: View {
    @State private var currentWeek = Date()
    private let calendar = Calendar.current

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
                        DayColumn(date: day)
                    }
                }
            }
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

    private let sampleEvents: [WeekEvent] = [
        WeekEvent(title: "5C", time: "8:00", priority: .medium, dayOffset: 0),
        WeekEvent(title: "ODE", time: "10:40", priority: .medium, dayOffset: 0),
        WeekEvent(title: "Work", time: "14:00", priority: .high, dayOffset: 0),
        WeekEvent(title: "5C Lab", time: "8:30", priority: .medium, dayOffset: 1),
        WeekEvent(title: "Meeting", time: "13:30", priority: .event, dayOffset: 1),
        WeekEvent(title: "5C", time: "8:00", priority: .medium, dayOffset: 2),
        WeekEvent(title: "Gym", time: "19:00", priority: .none, dayOffset: 2)
    ]

    private var dayEvents: [WeekEvent] {
        let dayOfWeek = Calendar.current.component(.weekday, from: date) - 1
        return sampleEvents.filter { $0.dayOffset == dayOfWeek }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(dayEvents, id: \.title) { event in
                WeekEventBlock(event: event)
            }

            Spacer(minLength: 200)
        }
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .top)
        .padding(.horizontal, 2)
        .background(Color(.systemBackground))
    }
}

struct WeekEventBlock: View {
    let event: WeekEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(event.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(event.time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(event.priority.color)
        .cornerRadius(4)
    }
}

struct WeekEvent {
    let title: String
    let time: String
    let priority: TaskPriority
    let dayOffset: Int
}

#Preview {
    WeeklyCalendarView()
}