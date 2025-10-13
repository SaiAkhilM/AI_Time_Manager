import SwiftUI

// Ultra-Safe Static AI Insights - NO Core Data dependencies
struct AIInsightsView: View {
    @State private var selectedTab = 0
    @State private var featuresEnabled = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AIInsightsHeader()

                Picker("Insights", selection: $selectedTab) {
                    Text("Optimization").tag(0)
                    Text("Deadlines").tag(1)
                    Text("Estimates").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if featuresEnabled {
                    insightContent
                } else {
                    enableFeaturesView
                }
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var enableFeaturesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("AI-Powered Analytics")
                .font(.title2)
                .fontWeight(.medium)

            Text("Get intelligent insights about your productivity patterns and optimization opportunities")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                InsightPlaceholderCard(
                    icon: "lightbulb.fill",
                    title: "Schedule Optimization",
                    description: "AI analyzes your productivity patterns to suggest optimal time blocks",
                    enabled: featuresEnabled
                )

                InsightPlaceholderCard(
                    icon: "clock.fill",
                    title: "Deadline Risk Analysis",
                    description: "Predicts deadline risks and suggests schedule rebalancing",
                    enabled: featuresEnabled
                )

                InsightPlaceholderCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Time Estimation Learning",
                    description: "Improves task duration predictions based on your history",
                    enabled: featuresEnabled
                )
            }

            Spacer()

            Button("Enable AI Insights") {
                enableFeatures()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var insightContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case 0:
                    optimizationInsights
                case 1:
                    deadlineInsights
                case 2:
                    estimationInsights
                default:
                    optimizationInsights
                }
            }
            .padding()
        }
    }

    private var optimizationInsights: some View {
        VStack(spacing: 16) {
            Text("Schedule Optimization")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                OptimizationCard(
                    title: "Peak Productivity Hours",
                    value: "9 AM - 11 AM",
                    insight: "You're 40% more productive during morning hours",
                    color: .green
                )

                OptimizationCard(
                    title: "Focus Block Recommendation",
                    value: "2.5 Hours",
                    insight: "Optimal deep work session length for complex tasks",
                    color: .blue
                )

                OptimizationCard(
                    title: "Meeting-Free Days",
                    value: "Tuesdays & Thursdays",
                    insight: "Schedule important work on these high-focus days",
                    color: .purple
                )
            }

            Text("💡 AI learns from your completed tasks to provide better recommendations over time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var deadlineInsights: some View {
        VStack(spacing: 16) {
            Text("Deadline Risk Analysis")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DeadlineRiskCard(
                    title: "Project Alpha",
                    deadline: "Oct 25",
                    riskLevel: "Medium",
                    recommendation: "Consider extending by 2 days or reducing scope",
                    color: .orange
                )

                DeadlineRiskCard(
                    title: "Weekly Report",
                    deadline: "Oct 18",
                    riskLevel: "Low",
                    recommendation: "On track - maintain current pace",
                    color: .green
                )

                DeadlineRiskCard(
                    title: "Client Presentation",
                    deadline: "Oct 20",
                    riskLevel: "High",
                    recommendation: "Urgent: Allocate 6 hours today",
                    color: .red
                )
            }

            Text("⚠️ AI analyzes your work patterns and current workload to predict deadline risks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var estimationInsights: some View {
        VStack(spacing: 16) {
            Text("Time Estimation Accuracy")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                EstimationCard(
                    taskType: "Code Review",
                    estimatedTime: "30 min",
                    actualTime: "25 min",
                    accuracy: "95%",
                    color: .green
                )

                EstimationCard(
                    taskType: "Writing Tasks",
                    estimatedTime: "1 hour",
                    actualTime: "1.5 hours",
                    accuracy: "67%",
                    color: .orange
                )

                EstimationCard(
                    taskType: "Meetings",
                    estimatedTime: "45 min",
                    actualTime: "50 min",
                    accuracy: "85%",
                    color: .blue
                )
            }

            Text("📊 AI improves time estimates by learning from your completed tasks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func enableFeatures() {
        featuresEnabled = true
    }
}

struct AIInsightsHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("AI-Powered Insights")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            Text("Intelligent analysis of your productivity patterns and scheduling optimization")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct InsightPlaceholderCard: View {
    let icon: String
    let title: String
    let description: String
    let enabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(enabled ? "Active" : "Ready")
                .font(.caption)
                .foregroundColor(enabled ? .green : .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((enabled ? Color.green : Color.blue).opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OptimizationCard: View {
    let title: String
    let value: String
    let insight: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Text(insight)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DeadlineRiskCard: View {
    let title: String
    let deadline: String
    let riskLevel: String
    let recommendation: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(deadline)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Risk: \(riskLevel)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(6)
                Spacer()
            }

            Text(recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EstimationCard: View {
    let taskType: String
    let estimatedTime: String
    let actualTime: String
    let accuracy: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(taskType)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(accuracy)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            HStack {
                Text("Est: \(estimatedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("Actual: \(actualTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    AIInsightsView()
}