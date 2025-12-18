import Foundation

/// 所有 AI Provider 必须遵守的协议
protocol AIProviderProtocol {
    func generate(_ snapshot: HealthSnapshot) async throws -> AIHealthReport
}
