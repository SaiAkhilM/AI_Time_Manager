import SwiftUI

// Ultra-Safe Static Calendar - NO Core Data dependencies
struct CalendarContainerView: View {
    @State private var selectedCalendarView = 0
    @State private var featuresEnabled = false

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
                        StaticDailyCalendarView(featuresEnabled: $featuresEnabled)
                    case 1:
                        StaticWeeklyCalendarView(featuresEnabled: $featuresEnabled)
                    case 2:
                        StaticMonthlyCalendarView(featuresEnabled: $featuresEnabled)
                    case 3:
                        StaticYearlyCalendarView(featuresEnabled: $featuresEnabled)
                    default:
                        StaticDailyCalendarView(featuresEnabled: $featuresEnabled)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Calendar")
        }
    }
}

// Static Daily Calendar View
struct StaticDailyCalendarView: View {
    @Binding var featuresEnabled: Bool
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Date picker
            DatePicker("Selected Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()

            if featuresEnabled {
                // Time slots with sample data
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(timeSlots, id: \.self) { timeSlot in
                            DailyTimeSlotView(timeSlot: timeSlot)
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Daily Calendar View")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("Time slots and tasks will appear here")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Button("Enable Calendar Features") {
                        featuresEnabled = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var timeSlots: [String] {
        (6...22).map { hour in
            String(format: "%02d:00", hour)
        }
    }
}

struct DailyTimeSlotView: View {
    let timeSlot: String

    var body: some View {
        HStack {
            Text(timeSlot)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 60)
                .overlay {
                    if timeSlot == "09:00" {
                        Text("Sample Meeting")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(4)
                    } else if timeSlot == "14:00" {
                        Text("Sample Task")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .background(Color.orange.opacity(0.3))
                            .cornerRadius(4)
                    }
                }

            Spacer()
        }
        .padding(.horizontal)
    }
}

// Static Weekly Calendar View
struct StaticWeeklyCalendarView: View {
    @Binding var featuresEnabled: Bool

    var body: some View {
        VStack(spacing: 20) {
            if featuresEnabled {
                Text("Weekly calendar grid would go here")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Weekly Calendar View")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Week view with daily columns")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button("Enable Calendar Features") {
                    featuresEnabled = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Static Monthly Calendar View
struct StaticMonthlyCalendarView: View {
    @Binding var featuresEnabled: Bool

    var body: some View {
        VStack(spacing: 20) {
            if featuresEnabled {
                Text("Monthly calendar grid would go here")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "calendar.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Monthly Calendar View")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Month grid with events")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button("Enable Calendar Features") {
                    featuresEnabled = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Static Yearly Calendar View
struct StaticYearlyCalendarView: View {
    @Binding var featuresEnabled: Bool

    var body: some View {
        VStack(spacing: 20) {
            if featuresEnabled {
                Text("Yearly calendar overview would go here")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Yearly Calendar View")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Year overview with months")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button("Enable Calendar Features") {
                    featuresEnabled = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}