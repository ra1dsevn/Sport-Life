# Sport-Life / Hearty — iOS MVP (SwiftUI)

版本：中文（下）与 English（下方）

---

## 简介（中文）

Sport-Life（代码名：Hearty）是一个用 SwiftUI 构建的 iOS MVP 原型，示范如何从 HealthKit 收集聚合健康数据、在仪表盘中展示，并提供清晰的模块化架构以便扩展（网络、AI 服务接入、后端对接）。本 README 按模块分节，包含架构图、关键代码示例、部署与 CI 指南，以及英文镜像版。

目标读者：iOS 开发者、希望快速搭建 HealthKit + SwiftUI 原型的工程师。

---

## 目录（中文）

- 项目摘要
- 技术栈
- 项目结构（按模块）
- 架构图（高层 & 数据流）
- 关键代码示例（Models / Services / ViewModels / Views）
- 部署与发布（本地构建、真机测试、CI / Release）
- 开发建议与扩展点
- English section (below)

---

## 项目摘要

- 名称：Sport-Life（Hearty）
- 类型：iOS 原型 / MVP
- UI：SwiftUI
- 模式：MVVM（View → ViewModel → Services → 数据/网络）

用途：演示如何将 HealthKit 数据以聚合快照形式读取并在本地展示，保留拓展点（网络上报、AI 报告、后端存储）。

---

## 技术栈

- iOS: Swift 5.8+，SwiftUI
- 架构: MVVM
- 健康数据: HealthKit
- 网络: URLSession（`Core/Services/NetworkService.swift`）或可替换为 Alamofire
- 异步: async/await 或回调（代码中两者示例）
- 后端（建议）: Node.js + NestJS / Express（示例架构不包含实现代码）
- CI/CD: GitHub Actions（示例 workflow 可选）

---

## 项目结构（按模块）

简要目录说明：

- `App/` — 应用入口（`HeartyApp.swift`）
- `Features/Dashboard/` — 仪表盘页面与子视图（`DashboardView.swift`, `ActivityRingView.swift`, `StressGaugeView.swift`）
- `Components/` — 可复用 UI 组件（例如 `MetricCardView.swift`）
- `Core/Models/` — 数据模型（`HealthSnapshot.swift`, `UserProfile.swift`）
- `Core/Services/` — 服务层（`HealthKitService.swift`, `NetworkService.swift`, `AIService.swift`）
- `Core/ViewModels/` — 视图模型（`DashboardViewModel.swift`）
- `Core/Utils/` — 工具与扩展（例如 `Date+Extension.swift`）

保持模块化可以方便替换实现（例如把 `HealthKitService` 的数据源替换为后端 API）。

---

## 架构图（高层 & 数据流）

高层视图：

```
┌──────────────────────────────────────────────────┐
│                     iOS App (SwiftUI)            │
│  ┌────────────┐   ┌──────────────┐   ┌──────────┐ │
│  │  Views     │──▶│ ViewModels   │──▶│ Services │ │
│  └────────────┘   └──────────────┘   └──────────┘ │
└──────────────┬───────────────────────────────────┘
               │
               ▼
   ┌────────────────────────┐     ┌──────────────────┐
   │ HealthKit (on-device)  │     │ Remote Backend    │
   │ - stepCount            │     │ - Snapshot API    │
   │ - heartRate            │     │ - AI orchestration │
   └────────────────────────┘     └──────────────────┘
```

数据流（示例）：
- App 启动 → ViewModel 请求数据 → HealthKitService 查询并返回聚合数据（或调用 NetworkService 从后端拉取）→ ViewModel 格式化后更新 View。

---

## 关键代码示例（按模块）

下面的片段来自项目中可直接使用或借鉴的实现。

1) 模型：`Core/Models/HealthSnapshot.swift`

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

2) HealthKit 服务（节选）：`Core/Services/HealthKitService.swift`

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
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    func fetchStepsSum(start: Date, end: Date, completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async { completion(steps) }
        }
        healthStore.execute(query)
    }
}
```

3) Network 服务（简单异步调用示例）：`Core/Services/NetworkService.swift`

```swift
import Foundation

