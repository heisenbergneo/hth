import HealthKit
import SwiftUI

/// One value per calendar day for a metric.
struct DailyValue: Identifiable, Hashable {
    let date: Date
    let value: Double
    var id: Date { date }
}

/// How daily values are combined from raw samples.
enum Aggregation {
    case sum
    case average
    case latest

    var statisticsOptions: HKStatisticsOptions {
        switch self {
        case .sum: .cumulativeSum
        case .average: .discreteAverage
        case .latest: .mostRecent
        }
    }

    func quantity(from statistics: HKStatistics) -> HKQuantity? {
        switch self {
        case .sum: statistics.sumQuantity()
        case .average: statistics.averageQuantity()
        case .latest: statistics.mostRecentQuantity()
        }
    }
}

enum ChartStyle {
    case bar
    case line
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week, month, quarter

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        }
    }

    var title: String {
        switch self {
        case .week: "7 Days"
        case .month: "30 Days"
        case .quarter: "90 Days"
        }
    }
}

/// The Apple Health data types the app reads and displays.
enum HealthMetric: String, CaseIterable, Identifiable {
    case steps
    case activeEnergy
    case distance
    case exerciseMinutes
    case flightsClimbed
    case sleep
    case heartRate
    case restingHeartRate
    case heartRateVariability
    case bodyMass

    var id: String { rawValue }

    private static var usesMetric: Bool {
        Locale.current.measurementSystem != .us
    }

    var title: String {
        switch self {
        case .steps: "Steps"
        case .activeEnergy: "Active Energy"
        case .distance: "Walking + Running"
        case .exerciseMinutes: "Exercise"
        case .flightsClimbed: "Flights Climbed"
        case .sleep: "Sleep"
        case .heartRate: "Heart Rate"
        case .restingHeartRate: "Resting Heart Rate"
        case .heartRateVariability: "Heart Rate Variability"
        case .bodyMass: "Weight"
        }
    }

    var symbol: String {
        switch self {
        case .steps: "figure.walk"
        case .activeEnergy: "flame.fill"
        case .distance: "map.fill"
        case .exerciseMinutes: "figure.run"
        case .flightsClimbed: "figure.stairs"
        case .sleep: "bed.double.fill"
        case .heartRate: "heart.fill"
        case .restingHeartRate: "heart.circle.fill"
        case .heartRateVariability: "waveform.path.ecg"
        case .bodyMass: "scalemass.fill"
        }
    }

    var color: Color {
        switch self {
        case .steps, .distance, .flightsClimbed: .orange
        case .activeEnergy: .red
        case .exerciseMinutes: .green
        case .sleep: .indigo
        case .heartRate, .restingHeartRate, .heartRateVariability: .pink
        case .bodyMass: .purple
        }
    }

    /// `nil` for sleep, which is a category type rather than a quantity.
    var quantityIdentifier: HKQuantityTypeIdentifier? {
        switch self {
        case .steps: .stepCount
        case .activeEnergy: .activeEnergyBurned
        case .distance: .distanceWalkingRunning
        case .exerciseMinutes: .appleExerciseTime
        case .flightsClimbed: .flightsClimbed
        case .sleep: nil
        case .heartRate: .heartRate
        case .restingHeartRate: .restingHeartRate
        case .heartRateVariability: .heartRateVariabilitySDNN
        case .bodyMass: .bodyMass
        }
    }

    var sampleType: HKSampleType {
        if let quantityIdentifier {
            return HKQuantityType(quantityIdentifier)
        }
        return HKCategoryType(.sleepAnalysis)
    }

    var unit: HKUnit {
        switch self {
        case .steps, .flightsClimbed: .count()
        case .activeEnergy: .kilocalorie()
        case .distance: Self.usesMetric ? .meterUnit(with: .kilo) : .mile()
        case .exerciseMinutes: .minute()
        case .sleep: .hour()
        case .heartRate, .restingHeartRate: .count().unitDivided(by: .minute())
        case .heartRateVariability: .secondUnit(with: .milli)
        case .bodyMass: Self.usesMetric ? .gramUnit(with: .kilo) : .pound()
        }
    }

    var unitLabel: String {
        switch self {
        case .steps: "steps"
        case .activeEnergy: "kcal"
        case .distance: Self.usesMetric ? "km" : "mi"
        case .exerciseMinutes: "min"
        case .flightsClimbed: "floors"
        case .sleep: ""
        case .heartRate, .restingHeartRate: "bpm"
        case .heartRateVariability: "ms"
        case .bodyMass: Self.usesMetric ? "kg" : "lb"
        }
    }

    var aggregation: Aggregation {
        switch self {
        case .steps, .activeEnergy, .distance, .exerciseMinutes, .flightsClimbed, .sleep: .sum
        case .heartRate, .restingHeartRate, .heartRateVariability: .average
        case .bodyMass: .latest
        }
    }

    var chartStyle: ChartStyle {
        aggregation == .sum ? .bar : .line
    }

    /// Caption for the headline value on the dashboard.
    var summaryCaption: String {
        switch aggregation {
        case .sum: "Daily average"
        case .average: "Average"
        case .latest: "Latest"
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .sleep:
            let totalMinutes = Int((value * 60).rounded())
            return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
        case .distance, .bodyMass:
            return value.formatted(.number.precision(.fractionLength(1)))
        default:
            return value.formatted(.number.precision(.fractionLength(0)))
        }
    }

    func formatWithUnit(_ value: Double) -> String {
        unitLabel.isEmpty ? format(value) : "\(format(value)) \(unitLabel)"
    }
}

extension Date {
    var relativeDayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}
