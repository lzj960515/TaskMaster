# SwiftUI 数据流与状态管理

## 一、基础概念

### 1. 属性包装器介绍

#### @Published
- 作用：将属性标记为可观察对象
- 触发机制：当属性值变化时通知所有观察者
- 使用场景：需要在视图中响应的数据、需要在多个视图间共享的状态

```swift
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []  // 当 tasks 改变时，通知所有观察者
    @Published var searchText: String = ""  // UI 绑定的状态
}
```

#### @StateObject vs @ObservedObject
- @StateObject：负责创建和管理对象的生命周期
- @ObservedObject：仅负责观察已存在的对象

```swift
// @StateObject：视图的整个生命周期内只创建一次
struct ParentView: View {
    @StateObject private var viewModel = TaskViewModel()  // ✅ 负责创建和维护
    
    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

// @ObservedObject：从父视图接收实例
struct ChildView: View {
    @ObservedObject var viewModel: TaskViewModel  // ✅ 只负责使用
    
    var body: some View {
        Text("Tasks: \(viewModel.tasks.count)")
    }
}
```

#### @EnvironmentObject
- 作用：提供全局依赖注入机制
- 特点：自动向下传递给所有子视图
- 使用场景：需要在多个视图层级共享数据

```swift
// 注入环境对象
ContentView()
    .environmentObject(viewModel)

// 在任何子视图中使用
struct ChildView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    // ...
}
```

### 观察机制对比
在使用 `@EnvironmentObject` 和 `@ObservedObject` 时，两者都能正确观察和响应 ViewModel 的更新。`@EnvironmentObject` 实际上是建立在 `@ObservedObject` 的基础上的，主要区别在于获取 ViewModel 的方式而不是观察能力。

```swift
// 两种方式都能正确观察更新
struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskViewModel  // ✅ 从环境中获取并观察
    // 或
    @ObservedObject var viewModel: TaskViewModel    // ✅ 通过参数传递并观察
    
    var body: some View {
        List {
            ForEach(viewModel.tasks) { task in  // 都能响应 tasks 的变化
                TaskRowView()
            }
        }
    }
}
```

**关键区别**：
1. 获取方式：
   - `@EnvironmentObject`：从视图环境中自动获取
   - `@ObservedObject`：需要通过初始化或参数传递

2. 使用场景：
   - `@EnvironmentObject`：适合全局共享、多视图访问
   - `@ObservedObject`：适合明确的依赖传递

3. 数据流特点：
   - `@EnvironmentObject`：自动向下传递给所有子视图
   - `@ObservedObject`：需要手动传递给需要的子视图

```swift
// 使用 @EnvironmentObject 的简洁方式
struct ParentView: View {
    var body: some View {
        VStack {
            ChildView()  // 无需传递 viewModel
            AnotherChildView()  // 无需传递 viewModel
        }
    }
}

// 使用 @ObservedObject 的显式传递
struct ParentView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        VStack {
            ChildView(viewModel: viewModel)  // 需要手动传递
            AnotherChildView(viewModel: viewModel)  // 需要手动传递
        }
    }
}
```

**注意事项**：
- 使用 `@EnvironmentObject` 时，必须确保视图链上有通过 `.environmentObject()` 注入对应的对象
- 两种方式都能观察到所有 `@Published` 标记的属性变化
- 选择哪种方式主要取决于架构需求，而不是观察能力

### 2. 视图层次结构

#### 子视图定义
在 SwiftUI 中，一个视图中使用的所有视图都被视为其子视图：
- 自定义视图（如 `FilterView`、`CategoryListView`）
- 系统视图（如 `Text`、`Button`）
- 容器视图（如 `VStack`、`HStack`、`List`）

```swift
struct ParentView: View {
    var body: some View {
        VStack {  // 容器子视图
            CustomView()  // 自定义子视图
            Text("Hello")  // 系统子视图
            Button("Click") { }  // 系统子视图
        }
    }
}
```

#### 视图层次特点
1. 递归性：子视图中的视图也是父视图的后代
2. 环境传递：环境对象自动向下传递给所有后代视图
3. 修饰符视图：`.sheet`、`.alert` 等创建的视图也是子视图

