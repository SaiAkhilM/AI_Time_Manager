import SwiftUI

struct CalendarContainerView: View {
    @State private var selectedCalendarView = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Calendar View", selection: $selectedCalendarView) {
                    Text("Daily").tag(0)
                    Text("Weekly").tag(1)
                    Text("Monthly").tag(2)
                    Text("Yearly").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Group {
                    switch selectedCalendarView {
                    case 0:
                        DailyCalendarView()
                    case 1:
                        WeeklyCalendarView()
                    case 2:
                        MonthlyCalendarView()
                    case 3:
                        YearlyCalendarView()
                    default:
                        DailyCalendarView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Calendar")
        }
    }
}