final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    func post<T: Encodable>(url: URL, body: T) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
```

4) ViewModel 示例：`Core/ViewModels/DashboardViewModel.swift`

```swift
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var snapshot: HealthSnapshot?
    @Published var isLoading = false

    func loadDashboard() {
        isLoading = true
        // 异步组合示例：调用 HealthKitService 或后端 API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.snapshot = HealthSnapshot(date: Date(), stepsAvg7d: 7654, distanceAvg7d: 5.3, activeCaloriesAvg7d: 513, restingHeartRate: 62, sleepAvgHours: 6.4, stressScore: 19)
            self.isLoading = false
        }
    }
}
```

5) SwiftUI 视图示例：`Features/Dashboard/ActivityRingView.swift`

```swift
import SwiftUI

struct ActivityRingView: View {
    let calories: Double
    let target: Double
    var progress: Double { min(calories / target, 1.0) }
    var body: some View {
        VStack {
            ZStack {
                Circle().stroke(lineWidth: 12).opacity(0.2)
                Circle().trim(from: 0, to: progress).stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round)).rotationEffect(.degrees(-90))
            }.frame(width: 120, height: 120)
            Text("\(Int(calories)) / \(Int(target)) kcal").font(.footnote)
        }
    }
}
```

---

## 部署与发布（本地构建、真机测试、CI）

注：这是 iOS 客户端的发布说明。若需要后端部署示例（NestJS / Docker），可在仓库中新增 `backend/` 目录并扩展文档。

1) 本地构建与真机测试

- 打开 Xcode，选择目标设备（真机），在 `Signing & Capabilities` 中配置 Team，并确保启用了 `HealthKit` 权限。
- 运行应用：Xcode → Run。首次 HealthKit 授权会在设备上弹出。

2) CI（示例：GitHub Actions）

示例步骤：

- 在 `.github/workflows/ci.yml` 中配置 macOS runner（`macos-latest`），运行 `xcodebuild -scheme` 执行构建/测试。示例 workflow（高层）：

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Ruby (for CocoaPods if needed)
        uses: actions/setup-ruby@v1
      - name: Install dependencies
        run: | 
          # if you use SPM nothing needed; if CocoaPods: pod install
          echo "Install deps"
      - name: Build
        run: xcodebuild -scheme "YourScheme" -sdk iphoneos -configuration Release build
```

注意：CI 在 macOS runner 上运行需要调整 scheme 与签名配置（可使用 `xcodebuild` 参数或使用 `xcpretty` 简化输出）。

3) 发布到 App Store

- 使用 Xcode Organizer 或 `xcrun altool` / `xcodebuild -exportArchive` 导出并上传到 App Store Connect。
- 在 App Store Connect 中管理版本、截图与元数据。

---

## 开发建议与扩展点

- 将服务抽象为协议（protocol），使得 ViewModel 更易测试与替换（注入依赖）。
- 对网络层实现超时、重试与错误映射；对 HealthKit 查询做好权限与异常处理。
- 如果需要 AI 报告功能，建议在后端集中调用第三方模型并通过安全 API 提供简化接口。

---

## English — Summary & Instructions

Below is a concise English copy of the README with the same structure: overview, tech stack, modules, architecture, code samples, and deployment notes.

### Overview

Sport-Life (Hearty) is an iOS MVP prototype built with SwiftUI demonstrating collection and presentation of aggregated HealthKit data. It follows MVVM and keeps modular boundaries for Services, Models, ViewModels and Views.

### Tech Stack

- Swift 5+, SwiftUI
- HealthKit for local health data
- MVVM architecture
- Networking via URLSession (async/await)
- CI: GitHub Actions (macOS runners)

### Project Structure

- `App/` — app entry
- `Features/Dashboard/` — dashboard UI
- `Components/` — reusable UI pieces
- `Core/Models/` — data models
- `Core/Services/` — HealthKit, Network, AI service abstractions
- `Core/ViewModels/` — view models

### Quick Code Samples

Models, HealthKitService, NetworkService, ViewModel and a SwiftUI view — see the Chinese section above for full code blocks.

### Deployment Notes

- Local device testing requires enabling HealthKit in `Signing & Capabilities` and running on a real device.
- CI should use `macos-latest` runner to build and test via `xcodebuild`.

---

## Contributing

- Open an Issue to discuss larger changes. For PRs, keep changes small and focused. Add unit tests for logic-heavy changes.

---

If you want, I can:

- extract the code examples into a `docs/snippets/` folder and add cross-links; or
- add a `backend/` example (simple NestJS API with snapshot endpoints and example POST requests); or
- create a GitHub Actions workflow file under `.github/workflows/` tuned for this project.

告诉我你想继续的方向，我会按需实现并推送更改。
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
