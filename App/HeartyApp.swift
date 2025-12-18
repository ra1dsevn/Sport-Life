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