## 二、数据传递方式

### 1. 环境对象（Environment Object）

#### 定义与用法
```swift
// 在顶层视图注入
WindowGroup {
    ContentView()
        .environmentObject(viewModel)
}

// 在子视图中使用
struct ChildView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    // ...
}
```

#### 适用场景
- 深层视图层次结构
- 多个不相关视图需要访问同一个对象
- 全局状态管理

#### 优缺点
👍 优点：
- 避免属性传递链
- 方便全局状态管理
- 简化代码结构

👎 缺点：
- 依赖关系不明显
- 可能造成滥用
- 测试相对复杂

### 2. 直接传递（ObservedObject）

#### 定义与用法
```swift
struct ParentView: View {
    @StateObject private var viewModel = TaskViewModel()
    
    var body: some View {
        ChildView(viewModel: viewModel)  // 直接传递
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: TaskViewModel  // 接收传递
    // ...
}
```

#### 适用场景
- 简单的父子视图关系
- 需要明确依赖关系的场景
- 小型视图层次结构

#### 优缺点
👍 优点：
- 依赖关系清晰
- 易于理解和维护
- 便于测试

👎 缺点：
- 可能导致属性传递链
- 代码量较大
- 不适合复杂层次结构

### 2. 数据传递对比

#### 环境对象传递机制
```swift
TaskListView
    .environmentObject(viewModel)  // ⬇️ 向下传递到所有子视图
    |
    ├── FilterView  // ✅ 自动接收 viewModel
    |   |
    |   └── CategoryListView  // ✅ 自动接收 viewModel
    |
    └── TaskRowView  // ✅ 自动接收 viewModel
```

👍 **适用场景**：
- 深层视图嵌套
- 多个平行视图需要相同数据
- 全局状态共享
- 模态视图（sheet、alert等）需要访问父视图数据

```swift
struct ComplexView: View {
    var body: some View {
        TabView {
            HomeView()  // 需要 viewModel
            SearchView()  // 需要 viewModel
            ProfileView()  // 需要 viewModel
                .sheet(isPresented: $showSettings) {
                    SettingsView()  // 需要 viewModel
                }
        }
        .environmentObject(viewModel)  // 一次注入，到处使用
    }
}
```

#### 直接传递机制
```swift
TaskListView(viewModel: viewModel)
    |
    ├── FilterView(viewModel: viewModel)  // 需要手动传递
    |   |
    |   └── CategoryListView(viewModel: viewModel)  // 需要手动传递
    |
    └── TaskRowView(viewModel: viewModel)  // 需要手动传递
```

👍 **适用场景**：
- 简单的父子关系
- 需要明确依赖关系
- 视图复用性要求高
- 需要严格控制数据流向

```swift
struct TaskDetailView: View {
    @ObservedObject var viewModel: TaskViewModel
    let task: Task
    
    var body: some View {
        VStack {
            TaskInfoView(task: task, viewModel: viewModel)
            TaskActionsView(task: task, viewModel: viewModel)
        }
    }
}
```

#### 选择建议

1. **使用环境对象当**：
- 视图层次复杂
- 需要在多个分支共享数据
- 处理全局状态
- 处理模态视图

```swift
struct AppView: View {
    var body: some View {
        TabView {
            TaskListView()
            SettingsView()
            ProfileView()
        }
        .environmentObject(appViewModel)  // ✅ 适合全局注入
    }
}
```

2. **使用直接传递当**：
- 视图关系简单明确
- 需要高度可复用
- 需要严格的数据流控制
- 需要明确的依赖关系

```swift
struct TaskRow: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel  // ✅ 明确的依赖
    
    var body: some View {
        HStack {
            Text(task.title)
            Spacer()
            Button("完成") {
                viewModel.completeTask(task)
            }
        }
    }
}
```

### 3. 视图层次特点

#### 递归性
- 子视图中的所有视图都是父视图的后代
- 环境对象会传递给整个视图树
- 修饰符创建的视图也在传递链中

