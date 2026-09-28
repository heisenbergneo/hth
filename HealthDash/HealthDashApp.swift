import SwiftUI

@main
struct HealthDashApp: App {
    @State private var health = HealthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(health)
        }
    }
}

struct ContentView: View {
    var body: some View {
        if HealthStore.isAvailable {
            NavigationStack {
                DashboardView()
            }
        } else {
            ContentUnavailableView(
                "Apple Health Unavailable",
                systemImage: "heart.slash",
                description: Text("Health data isn't available on this device. Run HealthDash on an iPhone.")
            )
        }
    }
}
