# HealthDash

A SwiftUI iPhone app that connects to **Apple Health** (HealthKit) and shows your data as a dashboard with charts.

Apple Health data can only be read on-device by a native iOS app — there is no web API — so this is an Xcode project you run on your iPhone.

## What it shows

| Activity | Heart | Sleep & Body |
|---|---|---|
| Steps | Heart rate (daily average) | Sleep (hours asleep per night) |
| Active energy | Resting heart rate | Weight |
| Walking + running distance | Heart rate variability | |
| Exercise minutes | | |
| Flights climbed | | |

- Dashboard of cards with the latest value and a mini chart for each metric
- 7 / 30 / 90-day ranges, pull to refresh
- Tap a card for a detail screen: large interactive chart (drag to inspect a day), average / low / high / total, and a list of daily values
- Uses metric or imperial units based on your region
- **Read-only**: the app never writes to Apple Health, and data never leaves your phone

## Running it on your iPhone

Requirements: a Mac with **Xcode 16 or newer**, an iPhone on **iOS 17+**, and a free or paid Apple ID.

1. Open `HealthDash.xcodeproj` in Xcode.
2. Select the **HealthDash** target → **Signing & Capabilities**.
   - Pick your **Team** (your Apple ID works — add it under Xcode › Settings › Accounts).
   - Change the **Bundle Identifier** from `com.example.HealthDash` to something unique, e.g. `com.yourname.HealthDash`.
   - The **HealthKit** capability is already configured via `HealthDash.entitlements`.
3. Plug in your iPhone (enable Developer Mode on the phone when prompted: Settings › Privacy & Security › Developer Mode).
4. Choose your iPhone as the run destination and press **Run** (⌘R).
5. On first launch iOS shows the Health access sheet — tap **Turn On All** (or pick the categories you want) and **Allow**.

With a free Apple ID, the app expires after 7 days; just run it from Xcode again.

### Simulator

It also runs in the iOS Simulator, but the simulator's Health app starts empty. Open the Health app in the simulator and add some sample data manually (Browse → a category → Add Data) to see charts.

## Changing access later

iOS never tells apps which read permissions were denied, so a metric you didn't allow simply shows "No data". To change access: **Settings › Health › Data Access & Devices › HealthDash**.

## Project layout

```
HealthDash/
  HealthDashApp.swift        App entry point
  Model/
    HealthMetric.swift       Metric definitions (HealthKit type, unit, aggregation, colors)
    HealthStore.swift        HealthKit authorization + daily statistics / sleep queries
  Views/
    DashboardView.swift      Card grid
    MetricChart.swift        Swift Charts bar/line chart
    MetricDetailView.swift   Per-metric detail screen
HealthDash.entitlements      HealthKit entitlement
```

To add another metric, add a case to `HealthMetric` and fill in its properties — it will automatically be requested, queried and shown.
