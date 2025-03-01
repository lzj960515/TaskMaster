# Swift 枚举与协议知识点

## 1. Swift 枚举基础

Swift 枚举是一种强大的类型，可以定义一组相关的值并提供额外的功能。与其他语言中的枚举不同，Swift 枚举可以：

- 具有关联值
- 具有原始值
- 有计算属性和方法
- 遵循协议
- 有初始化器

### 基本语法

```swift
enum TaskPriority: String {
  case low = "低"
  case medium = "中"
  case high = "高"
}
```

## 2. 枚举常用协议

### 2.1 原始值类型 (如 String)

```swift
enum TaskPriority: String {
  case low = "低"
  case medium = "中"
  case high = "高"
}
```

**作用**：
- 为每个枚举成员关联一个固定的原始值
- 提供 `rawValue` 属性访问原始值
- 提供 `init(rawValue:)` 初始化方法，返回可选值

**使用场景**：
- 枚举值需要以特定格式表示（如显示文本、存储格式）
- 需要在字符串和枚举值之间转换

### 2.2 CaseIterable 协议

```swift
enum TaskPriority: String, CaseIterable {
  case low = "低"
  case medium = "中"
  case high = "高"
}
```

**作用**：
- 自动生成 `allCases` 静态属性，包含所有枚举情况的集合
- 使枚举可以被遍历

**使用场景**：
- 需要列出所有可能的枚举值（如在界面选择器中）
- 需要对所有枚举情况执行操作

```swift
// 遍历所有优先级
for priority in TaskPriority.allCases {
  print(priority.rawValue)
}
```

### 2.3 Identifiable 协议

```swift
enum TaskPriority: String, CaseIterable, Identifiable {
  case low = "低"
  case medium = "中"
  case high = "高"
  
  var id: String { self.rawValue }
}
```

**作用**：
- 提供唯一标识符，使类型可以用于需要唯一标识的场景
- 要求实现 `id` 属性

**使用场景**：
- SwiftUI 中的 List、ForEach 等组件
- 需要唯一区分实例的集合操作

```swift
// 在 SwiftUI 中直接使用枚举
List {
  ForEach(TaskPriority.allCases) { priority in
    Text(priority.rawValue)
  }
}
```

### 2.4 Codable 协议

```swift
enum TaskPriority: String, CaseIterable, Identifiable, Codable {
  case low = "低"
  case medium = "中"
  case high = "高"
}
```

**作用**：
- 使类型可以被编码和解码（序列化和反序列化）
- 原始值枚举自动获得 Codable 实现

**使用场景**：
- 将数据保存到文件或数据库
- 通过网络传输数据
- 用户设置和配置存储

```swift
// 编码示例
let encoder = JSONEncoder()
let priority = TaskPriority.high
let jsonData = try encoder.encode(priority)

// 解码示例
let decoder = JSONDecoder()
let decodedPriority = try decoder.decode(TaskPriority.self, from: jsonData)
```

## 3. 扩展枚举功能

枚举可以通过计算属性和方法进一步增强其功能：

```swift
enum TaskPriority: String, CaseIterable, Identifiable, Codable {
  case low = "低"
  case medium = "中"
  case high = "高"

  var id: String { self.rawValue }

  var color: String {
    switch self {
    case .low:
      return "PriorityLow"
    case .medium:
      return "PriorityMedium"
    case .high:
      return "PriorityHigh"
    }
  }

  var symbol: String {
    switch self {
    case .low:
      return "arrow.down.circle"
    case .medium:
      return "equal.circle"
    case .high:
      return "arrow.up.circle"
    }
  }
}
```

## 4. 枚举的实际应用场景

- **UI 展示**：不同优先级显示不同颜色和图标
- **数据筛选**：根据优先级筛选任务
- **用户选择**：在任务创建/编辑界面选择优先级
- **数据排序**：根据优先级对任务排序
- **数据持久化**：将优先级保存到数据库或文件

## 5. 枚举与可选值结合使用

```swift
// 尝试从字符串转换为枚举，处理可能的失败情况
let priorityString = "极高" // 不是有效的原始值
let priority = TaskPriority(rawValue: priorityString) ?? .medium

// 在计算属性中使用
var priority: TaskPriority {
  get {
    return TaskPriority(rawValue: priorityRaw) ?? .medium
  }
  set {
    priorityRaw = newValue.rawValue
  }
}
```

## 6. 枚举最佳实践

- **命名**：使用单数名词，首字母大写
- **关联有意义的原始值**：尤其是用于展示的文本
- **提供默认值**：处理无效输入时提供合理的默认值
- **遵循适当的协议**：根据使用场景选择合适的协议
- **添加辅助属性和方法**：增强枚举的功能性
- **考虑本地化**：用于显示的字符串应该支持本地化

## 7. 总结

Swift 枚举结合协议是一种强大的组合，可以创建既安全又灵活的类型。通过正确选择协议，可以使枚举:

- 支持原始值与字符串转换 (String)
- 支持迭代所有情况 (CaseIterable)
- 在集合和UI组件中使用 (Identifiable)
- 支持数据持久化 (Codable)

这种组合使得枚举能够满足从数据模型到用户界面的各种需求，成为Swift编程中不可或缺的工具。