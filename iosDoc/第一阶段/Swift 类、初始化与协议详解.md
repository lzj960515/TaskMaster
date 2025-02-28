# Swift 类、初始化与协议详解

## 1. Swift 中的类与结构体

Swift 提供了两种主要的复杂数据类型：类（Class）和结构体（Struct），它们有着不同的特性和使用场景。

### 类（Class）
- **引用类型**：传递时复制的是引用，多个变量可以引用同一实例
- **继承**：支持单继承，可以继承父类的属性和方法
- **初始化**：需要显式处理所有非可选、无默认值的属性
- **析构**：支持析构函数 `deinit`
- **引用计数**：使用 ARC 管理内存

```swift
class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    
    init(initialTasks: [TodoTask] = []) {
        self.tasks = initialTasks
    }
}
```

### 结构体（Struct）
- **值类型**：传递时复制整个值，创建独立实例
- **无继承**：不支持继承
- **自动初始化**：提供成员逐一初始化器
- **性能**：通常更轻量级

```swift
struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var isAddingTask = false
    
    var body: some View {
        // 视图内容
    }
}
```

## 2. Swift 初始化机制

### 类的初始化

1. **显式初始化**
   - 当类中有属性没有默认值时，必须提供初始化方法
   ```swift
   class User {
       let id: UUID
       var name: String
       
       init(name: String) {
           self.id = UUID()
           self.name = name
       }
   }
   ```

2. **默认初始化**
   - 当所有属性都有默认值时，Swift 会自动提供无参数初始化器
   ```swift
   class Counter {
       var count = 0  // 有默认值
       var name = "Counter"  // 有默认值
   }
   // 可以直接使用: let counter = Counter()
   ```

### 结构体的初始化

1. **成员逐一初始化器**
   - Swift 自动为结构体提供一个接受所有未初始化属性作为参数的初始化器
   ```swift
   struct Point {
       var x: Int
       var y: Int
   }
   // 自动生成: init(x: Int, y: Int)
   let point = Point(x: 10, y: 20)
   ```

2. **自定义初始化器**
   - 可以添加自定义初始化方法
   - 如果定义了任何初始化器，将不再自动生成成员逐一初始化器

## 3. Swift 协议

协议定义了一个方法、属性或其他要求的蓝图，类、结构体或枚举可以遵循协议以提供这些要求的具体实现。

### 协议基础

```swift
protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}

struct User: Identifiable {
    let id = UUID()  // 实现协议要求
    var name: String
}
```

### 协议与 Java 接口的对比

| 特性 | Swift 协议 | Java 接口 |
|------|------------|-----------|
| 基本用途 | 定义类型行为规范 | 定义类行为规范 |
| 语法 | `struct/class A: Protocol` | `class A implements Interface` |
| 多重遵循 | 支持 `class A: X, Y, Z` | 支持 `class A implements X, Y, Z` |
| 可应用类型 | 类、结构体、枚举 | 仅类 |
| 默认实现 | 通过协议扩展支持 | Java 8+使用 default 关键字支持 |
| 属性要求 | 支持 | 传统上不支持，Java 8+支持常量 |
| 值类型支持 | 支持 | 不支持 |

### 协议语法示例

```swift
// 定义协议
protocol Playable {
    var isPlaying: Bool { get set }
    func play()
    func pause()
}

// 遵循协议
class AudioPlayer: Playable {
    var isPlaying: Bool = false
    
    func play() {
        isPlaying = true
        print("Playing audio...")
    }
    
    func pause() {
        isPlaying = false
        print("Audio paused")
    }
}
```

## 4. SwiftUI 中的常用协议

SwiftUI 大量使用协议来定义组件行为，以下是最常见的几个：

### View 协议

```swift
protocol View {
    associatedtype Body: View
    var body: Body { get }
}
```

- 所有 SwiftUI 视图组件必须遵循
- 要求提供一个 `body` 计算属性，定义视图的内容和外观
- 使用实例：
  ```swift
  struct ContentView: View {
      var body: some View {
          Text("Hello, World!")
      }
  }
  ```

### ObservableObject 协议

```swift
protocol ObservableObject: AnyObject {
    associatedtype ObjectWillChangePublisher: Publisher = ObservableObjectPublisher
    var objectWillChange: ObjectWillChangePublisher { get }
}
```

- 用于视图模型和数据模型
- 允许发布属性变化通知
- 通常与 `@Published` 属性包装器配合使用
- 使用实例：
  ```swift
  class UserViewModel: ObservableObject {
      @Published var username = ""
      @Published var isLoggedIn = false
  }
  ```

### Identifiable 协议

```swift
protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}
```

- 为对象提供唯一标识符
- 常用于列表、集合视图中的数据项
- SwiftUI 的 `List` 和 `ForEach` 利用此协议追踪项目变化
- 使用实例：
  ```swift
  struct TodoTask: Identifiable {
      let id = UUID()
      var title: String
      var isCompleted = false
  }
  ```

## 5. 协议扩展与默认实现

Swift 的协议可以通过扩展提供默认实现，这是 Swift 协议相比 Java 接口的强大特性之一。

```swift
protocol Greetable {
    var name: String { get }
    func greet() -> String
}

extension Greetable {
    // 默认实现
    func greet() -> String {
        return "Hello, \(name)!"
    }
}

struct Person: Greetable {
    let name: String
    // 无需实现 greet()，将使用默认实现
}

let john = Person(name: "John")
print(john.greet())  // 输出: "Hello, John!"
```

## 6. 协议的进阶特性

### 协议组合

