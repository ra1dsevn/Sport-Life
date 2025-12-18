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
