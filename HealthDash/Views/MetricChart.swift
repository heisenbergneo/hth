import Charts
import SwiftUI

struct MetricChart: View {
    let metric: HealthMetric
    let values: [DailyValue]
    var compact = false

    @State private var selectedDate: Date?

    private var selectedValue: DailyValue? {
        guard let selectedDate else { return nil }
        return values.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        if compact {
            chart
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
        } else {
            chart
                .chartXSelection(value: $selectedDate)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(values) { item in
                switch metric.chartStyle {
                case .bar:
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value(metric.title, item.value)
                    )
                    .foregroundStyle(metric.color.gradient)
                    .cornerRadius(3)
                case .line:
                    LineMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value(metric.title, item.value)
                    )
                    .foregroundStyle(metric.color)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value(metric.title, item.value)
                    )
                    .foregroundStyle(metric.color)
                    .symbolSize(compact ? 10 : 24)
                }
            }

            if let selectedValue {
                RuleMark(x: .value("Selected", selectedValue.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .annotation(
                        position: .top,
                        spacing: 4,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        VStack(spacing: 2) {
                            Text(selectedValue.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(metric.formatWithUnit(selectedValue.value))
                                .font(.caption.bold())
                        }
                        .padding(6)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: metric.chartStyle == .bar))
    }
}