```swift
struct ParentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {  // 容器视图
            List {  // 容器视图
                ForEach(viewModel.items) { item in
                    ItemRow(item: item)  // 子视图
                        .sheet(isPresented: $showDetail) {
                            DetailView()  // 模态视图也是子视图
                        }
                }
            }
        }
        .environmentObject(viewModel)  // 传递给所有后代
    }
}
```

#### 特殊情况处理

1. **模态视图**：
```swift
.sheet(isPresented: $showDetail) {
    DetailView()
        .environmentObject(viewModel)  // 需要显式传递
}
```

2. **导航链接**：
```swift
NavigationLink {
    DetailView()  // 自动继承环境对象
} label: {
    Text("详情")
}
```

3. **异步加载视图**：
```swift
if let data = asyncData {
    DataView(data: data)  // 继承父视图的环境对象
} else {
    ProgressView()
}
```

#### 最佳实践建议

1. **环境对象使用原则**：
- 全局状态使用环境对象
- 局部状态使用直接传递
- 避免过度使用环境对象

2. **视图组织原则**：
- 保持视图层次清晰
- 合理拆分组件
- 注意数据流向

## 三、数据流动模式

### 1. 视图持有状态模式

#### 实现方式
```swift
struct TaskListView: View {
    // 视图持有 UI 状态
    @State private var searchText: String = ""
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        TextField("搜索", text: $searchText)
            .onChange(of: searchText) { newValue in
                viewModel.search(text: newValue)
            }
    }
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    
    func search(text: String) {
        // 处理业务逻辑
    }
}
```

#### 优缺点
👍 优点：
- 职责分明，视图状态和业务逻辑解耦
- 符合单一职责原则
- 视图逻辑清晰

👎 缺点：
- 状态分散
- 需要手动同步状态
- 代码量较多

### 2. ViewModel 持有状态模式

#### 实现方式
```swift
class TaskViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var tasks: [Task] = []
    
    func fetchTasks() {
        // 使用内部状态处理业务逻辑
    }
}

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        TextField("搜索", text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) { _ in
                viewModel.fetchTasks()
            }
    }
}
```

#### 优缺点
👍 优点：
- 状态集中管理
- 状态一致性好
- 易于复用和持久化
- 代码量较少

👎 缺点：
- 视图和 ViewModel 耦合度高
- 可能违反单一职责原则

## 四、全局状态管理

### 1. App 级别注入

#### 基本实现
```swift
@main
struct TaskMasterApp: App {
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskViewModel)
        }
    }
}
```

#### 适用场景
- 小型应用
- 状态管理简单
- 全局共享需求

### 2. 依赖注入容器

#### 容器设计
```swift
class AppDependencyContainer {
    // 单例模式
    static let shared = AppDependencyContainer()
    
    // 各模块 ViewModel
    let taskViewModel: TaskViewModel
    let categoryViewModel: CategoryViewModel
    let userViewModel: UserViewModel
    
    private init() {
        taskViewModel = TaskViewModel()
        categoryViewModel = CategoryViewModel()
        userViewModel = UserViewModel()
    }
}
```

#### 使用方式
```swift
struct TaskListView: View {
    @StateObject private var viewModel = AppDependencyContainer.shared.taskViewModel
    // ...
}
```

### 3. AppViewModel 架构

#### 架构设计
```swift
class AppViewModel: ObservableObject {
    @Published var taskViewModel: TaskViewModel
    @Published var settingsViewModel: SettingsViewModel
    
    init() {
        self.taskViewModel = TaskViewModel()
        self.settingsViewModel = SettingsViewModel()
    }
}
```

#### 最佳实践
```swift
@main
struct TaskMasterApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}
```

## 五、项目规模选择指南

### 1. 小型项目
- 推荐方案：App 级别环境对象
- 实现方式：单一 ViewModel
- 注意事项：避免过度设计

### 2. 中型项目
- 推荐方案：依赖注入容器
- 实现方式：模块化 ViewModel
- 注意事项：合理划分模块

### 3. 大型项目
- 推荐方案：AppViewModel + 依赖注入
- 实现方式：完整的依赖注入系统
- 注意事项：考虑使用状态管理框架

