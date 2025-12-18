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
