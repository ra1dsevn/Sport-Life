import HealthKit

/// HealthKit 访问层
/// 原则：
/// - 不做聚合逻辑
/// - 不关心 UI
/// - 不上传数据
final class HealthKitService {

    static let shared = HealthKitService()
    private let store = HKHealthStore()

    private init() {}

    /// 请求 HealthKit 权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        store.requestAuthorization(toShare: [], read: readTypes) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
