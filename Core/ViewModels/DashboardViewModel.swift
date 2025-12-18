import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var snapshot: HealthSnapshot?
    @Published var isLoading = false

    func loadDashboard() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.snapshot = HealthSnapshot(
                date: Date(),
                stepsAvg7d: 7600,
                distanceAvg7d: 5.2,
                activeCaloriesAvg7d: 520,
                restingHeartRate: 61,
                sleepAvgHours: 6.3,
                stressScore: 18
            )
            self.isLoading = false
        }
    }
}
