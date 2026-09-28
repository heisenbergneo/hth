import HealthKit
import Observation

/// Talks to HealthKit and holds the daily series shown by the UI.
@Observable
@MainActor
final class HealthStore {
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static let readTypes: Set<HKObjectType> = Set(HealthMetric.allCases.map { $0.sampleType as HKObjectType })

    var range: TimeRange = .week {
        didSet {
            guard range != oldValue else { return }
            Task { await load() }
        }
    }
    private(set) var series: [HealthMetric: [DailyValue]] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let store = HKHealthStore()
    private var hasRequestedAuthorization = false
    private var loadGeneration = 0

    /// Asks for read access (the system sheet is shown only the first time), then loads data.
    func connectAndLoad() async {
        if !hasRequestedAuthorization {
            do {
                try await store.requestAuthorization(toShare: [], read: Self.readTypes)
                hasRequestedAuthorization = true
            } catch {
                errorMessage = "Couldn't connect to Apple Health: \(error.localizedDescription)"
                return
            }
        }
        await load()
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        let days = range.days
        isLoading = true
        errorMessage = nil

        var newSeries: [HealthMetric: [DailyValue]] = [:]
        var failures: [String] = []
        for metric in HealthMetric.allCases {
            do {
                newSeries[metric] = try await dailyValues(for: metric, days: days)
            } catch {
                failures.append(metric.title)
            }
        }

        // A newer load (e.g. the range changed) superseded this one.
        guard generation == loadGeneration else { return }
        series = newSeries
        isLoading = false
        if !failures.isEmpty {
            errorMessage = "Couldn't load: \(failures.joined(separator: ", "))"
        }
    }

    private func dailyValues(for metric: HealthMetric, days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let end = Date()
        let startOfToday = calendar.startOfDay(for: end)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday)!

        guard let identifier = metric.quantityIdentifier else {
            return try await sleepHours(from: start, to: end)
        }

        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(
                type: HKQuantityType(identifier),
                predicate: HKQuery.predicateForSamples(withStart: start, end: end)
            ),
            options: metric.aggregation.statisticsOptions,
            anchorDate: startOfToday,
            intervalComponents: DateComponents(day: 1)
        )

        let collection: HKStatisticsCollection
        do {
            collection = try await descriptor.result(for: store)
        } catch let error as HKError where error.code == .errorNoData {
            return []
        }

        var values: [DailyValue] = []
        collection.enumerateStatistics(from: start, to: end) { statistics, _ in
            if let quantity = metric.aggregation.quantity(from: statistics) {
                values.append(DailyValue(date: statistics.startDate, value: quantity.doubleValue(for: metric.unit)))
            }
        }
        return values
    }

    /// Total hours asleep per night, attributed to the day the sleep ended.
    private func sleepHours(from start: Date, to end: Date) async throws -> [DailyValue] {
        let calendar = Calendar.current
        // Include the evening before the first day so that night's sleep is counted.
        let queryStart = start.addingTimeInterval(-12 * 3600)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(
                type: HKCategoryType(.sleepAnalysis),
                predicate: HKQuery.predicateForSamples(withStart: queryStart, end: end)
            )],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await descriptor.result(for: store)
        let asleepValues = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))

        // iPhone and Apple Watch can both record the same night, so merge overlaps
        // instead of double-counting.
        var merged: [DateInterval] = []
        for sample in samples where asleepValues.contains(sample.value) {
            let interval = DateInterval(start: sample.startDate, end: sample.endDate)
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }

        var totals: [Date: Double] = [:]
        for interval in merged {
            let night = calendar.startOfDay(for: interval.end)
            guard night >= start else { continue }
            totals[night, default: 0] += interval.duration / 3600
        }
        return totals
            .map { DailyValue(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
}
