#!/bin/bash
set -e

echo "🚀 Initializing Hearty iOS MVP (Startup-Grade)..."

# =====================================================
# 1. Directory Structure
# =====================================================

mkdir -p App

mkdir -p Core/Models
mkdir -p Core/Services/AI
mkdir -p Core/Services/Health
mkdir -p Core/Services/Network
mkdir -p Core/ViewModels
mkdir -p Core/Config
mkdir -p Core/Utils

mkdir -p Features/Dashboard
mkdir -p Features/Report
mkdir -p Features/Paywall

mkdir -p Components/Common
mkdir -p Components/Cards
mkdir -p Components/Charts

mkdir -p Resources

# =====================================================
# 2. App Entry
# =====================================================

cat > App/HeartyApp.swift << 'EOF'
import SwiftUI

/// App 主入口
/// 注意：创业阶段不做复杂路由，先 Dashboard 驱动
@main
struct HeartyApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
    }
}
EOF

# =====================================================
# 3. Config（全局配置 / 环境 / 开关）
# =====================================================

cat > Core/Config/AppConfig.swift << 'EOF'
import Foundation

/// App 全局配置
/// 所有「以后一定会改」的东西，都集中在这里
enum AppConfig {

    /// 当前是否为 Debug / Mock 模式
    static let isMockMode: Bool = true

    /// 后端 API 基础地址（后期可按环境拆分）
    static let apiBaseURL: String = "https://api.yourdomain.com"

    /// AI Provider 开关（非常重要）
    static let aiProvider: AIProviderType = .openAI
}
EOF

cat > Core/Config/AIProviderType.swift << 'EOF'
import Foundation

/// 支持的 AI 提供方
/// 设计原则：
/// - iOS 端只认「协议」
/// - 不关心具体厂商
enum AIProviderType: String {
    case openAI
    case grok
    case qwen       // 通义千问
    case doubao     // 豆包
    case gemini
}
EOF

# =====================================================
# 4. Models（纯数据，不允许业务逻辑）
# =====================================================

cat > Core/Models/HealthSnapshot.swift << 'EOF'
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
EOF

cat > Core/Models/AIHealthReport.swift << 'EOF'
import Foundation

/// AI 生成的健康报告
/// 后期支持多语言 / 多版本
struct AIHealthReport: Codable {
    let summary: String
    let risks: [String]
    let suggestions: [String]
    let disclaimer: String
}
EOF

# =====================================================
# 5. Utils
# =====================================================

cat > Core/Utils/Date+Extension.swift << 'EOF'
import Foundation

extension Date {
    static var todayString: String {
        Date.now.formatted(date: .long, time: .omitted)
    }
}
EOF

# =====================================================
# 6. HealthKit Service（只负责“读”）
# =====================================================

cat > Core/Services/Health/HealthKitService.swift << 'EOF'
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
EOF

# =====================================================
# 7. Network Layer（后端统一入口）
# =====================================================

cat > Core/Services/Network/NetworkService.swift << 'EOF'
import Foundation

/// 网络层统一入口
/// 后期：
/// - Token
/// - Retry
/// - 日志
final class NetworkService {

    static let shared = NetworkService()
    private init() {}

    func post<T: Encodable, R: Decodable>(
        path: String,
        body: T,
        response: R.Type
    ) async throws -> R {

        // MVP 阶段直接 mock
        throw URLError(.badServerResponse)
    }
}
EOF

# =====================================================
# 8. AI Layer（最关键的“可扩展点”）
# =====================================================

cat > Core/Services/AI/AIService.swift << 'EOF'
import Foundation

/// AI Service Facade
/// iOS 端永远只调用这里
final class AIService {

    static let shared = AIService()
    private init() {}

    func generateHealthReport(
        snapshot: HealthSnapshot
    ) async throws -> AIHealthReport {

        if AppConfig.isMockMode {
            return mockReport()
        }

        switch AppConfig.aiProvider {
        case .openAI:
            return try await OpenAIProvider().generate(snapshot)
        case .grok:
            return try await GrokProvider().generate(snapshot)
        case .qwen:
            return try await QwenProvider().generate(snapshot)
        case .doubao:
            return try await DoubaoProvider().generate(snapshot)
        case .gemini:
            return try await GeminiProvider().generate(snapshot)
        }
    }

    private func mockReport() -> AIHealthReport {
        AIHealthReport(
            summary: "过去一周你的整体健康状态保持稳定。",
            risks: ["睡眠时间略低于推荐值"],
            suggestions: ["尝试提前 30 分钟入睡", "保持每日轻度运动"],
            disclaimer: "本报告仅供健康管理参考，不构成医疗建议。"
        )
    }
}
EOF

# =====================================================
# 9. AI Provider Protocol + Stubs
# =====================================================

cat > Core/Services/AI/AIProviderProtocol.swift << 'EOF'
import Foundation

/// 所有 AI Provider 必须遵守的协议
protocol AIProviderProtocol {
    func generate(_ snapshot: HealthSnapshot) async throws -> AIHealthReport
}
EOF

for provider in OpenAI Grok Qwen Doubao Gemini
do
cat > Core/Services/AI/${provider}Provider.swift << EOF
import Foundation

/// ${provider} AI Provider
/// 注意：
/// - iOS 端未来【不会】直接调 AI
/// - 这里最终只会调用你自己的后端
struct ${provider}Provider: AIProviderProtocol {

    func generate(_ snapshot: HealthSnapshot) async throws -> AIHealthReport {
        // TODO:
        // 1. 调用后端 /ai/health-report
        // 2. 后端再对接 ${provider} API
        throw URLError(.unsupportedURL)
    }
}
EOF
done

# =====================================================
# 10. ViewModel
# =====================================================

cat > Core/ViewModels/DashboardViewModel.swift << 'EOF'
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
EOF

# =====================================================
# 11. Dashboard UI
# =====================================================

cat > Features/Dashboard/DashboardView.swift << 'EOF'
import SwiftUI

/// App 核心入口页面
struct DashboardView: View {

    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if let snapshot = vm.snapshot {
                    MetricGrid(snapshot: snapshot)
                    GenerateReportButton()
                } else if vm.isLoading {
                    ProgressView("加载健康数据中...")
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .onAppear {
            vm.loadDashboard()
        }
    }
}
EOF

# =====================================================
# 12. Components
# =====================================================

cat > Components/Cards/MetricCardView.swift << 'EOF'
import SwiftUI

struct MetricCardView: View {

    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text(value)
                    .font(.title.bold())
                Text(unit)
                    .font(.footnote)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
EOF

cat > Components/Common/GenerateReportButton.swift << 'EOF'
import SwiftUI

struct GenerateReportButton: View {
    var body: some View {
        Button("生成综合健康报告") {
            // TODO: 跳转 Report 页面
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(14)
    }
}
EOF

echo "✅ Hearty iOS MVP initialized (Startup-Grade)."
