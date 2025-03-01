# Core Data 与 Swift 语法知识点总结

## 1. NSManagedObject 与 @NSManaged 注解

### @NSManaged 注解的作用
- **延迟加载**：属性值按需从持久化存储获取，避免一次性加载所有数据
- **动态生成**：属性的实际实现(getter/setter)由Core Data在运行时动态生成
- **变更追踪**：Core Data自动跟踪属性变化，便于管理数据持久化状态

### 实体类定义
```swift
class Task: NSManagedObject, Identifiable {
  @NSManaged public var id: UUID
  @NSManaged public var title: String
  @NSManaged public var desc: String
  @NSManaged public var isCompleted: Bool
  @NSManaged public var priorityRaw: String
  @NSManaged public var dueDate: Date?
  @NSManaged public var createdAt: Date?
  
  // 其他实现...
}
```

## 2. 计算属性与枚举转换

### 计算属性
计算属性提供了自定义的getter和setter逻辑，用于在存储格式和使用格式之间转换数据。

```swift
var priority: TaskPriority {
  get {
    return TaskPriority(rawValue: priorityRaw) ?? .medium
  }
  set {
    priorityRaw = newValue.rawValue
  }
}
```

### Swift空合运算符 (??)
- 用法：`表达式1 ?? 表达式2`
- 作用：当表达式1为nil时返回表达式2，否则返回表达式1
- 示例：`TaskPriority(rawValue: priorityRaw) ?? .medium` 表示尝试转换，转换失败则使用默认值

### 枚举简写语法
- 完整写法：`TaskPriority.medium`
- 简写形式：`.medium`（当上下文明确是TaskPriority类型时）
- 多枚举冲突：当多个枚举有相同成员名称时，必须使用完整写法或确保上下文明确

## 3. Core Data 实体初始化

### 标准初始化模式
```swift
convenience init(context: NSManagedObjectContext) {
  let entity = NSEntityDescription.entity(forEntityName: "Task", in: context)!
  self.init(entity: entity, insertInto: context)
  
  // 初始化默认值
  self.id = UUID()
  self.createdAt = Date()
  self.title = ""
  self.desc = ""
  self.isCompleted = false
  self.priorityRaw = TaskPriority.medium.rawValue
}
```

### 替代初始化方式
```swift
// 方式1：使用insertNewObject
static func createTask(in context: NSManagedObjectContext) -> Task {
  return NSEntityDescription.insertNewObject(forEntityName: "Task", into: context) as! Task
}

// 方式2：更安全的可选处理
convenience init?(context: NSManagedObjectContext) {
  guard let entity = NSEntityDescription.entity(forEntityName: "Task", in: context) else {
    return nil
  }
  self.init(entity: entity, insertInto: context)
  // 初始化属性...
}
```

## 4. 实体查询与获取请求

```swift
extension Task {
  static func fetchRequest() -> NSFetchRequest<Task> {
    return NSFetchRequest<Task>(entityName: "Task")
  }
}
```

## 5. Core Data 最佳实践

- **命名一致性**：实体名称必须与Core Data模型中定义的名称精确匹配
- **避免强制解包**：处理可选值时应当谨慎，优先使用guard或可选绑定
- **默认值**：为所有属性设置合理的默认值，避免nil值导致的运行时错误
- **计算属性**：使用计算属性处理复杂数据类型转换，保持数据模型简洁
- **便捷方法**：添加静态方法简化实体创建和查询操作 