## 六、最佳实践

### 1. 代码组织
- 视图逻辑保持简单
- 业务逻辑放在 ViewModel
- 合理抽取共用组件
- 遵循 SOLID 原则

### 2. 性能优化
- 减少不必要的状态更新
- 合理使用 @Published
- 注意内存管理
- 避免循环引用

### 3. 测试建议
```swift
// 依赖注入设计
protocol DataServiceProtocol {
    func fetchTasks() async throws -> [Task]
}

class TaskViewModel: ObservableObject {
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = DataService()) {
        self.dataService = dataService
    }
}

// 测试示例
class MockDataService: DataServiceProtocol {
    func fetchTasks() async throws -> [Task] {
        return [] // 返回测试数据
    }
}
```

## 七、注意事项

1. **状态管理**
- 避免过度使用 @Published
- 注意状态更新性能
- 合理划分状态职责

2. **内存管理**
- 注意循环引用
- 正确使用 weak/unowned
- 及时清理资源

3. **代码质量**
- 保持代码可测试性
- 遵循设计原则
- 注重代码复用

## 八、总结

选择合适的状态管理方案需要考虑：
- 项目规模和复杂度
- 团队开发经验
- 维护成本
- 性能要求

关键原则：
- 简单性优先
- 可维护性重要
- 性能适度
- 团队友好

最后建议：
- 从简单方案开始
- 根据需求逐步改进
- 保持代码整洁
- 重视团队反馈

## 九、全局 ViewModel 处理方式

### 1. App 级别注入
最简单的全局 ViewModel 处理方式是在 App 级别注入：

```swift
@main
struct TaskMasterApp: App {
    // 创建一个全局的 ViewModel 实例
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskViewModel) // 注入到整个应用
        }
    }
}
```

### 2. 适用场景分析

👍 **适合的场景**：
- 应用规模较小
- ViewModel 确实需要在全局共享
- 状态管理相对简单

```swift
// 适合全局共享的 ViewModel 示例
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var categories: [Category] = []
    @Published var userPreferences: UserPreferences
    
    // 全局性的业务逻辑
    func fetchTasks() { ... }
    func updateUserPreferences() { ... }
}
```

❌ **不适合的场景**：
- 大型应用
- 需要细粒度控制的场景
- 有多个独立功能模块

### 3. 大型应用的改进方案

```swift
// 1. 按功能拆分 ViewModel
class TaskViewModel: ObservableObject { ... }
class CategoryViewModel: ObservableObject { ... }
class UserViewModel: ObservableObject { ... }

// 2. 使用依赖注入容器
class AppDependencyContainer {
    let taskViewModel: TaskViewModel
    let categoryViewModel: CategoryViewModel
    let userViewModel: UserViewModel
    
    static let shared = AppDependencyContainer()
    
    private init() {
        taskViewModel = TaskViewModel()
        categoryViewModel = CategoryViewModel()
        userViewModel = UserViewModel()
    }
}

// 3. 在需要的地方注入
struct TaskListView: View {
    @StateObject private var viewModel = AppDependencyContainer.shared.taskViewModel
    // ...
}
```

### 4. 推荐的架构方式

```swift
// 1. 创建专门的 AppViewModel
class AppViewModel: ObservableObject {
    @Published var taskViewModel: TaskViewModel
    @Published var settingsViewModel: SettingsViewModel
    
    init() {
        self.taskViewModel = TaskViewModel()
        self.settingsViewModel = SettingsViewModel()
    }
}

// 2. 在 App 中使用
@main
struct TaskMasterApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}

// 3. 在视图中使用
struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        TabView {
            TaskListView()
                .environmentObject(appViewModel.taskViewModel)
            SettingsView()
                .environmentObject(appViewModel.settingsViewModel)
        }
    }
}
```

### 5. 注意事项

1. **内存管理**：
```swift
class AppViewModel: ObservableObject {
    // 使用 @StateObject 而不是 @ObservedObject
    // 确保 ViewModel 的生命周期与 App 一致
    @StateObject private var taskViewModel = TaskViewModel()
}
```

