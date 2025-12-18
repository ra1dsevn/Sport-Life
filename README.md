**项目概览**

Hearty（仓库名：`Sport-Life`）是一个用 SwiftUI 构建的 iOS MVP 原型，展示了如何从 HealthKit 收集聚合健康数据并在仪表盘中展示。代码结构清晰、便于扩展与测试，适合作为学习与二次开发的起点。

**快速开始（最小）**

- 在 macOS 上安装并打开 Xcode（建议 Xcode 15+）。
- 在终端进入项目目录并打开工程：
  ```bash
  cd /Users/yqlee/Sport-Life
  open .
  ```
- 在真机上运行以测试 HealthKit 功能（模拟器不提供真实 HealthKit 数据）。

**主要文件/目录说明**

- `App/HeartyApp.swift`：应用入口。
- `Features/Dashboard/`：仪表盘 UI（`DashboardView.swift`、`ActivityRingView.swift`、`StressGaugeView.swift`）。
- `Components/`：UI 组件（`MetricCardView.swift`、`SectionHeaderView.swift` 等）。
- `Core/Models/`：数据模型（`HealthSnapshot.swift`、`UserProfile.swift` 等）。
- `Core/Services/`：服务层（`HealthKitService.swift`、`NetworkService.swift`、`AIService.swift`）。
- `Core/ViewModels/`：视图模型（`DashboardViewModel.swift`）。
- `Core/Utils/Date+Extension.swift`：日期格式化扩展。

**HealthKit 与 权限**

- `Core/Services/HealthKitService.swift` 提供了授权入口。要读取具体样本或统计数据，请在该服务中添加相应的 `HKQuery` 实现。
- 在 Xcode 的 `Signing & Capabilities` 中启用 `HealthKit` 并在设备上同意授权。

**扩展点与实现提示**

- `Core/Services/AIService.swift` 为可选扩展点，当前为占位实现；如果不需要 AI 功能，可忽略此模块。
- 推荐通过 `Core/Services/NetworkService.swift` 统一封装 HTTP 请求、鉴权与超时/重试策略。

**开发建议**

- 把 `DashboardViewModel` 中的数据来源抽象为协议以便单元测试与替换存根实现。
- 为关键服务添加错误处理和超时保护（network）。
- 添加 `Localizable.strings` 做多语言支持（目前界面为中文）。

**命令 & 验证**

- 查看远程仓库： `git remote -v`
- 验证 SSH： `ssh -T git@github.com`

*** 示例架构图 & 代码片段 ***

---

简单架构图

```
┌──────────────────────────┐
│        iOS Client        │
│      (Swift + SwiftUI)   │
│                          │
│  UI  <-> ViewModel <-> Services
│                          │
│  Services:
│   - HealthKitService
│   - NetworkService
│   - AIService (optional)
└──────────────────────────┘
```

核心模型示例（`Core/Models/HealthSnapshot.swift`）

```swift
import Foundation

struct HealthSnapshot: Codable {
    let date: Date
    let stepsAvg7d: Double
    let distanceAvg7d: Double
    let activeCaloriesAvg7d: Double
    let restingHeartRate: Double
    let sleepAvgHours: Double
    let stressScore: Int
}
```

简要的 `HealthKitService` 示例（节选）

```swift
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false); return }
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
```

`DashboardViewModel` 简要示例

```swift
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var snapshot: HealthSnapshot?
    @Published var isLoading = false

    func loadDashboard() {
        isLoading = true
        // 示例：调用 HealthKitService 或后端服务获取聚合数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.snapshot = HealthSnapshot(date: Date(), stepsAvg7d: 7654, distanceAvg7d: 5.3, activeCaloriesAvg7d: 513, restingHeartRate: 62, sleepAvgHours: 6.4, stressScore: 19)
            self.isLoading = false
        }
    }
}
```

UI 组件示例：`ActivityRingView`（节选）

```swift
struct ActivityRingView: View {
    let calories: Double
    let target: Double
    var progress: Double { min(calories / target, 1.0) }
    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 12).opacity(0.2)
            Circle().trim(from: 0, to: progress).stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round)).rotationEffect(.degrees(-90))
        }.frame(width: 120, height: 120)
    }
}
```

---

**贡献**

- 欢迎提交 issue 和 PR。请尽量保持改动小而明确。若要添加新特性，请先开 issue 描述设计和动机。


