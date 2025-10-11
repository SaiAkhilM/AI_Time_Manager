import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct TaskActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskAttributes.self) { context in
            TaskActivityView(state: context.state)
                .padding()
                .background(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Task")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.taskTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Time Remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.timeRemaining)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(context.state.timeProgress > 0.8 ? .red : .primary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        ProgressView(value: context.state.timeProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(context.state.priorityColor)))

                        if context.state.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color(context.state.priorityColor))
            } compactTrailing: {
                Text(context.state.timeRemaining)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(context.state.timeProgress > 0.8 ? .red : .primary)
            } minimal: {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color(context.state.priorityColor))
            }
        }
    }
}

@available(iOS 16.1, *)
struct TaskActivityView: View {
    let state: TaskAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Task")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(state.taskTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }

                Spacer()

                if state.isCompleted {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Time Left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(state.timeRemaining)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(state.timeProgress > 0.8 ? .red : .primary)
                    }
                }
            }

            if !state.isCompleted {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(state.timeProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }

                    ProgressView(value: state.timeProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(state.priorityColor)))
                        .scaleEffect(y: 2)
                }
            }

            HStack {
                Text("Started: \(state.startTime.formatted(.dateTime.hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Due: \(state.endTime.formatted(.dateTime.hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

#if DEBUG
@available(iOS 16.1, *)
#Preview("Task Activity", as: .content, using: TaskAttributes(taskId: "preview")) {
    TaskActivityWidget()
} contentStates: {
    TaskAttributes.ContentState(
        taskTitle: "Complete iOS App Development",
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
        priority: "red",
        isCompleted: false
    )

    TaskAttributes.ContentState(
        taskTitle: "Review Pull Requests",
        startTime: Date().addingTimeInterval(-1800),
        endTime: Date().addingTimeInterval(900),
        priority: "orange",
        isCompleted: true
    )
}
#endif