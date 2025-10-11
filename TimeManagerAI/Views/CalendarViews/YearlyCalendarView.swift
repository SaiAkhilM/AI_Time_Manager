import SwiftUI

struct YearlyCalendarView: View {
    @State private var currentYear = Date()
    private let calendar = Calendar.current

    private var yearMonths: [Date] {
        guard let yearStart = calendar.dateInterval(of: .year, for: currentYear)?.start else {
            return []
        }

        return (0..<12).compactMap { monthOffset in
            calendar.date(byAdding: .month, value: monthOffset, to: yearStart)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            YearHeader(currentYear: $currentYear)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(yearMonths, id: \.self) { month in
                        MiniMonthView(month: month)
                    }
                }
                .padding()
            }
        }
    }
}

struct YearHeader: View {
    @Binding var currentYear: Date

    var body: some View {
        HStack {
            Button(action: { changeYear(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(currentYear, format: .dateTime.year())
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Button(action: { changeYear(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private func changeYear(by years: Int) {
        if let newYear = Calendar.current.date(byAdding: .year, value: years, to: currentYear) {
            currentYear = newYear
        }
    }
}

struct MiniMonthView: View {
    let month: Date
    private let calendar = Calendar.current

    private var monthName: String {
        month.formatted(.dateTime.month(.wide))
    }

    private var monthDays: [Date] {
        guard let monthStart = calendar.dateInterval(of: .month, for: month)?.start,
              let monthEnd = calendar.dateInterval(of: .month, for: month)?.end else {
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
        VStack(spacing: 4) {
            Text(monthName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.bottom, 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(height: 15)
                }

                ForEach(monthDays, id: \.self) { day in
                    MiniDayCell(date: day, currentMonth: month)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MiniDayCell: View {
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

    private var hasEvents: Bool {
        Int(dayNumber)! % 8 == 0
    }

    var body: some View {
        ZStack {
            if hasEvents && isInCurrentMonth {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
                    .offset(x: 6, y: -6)
            }

            Text(dayNumber)
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .white : (isInCurrentMonth ? .primary : .secondary))
                .frame(width: 20, height: 20)
                .background(isToday ? Color.blue : Color.clear)
                .clipShape(Circle())
        }
        .opacity(isInCurrentMonth ? 1.0 : 0.3)
    }
}

#Preview {
    YearlyCalendarView()
}