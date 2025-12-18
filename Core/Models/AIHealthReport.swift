import Foundation

/// AI 生成的健康报告
/// 后期支持多语言 / 多版本
struct AIHealthReport: Codable {
    let summary: String
    let risks: [String]
    let suggestions: [String]
    let disclaimer: String
}
