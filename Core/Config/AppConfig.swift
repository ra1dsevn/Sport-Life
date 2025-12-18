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
