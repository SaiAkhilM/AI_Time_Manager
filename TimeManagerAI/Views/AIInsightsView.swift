import SwiftUI
import CoreData

struct AIInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var intelligentSchedulingService: IntelligentSchedulingService
    @StateObject private var contextAwareOptimizationService: ContextAwareOptimizationService
    @StateObject private var smartDeadlineManager: SmartDeadlineManager
    @StateObject private var predictiveTimeEstimationService: PredictiveTimeEstimationService

    @State private var isAnalyzing = false
    @State private var selectedTab = 0

    init() {
        let context = PersistenceController.shared.container.viewContext
        self._calendarViewModel = StateObject(wrappedValue: CalendarViewModel(context: context))
        self._intelligentSchedulingService = StateObject(wrappedValue: IntelligentSchedulingService(context: context))
        self._contextAwareOptimizationService = StateObject(wrappedValue: ContextAwareOptimizationService(context: context))
        self._smartDeadlineManager = StateObject(wrappedValue: SmartDeadlineManager(context: context))
        self._predictiveTimeEstimationService = StateObject(wrappedValue: PredictiveTimeEstimationService(context: context))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AIInsightsHeader(isAnalyzing: $isAnalyzing)

                Picker("Insights", selection: $selectedTab) {
                    Text("Optimization").tag(0)
                    Text("Deadlines").tag(1)
                    Text("Estimates").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                TabView(selection: $selectedTab) {
                    OptimizationInsightsView(
                        optimizationService: contextAwareOptimizationService,
                        isAnalyzing: $isAnalyzing
                    )
                    .tag(0)

                    DeadlineInsightsView(
                        deadlineManager: smartDeadlineManager,
                        isAnalyzing: $isAnalyzing
                    )
                    .tag(1)

                    TimeEstimationInsightsView(
                        estimationService: predictiveTimeEstimationService
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAllInsights) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                            .animation(isAnalyzing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isAnalyzing)
                    }
                    .disabled(isAnalyzing)
                }
            }
            .onAppear {
                calendarViewModel.viewDidAppear()
                refreshAllInsights()
            }
        }
    }

    private func refreshAllInsights() {
        isAnalyzing = true

        Task {
            async let optimizationTask = contextAwareOptimizationService.analyzeAndOptimizeSchedule()
            async let deadlineTask = smartDeadlineManager.analyzeDeadlines()

            await optimizationTask
            await deadlineTask

            DispatchQueue.main.async {
                isAnalyzing = false
            }
        }
    }
}

struct AIInsightsHeader: View {
    @Binding var isAnalyzing: Bool

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

                if isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
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

struct OptimizationInsightsView: View {
    @ObservedObject var optimizationService: ContextAwareOptimizationService
    @Binding var isAnalyzing: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let metrics = optimizationService.productivityMetrics {
                    ProductivityMetricsCard(metrics: metrics)
                }

                ForEach(optimizationService.optimizationSuggestions, id: \.id) { suggestion in
                    OptimizationSuggestionCard(suggestion: suggestion)
                }

                if optimizationService.optimizationSuggestions.isEmpty && !isAnalyzing {
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "No Optimization Suggestions",
                        description: "Your schedule looks well-optimized! Keep up the great work."
                    )
                }
            }
            .padding()
        }
    }
}

struct DeadlineInsightsView: View {
    @ObservedObject var deadlineManager: SmartDeadlineManager
    @Binding var isAnalyzing: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(deadlineManager.deadlineAnalyses, id: \.taskId) { analysis in
                    DeadlineAnalysisCard(analysis: analysis)
                }

                ForEach(deadlineManager.recommendations, id: \.id) { recommendation in
                    DeadlineRecommendationCard(recommendation: recommendation)
                }

                if deadlineManager.deadlineAnalyses.isEmpty && !isAnalyzing {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No Deadline Analysis",
                        description: "Add tasks with deadlines to see AI-powered deadline insights."
                    )
                }
            }
            .padding()
        }
    }
}

struct TimeEstimationInsightsView: View {
    @ObservedObject var estimationService: PredictiveTimeEstimationService

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                EstimationAccuracyCard(accuracy: estimationService.estimationAccuracy)