**快速开始**

- **前提：** 在 macOS 上安装 Xcode（建议 Xcode 15 及以上）。
- **打开工程：** 在 Xcode 中通过 `File → Open` 打开项目所在文件夹（根目录包含 `App/`、`Features/` 等目录）。
- **运行：** 选中模拟器或连接的设备后，点击运行（Run）。

如果要运行与 HealthKit 相关的功能，请在真机上运行并在 Xcode 的 Capabilities 中开启 HealthKit 权限；模拟器无法提供真实的 HealthKit 数据。

示例命令（在项目根目录用于查看文件）：

```bash
ls -la
open .
```

**主要特性**

- **仪表盘视图：** 基于 `Features/Dashboard/DashboardView.swift` 展示汇总数据与可视化组件。
- **HealthKit 支持（MVP）：** `Core/Services/HealthKitService.swift` 提供授权流程和数据读取入口。
- **AI 报告（占位实现）：** `Core/Services/AIService.swift` 提供生成健康文字报告的异步接口（当前为 mock）。
- **视图模型：** `Core/ViewModels/DashboardViewModel.swift` 管理仪表盘数据加载与状态。

**项目结构（摘要）**

- `App/HeartyApp.swift`：应用入口。  
- `Features/Dashboard/`：仪表盘相关视图与子组件（`ActivityRingView.swift`、`StressGaugeView.swift`、`DashboardView.swift`）。  
- `Components/`：可复用 UI 组件（`MetricCardView.swift`、`SectionHeaderView.swift`、`PlaceholderView.swift`）。  
- `Core/Models/`：数据模型（`HealthSnapshot.swift`、`UserProfile.swift`）。  
- `Core/ViewModels/`：视图模型（`DashboardViewModel.swift`）。  
- `Core/Utils/Date+Extension.swift`：实用扩展。

**关键实现说明与扩展建议**

- HealthKit：目前 `HealthKitService` 提供授权接口。要读取具体数据（步数、心率、消耗能量、睡眠等），在该服务中实现对应的 `HKStatisticsQuery` / `HKSampleQuery` 并做好错误处理与单元转换。
- AI 报告：`AIService.generateHealthReport(from:)` 目前返回固定文本。可替换为调用自建后端或第三方模型（通过 `NetworkService` 统一封装 HTTP 请求、鉴权与速率限制）。
- 本地化：当前界面包含中文字符串，若要支持多语言，请使用 `Localizable.strings` 及 `String(localized:)`。
- 单元测试：将 `DashboardViewModel` 中的数据加载逻辑抽象成可注入的存根服务（protocol），便于编写单元测试和 UI 预览。

**开发与调试提示**

- 在真机上测试 HealthKit：打开 Xcode → 选中目标设备 → 在项目 `Signing & Capabilities` 中添加 `HealthKit` 权限并在运行时同意授权。  
- 若要模拟不同数据场景，可修改 `Core/ViewModels/DashboardViewModel.swift` 中的模拟值或把真实数据读取逻辑替换进来。  

**下一步建议**

- 将 `AIService` 替换为真实后端调用并在 UI 中添加加载/提示状态；  
- 添加 Settings 页面以配置目标值（如每日卡路里目标）；  
- 增加更丰富的健康图表和历史趋势展示。

**致谢**

该仓库为 Hearty MVP 快速原型结构，旨在帮助你快速上手 HealthKit + SwiftUI 的工程组织与扩展点设计。



    @StateObject private var vm = DashboardViewModel()

    var body: some View {
            Text("今日步数")
            Text("\(Int(vm.stepsToday))")
                .font(.largeTitle)
    }
}
```

## 三、单人创业的「现实建议」（非常重要）

* ❌ 复杂设备接入
* ❌ 医疗诊断
* ❌ 太多指标（3–5 个核心即可）
### ✅ 你第一个 MVP 必须包含

1. Apple Health 数据读取
4. 清晰免责声明
5. Pro 开关（哪怕暂时免费）


| --- | ------------------- |
| iOS | Swift + SwiftUI     |
| 架构  | MVVM                |
| 健康  | HealthKit           |
| 图表  | Swift Charts        |
| 后端  | NestJS + PostgreSQL |
| AI  | OpenAI / Claude     |
| 订阅  | StoreKit 2          |
| 部署  | Fly.io / AWS        |

---
