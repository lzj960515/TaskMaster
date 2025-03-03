# SwiftUI 数据流与状态管理

## 一、数据传递方式

### 1. 环境对象（Environment Object）
环境对象是 SwiftUI 中的依赖注入机制，用于在视图层次结构中共享数据。

```swift
// 注入环境对象
.environmentObject(viewModel)

// 接收环境对象
@EnvironmentObject var viewModel: TaskViewModel
```

**适用场景**：
- 深层视图层次结构
- 多个不相关视图需要访问同一个对象
- 需要全局共享的数据

### 2. 直接传递（ObservedObject）
通过构造函数直接传递对象的方式。

```swift
// 直接传递
FilterView(viewModel: viewModel)

// 接收对象
@ObservedObject var viewModel: TaskViewModel
```

**适用场景**：
- 简单的父子视图关系
- 需要明确依赖关系的场景
- 小型视图层次结构

## 二、数据流动模式

### 1. 视图持有状态模式

```swift
struct TaskListView: View {
    // 视图持有 UI 状态
    @State private var searchText: String = ""
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        TextField("搜索", text: $searchText)
            .onChange(of: searchText) { newValue in
                // 通知 ViewModel 执行业务逻辑
                viewModel.search(text: newValue)
            }
    }
}

class TaskViewModel: ObservableObject {
    // ViewModel 只持有核心业务数据
    @Published var tasks: [Task] = []
    
    func search(text: String) {
        // 处理业务逻辑
    }
}
```

**优点**：
- 职责分明
- 视图状态和业务逻辑解耦
- 更符合单一职责原则

**缺点**：
- 状态分散
- 需要手动同步状态
- 代码量较多

### 2. ViewModel 持有状态模式

```swift
class TaskViewModel: ObservableObject {
    // ViewModel 持有所有状态
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

**优点**：
- 状态集中管理
- 状态一致性好
- 易于复用和持久化
- 代码量较少

**缺点**：
- 视图和 ViewModel 耦合度高
- 可能违反单一职责原则

## 三、@Published 属性包装器

### 1. 作用机制
- 将属性标记为可观察
- 当属性值变化时通知所有观察者
- 触发视图刷新

### 2. 使用场景
- 需要在视图中响应的数据
- 需要在多个视图间共享的状态
- 需要持久化的数据

## 四、最佳实践建议

### 1. 选择状态管理模式
- 小型项目：可以使用 ViewModel 持有状态模式，简单直接
- 大型项目：建议使用视图持有状态模式，职责更清晰
- 特殊需求：根据具体场景选择合适的模式

### 2. 数据传递方式选择
- 简单父子关系：优先使用直接传递（@ObservedObject）
- 复杂视图层次：考虑使用环境对象（@EnvironmentObject）
- 全局状态：使用环境对象或状态管理框架

### 3. 代码组织建议
- 保持视图逻辑简单
- 业务逻辑放在 ViewModel 中
- 适当抽取共用组件
- 注意状态更新性能

## 五、注意事项

1. 避免过度使用 @Published
2. 注意内存泄漏问题
3. 合理划分视图和状态的职责
4. 保持代码可测试性
5. 考虑状态更新的性能影响

## 六、总结

SwiftUI 的数据流和状态管理方案需要根据具体项目需求选择。无论选择哪种方式，都要注意：
- 代码可维护性
- 状态一致性
- 性能影响
- 开发效率

选择合适的方案比追求完美的方案更重要。在实际开发中，可以根据项目规模和团队情况灵活选择。 