                ProductivityPatternsCard(patterns: estimationService.productivityPatterns)

                RecentEstimatesCard(estimates: estimationService.recentEstimates)
            }
            .padding()
        }
    }
}

struct ProductivityMetricsCard: View {
    let metrics: ProductivityMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Productivity Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 8) {
                MetricRow(
                    title: "Completion Rate",
                    value: "\(Int(metrics.completionRate * 100))%",
                    color: metrics.completionRate > 0.8 ? .green : metrics.completionRate > 0.6 ? .orange : .red
                )

                MetricRow(
                    title: "Avg Task Duration",
                    value: formatDuration(metrics.averageTaskDuration),
                    color: .blue
                )

                MetricRow(
                    title: "Overdue Tasks",
                    value: "\(metrics.overdueTasks)",
                    color: metrics.overdueTasks == 0 ? .green : .red
                )

                MetricRow(
                    title: "Weekly Workload",
                    value: "\(Int(metrics.weeklyWorkload / 3600))h",
                    color: metrics.weeklyWorkload > 40 * 3600 ? .red : .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct OptimizationSuggestionCard: View {
    let suggestion: OptimizationSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text(suggestion.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(String(describing: suggestion.impact).capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(suggestion.impact.color).opacity(0.2))
                    .foregroundColor(Color(suggestion.impact.color))
                    .cornerRadius(8)
            }

            Text(suggestion.description)
                .font(.body)
                .foregroundColor(.secondary)

            if !suggestion.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Items:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(suggestion.actionItems, id: \.self) { item in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(item)
                                .font(.caption)
                        }
                    }
                }
            }

            if suggestion.estimatedTimeSaved > 0 {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.green)
                    Text("Potential time saved: \(formatDuration(suggestion.estimatedTimeSaved))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DeadlineAnalysisCard: View {
    let analysis: DeadlineAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(analysis.riskLevel.color))
                Text("Task Deadline Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(analysis.riskLevel.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(analysis.riskLevel.color).opacity(0.2))
                    .foregroundColor(Color(analysis.riskLevel.color))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Current Deadline: \(analysis.currentDeadline.formatted(.dateTime.month().day().hour().minute()))")
                    .font(.body)

                if let suggested = analysis.suggestedDeadline {
                    Text("Suggested Deadline: \(suggested.formatted(.dateTime.month().day().hour().minute()))")
                        .font(.body)
                        .foregroundColor(.blue)
                }

                Text("Workload Pressure: \(Int(analysis.workloadPressure * 100))%")
                    .font(.body)
            }

            if !analysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(analysis.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(recommendation)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DeadlineRecommendationCard: View {
    let recommendation: DeadlineRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                Text("Deadline Recommendation")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text(recommendation.reasoning)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EstimationAccuracyCard: View {
    let accuracy: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Estimation Accuracy")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(accuracy * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(accuracy > 0.8 ? .green : accuracy > 0.6 ? .orange : .red)
            }

            ProgressView(value: accuracy)
                .progressViewStyle(LinearProgressViewStyle(tint: accuracy > 0.8 ? .green : accuracy > 0.6 ? .orange : .red))
                .scaleEffect(y: 2)

            Text("Your time estimation accuracy based on completed tasks")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProductivityPatternsCard: View {
    let patterns: [ProductivityPattern]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.purple)
                Text("Productivity Patterns")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if patterns.isEmpty {
                Text("No patterns available yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                let topPatterns = patterns.sorted { $0.averageEfficiency > $1.averageEfficiency }.prefix(3)

                ForEach(Array(topPatterns), id: \.hour) { pattern in
                    HStack {
                        Text("\(pattern.hour):00")
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)

                        ProgressView(value: pattern.averageEfficiency)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))

                        Text("\(Int(pattern.averageEfficiency * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentEstimatesCard: View {
    let estimates: [TimeEstimate]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.green)
                Text("Recent Estimates")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if estimates.isEmpty {
                Text("No recent estimates")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(estimates.prefix(3), id: \.estimatedDuration) { estimate in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(estimate.formattedDuration)
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Confidence: \(Int(estimate.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ProgressView(value: estimate.confidence)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: 60)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    AIInsightsView()
}