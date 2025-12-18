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
