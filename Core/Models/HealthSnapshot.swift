import Foundation

/// 健康数据快照
/// ❗❗❗
/// - 这是 iOS ⇄ 后端 ⇄ AI 的「统一语言」
/// - 永远不要在这里出现 HealthKit 类型
struct HealthSnapshot: Codable {

    let date: Date

    // -------- Activity --------
    let stepsAvg7d: Double
    let distanceAvg7d: Double
    let activeCaloriesAvg7d: Double

    // -------- Body --------
    let restingHeartRate: Double
    let sleepAvgHours: Double

    // -------- Mental --------
    let stressScore: Int
}
