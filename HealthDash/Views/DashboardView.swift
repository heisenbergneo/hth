import SwiftUI

struct DashboardView: View {
    @Environment(HealthStore.self) private var health

    var body: some View {
        @Bindable var health = health

        ScrollView {
            VStack(spacing: 16) {
                Picker("Range", selection: $health.range) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if let errorMessage = health.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                    ForEach(HealthMetric.allCases) { metric in
                        NavigationLink(value: metric) {
                            MetricCard(metric: metric, values: health.series[metric] ?? [])
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Metrics you haven't granted access to, or that have no recordings, show “No data”. You can change access in Settings › Health › Data Access & Devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Health")
        .navigationDestination(for: HealthMetric.self) { metric in
            MetricDetailView(metric: metric)
        }
        .overlay {
            if health.isLoading && health.series.isEmpty {
                ProgressView("Reading Apple Health…")
            }
        }
        .refreshable { await health.load() }
        .task { await health.connectAndLoad() }
    }
}

struct MetricCard: View {
    let metric: HealthMetric
    let values: [DailyValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(metric.title, systemImage: metric.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(metric.color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            if let latest = values.last {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.format(latest.value))
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text(metric.unitLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(latest.date.relativeDayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                MetricChart(metric: metric, values: values, compact: true)
                    .frame(height: 70)
            } else {
                Text("No data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
