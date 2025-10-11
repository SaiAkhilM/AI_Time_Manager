import SwiftUI

struct MonthlyCalendarView: View {
    @State private var currentMonth = Date()
    private let calendar = Calendar.current

    private var monthDays: [Date] {
        guard let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start,
              let monthEnd = calendar.dateInterval(of: .month, for: currentMonth)?.end else {
            return []
        }

        var days: [Date] = []

        let startWeekday = calendar.component(.weekday, from: monthStart)
        let daysToAdd = startWeekday - 1

        if let weekStart = calendar.date(byAdding: .day, value: -daysToAdd, to: monthStart) {
            var currentDate = weekStart
            while currentDate < monthEnd {
                days.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }

        return days
    }

    var body: some View {
        VStack(spacing: 0) {
            MonthHeader(currentMonth: $currentMonth)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }

                ForEach(monthDays, id: \.self) { day in
                    MonthDayCell(date: day, currentMonth: currentMonth)
                }
            }
            .background(Color(.systemGray6))

            Spacer()
        }
    }
}

struct MonthHeader: View {
    @Binding var currentMonth: Date

    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private func changeMonth(by months: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: months, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct MonthDayCell: View {
    let date: Date
    let currentMonth: Date
    private let calendar = Calendar.current

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }

    private let sampleEvents: [String] = ["Meeting", "Deadline", "Class"]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(dayNumber)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isToday ? .white : (isInCurrentMonth ? .primary : .secondary))
                    .frame(width: 20, height: 20)
                    .background(isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())

                Spacer()
            }

            if isInCurrentMonth && Int(dayNumber)! % 7 == 0 {
                VStack(alignment: .leading, spacing: 1) {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()
        }
        .frame(height: 60)
        .padding(4)
        .background(Color(.systemBackground))
        .opacity(isInCurrentMonth ? 1.0 : 0.5)
    }
}

#Preview {
    MonthlyCalendarView()
}