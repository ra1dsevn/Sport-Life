import Foundation

/// Doubao AI Provider
/// 注意：
/// - iOS 端未来【不会】直接调 AI
/// - 这里最终只会调用你自己的后端
struct DoubaoProvider: AIProviderProtocol {

    func generate(_ snapshot: HealthSnapshot) async throws -> AIHealthReport {
        // TODO:
        // 1. 调用后端 /ai/health-report
        // 2. 后端再对接 Doubao API
        throw URLError(.unsupportedURL)
    }
}
