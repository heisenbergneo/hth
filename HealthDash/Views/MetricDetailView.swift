import SwiftUI

struct MetricDetailView: View {
    @Environment(HealthStore.self) private var health
    let metric: HealthMetric

    private var values: [DailyValue] { health.series[metric] ?? [] }

    var body: some View {
        @Bindable var health = health

        List {
            Section {
                Picker("Range", selection: $health.range) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if values.isEmpty {
                ContentUnavailableView(
                    "No \(metric.title) Data",
                    systemImage: metric.symbol,
                    description: Text("Nothing recorded in this period, or HealthDash doesn't have access to this data type.")
                )
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        statistics
                        MetricChart(metric: metric, values: values)
                            .frame(height: 240)
                    }
                    .padding(.vertical, 8)
                }

                Section("Daily Values") {
                    ForEach(values.reversed()) { item in
                        HStack {
                            Text(item.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            Spacer()
                            Text(metric.formatWithUnit(item.value))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(metric.title)
        .refreshable { await health.load() }
    }

    private var statistics: some View {
        let numbers = values.map(\.value)
        let average = numbers.reduce(0, +) / Double(numbers.count)

        return HStack(alignment: .top) {
            if metric.aggregation == .latest, let latest = values.last {
                StatView(title: metric.summaryCaption, value: metric.formatWithUnit(latest.value), color: metric.color)
            } else {
                StatView(title: metric.summaryCaption, value: metric.formatWithUnit(average), color: metric.color)
            }
            Spacer()
            StatView(title: "Low", value: metric.formatWithUnit(numbers.min() ?? 0))
            Spacer()
            StatView(title: "High", value: metric.formatWithUnit(numbers.max() ?? 0))
            if metric.aggregation == .sum && metric != .sleep {
                Spacer()
                StatView(title: "Total", value: metric.formatWithUnit(numbers.reduce(0, +)))
            }
        }
    }
}

private struct StatView: View {
    let title: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