```swift
protocol Named {
    var name: String { get }
}

protocol Aged {
    var age: Int { get }
}

func greet(person: Named & Aged) {
    print("Hello, \(person.name)! You are \(person.age) years old.")
}
```

### 协议作为类型

```swift
// 协议作为参数类型
func process(drawable: any Drawable) {
    drawable.draw()
}

// 协议作为返回类型
func createRandomShape() -> any Drawable {
    let random = Int.random(in: 0...1)
    return random == 0 ? Circle(radius: 10) : Rectangle(width: 10, height: 20)
}
```

### 关联类型

```swift
protocol Container {
    associatedtype Item
    var count: Int { get }
    mutating func add(_ item: Item)
    subscript(i: Int) -> Item { get }
}
```

## 7. 协议优先编程

Swift 推崇"协议优先编程"(Protocol-Oriented Programming)，这是一种设计理念，相比传统的面向对象编程更侧重于定义和组合协议。

### 优势

1. **灵活性**：不受继承层次限制
2. **组合性**：可以组合多个协议的功能
3. **值类型友好**：适用于结构体和枚举
4. **默认实现**：通过协议扩展减少代码重复
5. **横切关注点**：可以跨不同类型添加共享行为

### 实例：协议优先设计

```swift
// 定义能力而非类层次
protocol Identifiable { /* ... */ }
protocol Persistable { /* ... */ }
protocol Displayable { /* ... */ }

// 组合协议提供跨类型功能
extension Persistable where Self: Identifiable {
    func save() {
        // 实现保存逻辑，使用 id 属性
    }
}

// 应用到不同类型
struct User: Identifiable, Persistable, Displayable { /* ... */ }
struct Document: Identifiable, Persistable { /* ... */ }
enum Status: Displayable { /* ... */ }
```

## 8. 扩展与静态成员

### 扩展（Extension）

扩展是 Swift 中的一个强大特性，允许向现有类型添加新功能，而无需修改原始定义或继承。

```swift
extension String {
    func capitalizeFirstLetter() -> String {
        return self.prefix(1).uppercased() + self.dropFirst()
    }
}

// 使用扩展方法
let name = "swift"
print(name.capitalizeFirstLetter()) // 输出 "Swift"
```

**扩展的主要特点：**

- 可以添加新的方法、计算属性、下标、协议遵循等
- 不能添加存储属性或修改已有的功能
- 可以扩展任何类型，包括类、结构体、枚举、协议甚至系统类型
- 可以分布在多个文件中，与文件名无关联

**扩展与继承的区别：**
- 扩展是在原有类型上直接添加功能，而非创建新类型
- 扩展不支持方法覆盖，只能添加新功能
- 扩展适用于任何类型，包括结构体和枚举

### 静态成员（Static Members）

静态成员是属于类型本身而非实例的属性和方法。

```swift
struct Math {
    static let pi = 3.14159
    static func square(of number: Double) -> Double {
        return number * number
    }
}

// 通过类型名直接访问
let area = Math.pi * Math.square(of: 2)
```

**静态成员的特点：**

- 通过类型名直接访问，无需创建实例
- 所有实例共享同一个静态成员
- 可以用于存储类型级别的常量、工厂方法、工具函数等
- 在类中可以使用 `class` 关键字声明可被子类覆盖的静态成员

### 扩展与静态成员的结合

扩展和静态成员结合是 Swift 中常见且强大的模式，特别适合添加示例数据、工具方法等：

```swift
// 在模型定义中的扩展部分添加静态示例数据
struct TodoTask {
    var title: String
    var isCompleted: Bool
    var id = UUID()
}

extension TodoTask {
    static let sampleTasks = [
        TodoTask(title: "完成SwiftUI学习", isCompleted: true),
        TodoTask(title: "实现任务列表显示", isCompleted: false),
        TodoTask(title: "添加新任务功能", isCompleted: false)
    ]
}

// 可在任何地方通过 TodoTask.sampleTasks 访问
```

**这种模式的优势：**

- **代码组织**：将示例数据与核心模型逻辑分离
- **命名空间**：示例数据自然地存在于类型的命名空间中
- **可发现性**：通过类型名可以轻松找到相关功能
- **避免全局状态**：比全局变量更有组织性

### 文件组织与命名

在 Swift 中，文件名和类型名没有强制关联：

- 一个文件可以包含多个类型定义
- 类型名称不必与文件名匹配
- 扩展可以位于不同的文件中

这种灵活性允许开发者按功能而非类型边界组织代码：

```swift
// 文件: TodoTask.swift - 基本定义
struct TodoTask { /* 核心属性与方法 */ }

// 文件: TodoTask+SampleData.swift - 示例数据
extension TodoTask { static let sampleTasks = [...] }

// 文件: TodoTask+Formatting.swift - 格式化相关扩展
extension TodoTask { func formattedTitle() -> String {...} }
```

这种基于功能的代码组织是 Swift 的一种常见实践，使代码库保持模块化和可维护。

## 总结

Swift 的类、初始化机制和协议系统构成了语言的核心部分。理解这些概念对于构建高效、可维护的 Swift 应用至关重要，特别是在 SwiftUI 框架中：

- **类**用于需要引用语义的场景，如视图模型
- **结构体**用于值语义场景，如 UI 组件
- **初始化**规则因类型不同而异，结构体享有便利的自动初始化器
- **协议**定义了类型行为的蓝图，类似 Java 接口但功能更强大
- **SwiftUI** 大量使用协议来定义组件行为和数据流

通过掌握这些概念，开发者可以更好地理解 Swift 的设计哲学，编写出更符合 Swift 语言习惯的高质量代码。