2. **性能考虑**：
```swift
class TaskViewModel: ObservableObject {
    // 只将需要触发 UI 更新的属性标记为 @Published
    @Published var tasks: [Task] = []
    // 内部状态不需要标记
    private var cache: [String: Task] = [:]
}
```

3. **测试友好**：
```swift
class TaskViewModel: ObservableObject {
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = DataService()) {
        self.dataService = dataService
    }
}
```

### 6. 选择建议

1. **小型项目**：
- 直接在 App 级别使用环境对象
- 单一 ViewModel 管理所有状态

2. **中型项目**：
- 使用依赖注入容器
- 按功能模块拆分 ViewModel

3. **大型项目**：
- 使用专门的 AppViewModel
- 完整的依赖注入系统
- 考虑使用状态管理框架

### 7. 进阶实践

#### 模块化设计
```swift
// 1. 定义模块协议
protocol ModuleViewModel: ObservableObject {
    func initialize()
    func cleanup()
}

// 2. 实现具体模块
class TaskModule: ModuleViewModel {
    @Published var taskViewModel: TaskViewModel
    @Published var categoryViewModel: CategoryViewModel
    
    init() {
        self.taskViewModel = TaskViewModel()
        self.categoryViewModel = CategoryViewModel()
    }
    
    func initialize() {
        taskViewModel.fetchInitialData()
    }
    
    func cleanup() {
        // 清理资源
    }
}
```

#### 生命周期管理
```swift
class AppViewModel: ObservableObject {
    private var modules: [ModuleViewModel] = []
    
    func registerModule(_ module: ModuleViewModel) {
        modules.append(module)
        module.initialize()
    }
    
    func cleanupModules() {
        modules.forEach { $0.cleanup() }
    }
}
```

#### 状态恢复
```swift
class AppViewModel: ObservableObject {
    @AppStorage("lastActiveTab") private var lastActiveTab: Int = 0
    
    func restoreState() {
        // 恢复应用状态
    }
    
    func saveState() {
        // 保存当前状态
    }
}
```

### 8. 实际应用示例

#### 完整的 App 结构
```swift
@main
struct TaskMasterApp: App {
    @StateObject private var appViewModel: AppViewModel = {
        let viewModel = AppViewModel()
        // 注册模块
        viewModel.registerModule(TaskModule())
        viewModel.registerModule(SettingsModule())
        return viewModel
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .onAppear {
                    appViewModel.restoreState()
                }
                .onDisappear {
                    appViewModel.saveState()
                }
        }
    }
}
```

#### 模块化视图组织
```swift
struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView {
            TaskModuleView()
                .tabItem { /* ... */ }
            
            SettingsModuleView()
                .tabItem { /* ... */ }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                appViewModel.restoreState()
            case .background:
                appViewModel.saveState()
            default:
                break
            }
        }
    }
}
```

### 9. 调试与开发工具

#### 状态监控
```swift
extension AppViewModel {
    func debugPrint() {
        #if DEBUG
        print("当前应用状态：")
        modules.forEach { module in
            print("模块: \(type(of: module))")
            // 打印模块状态
        }
        #endif
    }
}
```

#### 开发环境配置
```swift
class AppViewModel: ObservableObject {
    #if DEBUG
    static let preview: AppViewModel = {
        let viewModel = AppViewModel()
        // 配置预览数据
        return viewModel
    }()
    #endif
}
```

### 10. 迁移策略

1. **从简单架构迁移**：
```swift
// 1. 原始结构
class TaskViewModel: ObservableObject { ... }

// 2. 中间过渡
class TaskViewModel: ObservableObject, ModuleViewModel { ... }

// 3. 最终模块化
class TaskModule: ModuleViewModel {
    let taskViewModel: TaskViewModel
    // 新增功能
}
```

2. **渐进式改进**：
- 先保持现有功能
- 逐步引入模块化
- 增量添加新特性
- 保证向后兼容

3. **注意事项**：
- 保持数据一致性
- 维护现有功能
- 完善测试覆盖
- 文档更新