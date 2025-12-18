1. **完整系统架构图（创业级）**
2. **iOS 端 HealthKit 读取模板（Swift + SwiftUI，生产级）**

---

## 一、完整系统架构图（iOS 健康 + AI，创业级）

下面这是一张**逻辑架构图**，不是“画 UI”，而是你未来 1–3 年都不会推翻的底层结构。

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

**1️⃣ iOS 不保存“完整健康历史”**

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

下面是一个**生产级 HealthKit Service 模板**，适合 SwiftUI + MVVM。

---

### 1️⃣ HealthKitService.swift

```swift
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
@MainActor
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
