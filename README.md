1. **完整系统架构图（创业级）**
2. **iOS 端 HealthKit 读取模板（Swift + SwiftUI，生产级）**

---

## 一、完整系统架构图（iOS 健康 + AI，创业级）


```
┌──────────────────────────┐
│        iOS Client        │
│  (Swift + SwiftUI)       │
│                          │
│  ┌────────────────────┐ │
│  │  UI Layer          │ │
│  │  - Dashboard       │ │
│  │  - Charts          │ │
│  │  - Reports         │ │
│  │  - Tests (PHQ-9)   │ │
│  └────────▲───────────┘ │
│           │ MVVM         │
│  ┌────────┴───────────┐ │
│  │ ViewModels         │ │
│  └────────▲───────────┘ │
│           │              │
│  ┌────────┴───────────┐ │
│  │ Services           │ │
│  │ - HealthKitService │◄───── Apple Health
│  │ - NetworkService  │ │
│  │ - AuthService     │ │
│  │ - AIService       │ │
│  └────────▲───────────┘ │
│           │ HTTPS        │
└───────────┼──────────────┘
            │
            ▼
┌──────────────────────────┐
│      API Gateway         │
│  (Rate limit / Auth)     │
└───────────▲──────────────┘
            │
            ▼
┌──────────────────────────┐
│      Backend (NestJS)    │
│                          │
│  - User / Auth           │
│  - Subscription          │
│  - Health Snapshot API   │
│  - AI Orchestration      │
│                          │
└───────┬─────────┬────────┘
        │         │
        ▼         ▼
┌────────────┐  ┌────────────────┐
│ PostgreSQL │  │   AI Provider   │
│            │  │ (GPT / Claude)  │
│ - Users    │  │                │
│ - Snapshots│  └────────────────┘
│ - Reports  │
└────────────┘
```

---

### 🔑 这个架构的关键设计思想


* iOS 只负责读取 HealthKit
* 上传的是 **“聚合后的健康快照”**

**2️⃣ 后端不碰 HealthKit**

* 后端永远不知道你的原始健康数据来源
* 只处理统计值、趋势、AI 输入

**3️⃣ AI 在后端**

* 避免 Key 泄露
* 便于统一 Prompt、成本控制、A/B 测试

**4️⃣ 一开始就支持订阅**

* 即使暂时不收费，结构要在

---

## 二、HealthKit 读取模板（你可以直接用）


---

### 1️⃣ HealthKitService.swift

import HealthKit

final class HealthKitService {

    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    // MARK: - Step Count (Today)

    func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async {
                completion(steps)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Resting Heart Rate (7 Days Avg)

    func fetchRestingHeartRateAvg7Days(completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, _ in
            let bpm = result?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0
            DispatchQueue.main.async {
                completion(bpm)
            }
        }

        healthStore.execute(query)
    }
}
```

---

### 2️⃣ ViewModel 示例

```swift
final class DashboardViewModel: ObservableObject {

    @Published var stepsToday: Double = 0
    @Published var restingHR: Double = 0

    func load() {
        HealthKitService.shared.fetchTodaySteps {
            self.stepsToday = $0
        }

        HealthKitService.shared.fetchRestingHeartRateAvg7Days {
            self.restingHR = $0
        }
    }
}
```

---

### 3️⃣ SwiftUI 使用示例
**项目概览**

Hearty 是一个面向 iOS 的轻量级 MVP（最小可行产品）示例，使用 SwiftUI 构建，展示如何在仪表盘中呈现来自 HealthKit 的基本健康数据、用简单视图组件组织 UI，并在未来接入 AI 服务生成健康报告。

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
- `Core/Services/`：服务层（`HealthKitService.swift`、`NetworkService.swift`、`AIService.swift`）。  
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


```swift
struct DashboardView: View {

    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("今日步数")
            Text("\(Int(vm.stepsToday))")
                .font(.largeTitle)

            Text("7日平均静息心率")
            Text(String(format: "%.1f bpm", vm.restingHR))
        }
        .onAppear {
            vm.load()
        }
    }
}
```

---

## 三、单人创业的「现实建议」（非常重要）

### ✅ 不要一开始做的事情

* ❌ 复杂设备接入
* ❌ 医疗诊断
* ❌ 太多指标（3–5 个核心即可）

---

### ✅ 你第一个 MVP 必须包含

1. Apple Health 数据读取
2. 周期性健康总结
3. AI 生成报告
4. 清晰免责声明
5. Pro 开关（哪怕暂时免费）

---

### ✅ 技术选型最终结论（为你总结）

| 层   | 技术                  |
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
