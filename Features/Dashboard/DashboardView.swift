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
