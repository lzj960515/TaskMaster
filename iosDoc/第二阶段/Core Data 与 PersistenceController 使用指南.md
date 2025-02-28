# Core Data 与 PersistenceController 使用指南

## 1. PersistenceController 简介

`PersistenceController` 是一个管理 Core Data 持久化存储的结构体，在 iOS 应用中扮演数据持久化管理的核心角色。它负责创建和配置 Core Data 堆栈，提供对持久化存储的统一访问点。

### 主要职责

- 创建并管理 `NSPersistentContainer`
- 加载和配置持久化存储
- 处理存储错误
- 提供存储上下文（Context）
- 管理数据保存操作

### 典型实现

```swift
struct PersistenceController {
  // 全局单例
  static let shared = PersistenceController()

  // Core Data 容器
  let container: NSPersistentContainer

  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "AppName")

    // 可选：配置内存存储而非磁盘存储（用于测试）
    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    // 加载持久化存储
    container.loadPersistentStores { description, error in
      if let error = error {
        fatalError("无法加载Core Data: \(error.localizedDescription)")
      }
    }

    // 优化配置
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }

  // 保存上下文变更
  func save() throws {
    let context = container.viewContext
    if context.hasChanges {
      try context.save()
    }
  }
}
```

## 2. 在 SwiftUI 应用中集成

在 SwiftUI 应用入口点（如 `App` 结构体）中初始化 `PersistenceController` 并将其注入视图环境：

```swift
@main
struct MyApp: App {
    // 创建持久化控制器
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 注入托管对象上下文到环境中
                .environment(\.managedObjectContext, 
                             persistenceController.container.viewContext)
                // 可选：注入视图模型
                .environmentObject(
                    ViewModel(context: persistenceController.container.viewContext))
        }
    }
}
```

## 3. 基础 CRUD 操作示例

### 创建(Create)

```swift
// 获取托管对象上下文
let context = PersistenceController.shared.container.viewContext

// 创建新实体
let newItem = Item(context: context)
newItem.id = UUID()
newItem.title = "新项目"
newItem.timestamp = Date()

// 保存到持久化存储
do {
    try PersistenceController.shared.save()
} catch {
    print("创建失败: \(error.localizedDescription)")
}
```

### 读取(Read)

```swift
let context = PersistenceController.shared.container.viewContext

// 创建获取请求
let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()

// 可选：添加排序
let sortByDate = NSSortDescriptor(key: "timestamp", ascending: false)
fetchRequest.sortDescriptors = [sortByDate]

// 可选：添加过滤条件
fetchRequest.predicate = NSPredicate(format: "isComplete == %@", NSNumber(value: false))

do {
    let items = try context.fetch(fetchRequest)
    // 处理获取到的数据
} catch {
    print("读取失败: \(error.localizedDescription)")
}
```

### 更新(Update)

```swift
let context = PersistenceController.shared.container.viewContext

// 查找要更新的项目
let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)

do {
    let results = try context.fetch(fetchRequest)
    if let itemToUpdate = results.first {
        // 更新属性
        itemToUpdate.title = "更新后的标题"
        
        // 保存更改
        try PersistenceController.shared.save()
    }
} catch {
    print("更新失败: \(error.localizedDescription)")
}
```

### 删除(Delete)

```swift
let context = PersistenceController.shared.container.viewContext

// 获取要删除的项目
let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)

do {
    let results = try context.fetch(fetchRequest)
    if let itemToDelete = results.first {
        // 删除实体
        context.delete(itemToDelete)
        
        // 保存更改
        try PersistenceController.shared.save()
    }
} catch {
    print("删除失败: \(error.localizedDescription)")
}
```

## 4. 在视图模型中使用

推荐在视图模型（ViewModel）中封装 Core Data 操作，以实现更好的关注点分离：

```swift
class TaskViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var items: [Item] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchItems()
    }
    
    // 获取所有项目
    func fetchItems() {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            items = try context.fetch(request)
        } catch {
            print("获取项目失败: \(error)")
        }
    }
    
    // 添加新项目
    func addItem(title: String) {
        let newItem = Item(context: context)
        newItem.id = UUID()
        newItem.title = title
        newItem.timestamp = Date()
        
        saveContext()
    }
    
    // 更新项目
    func updateItem(_ item: Item, title: String) {
        item.title = title
        saveContext()
    }
    
    // 删除项目
    func deleteItem(_ item: Item) {
        context.delete(item)
        saveContext()
    }
    
    // 保存上下文
    private func saveContext() {
        do {
            try PersistenceController.shared.save()
            fetchItems() // 重新加载数据以更新UI
        } catch {
            print("保存失败: \(error)")
        }
    }
}
```

## 5. 在 SwiftUI 视图中使用

```swift
struct ItemListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TaskViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: TaskViewModel(context: context))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Text(item.title ?? "无标题")
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            Button(action: addItem) {
                Label("添加", systemImage: "plus")
            }
        }
    }
    
    private func addItem() {
        viewModel.addItem(title: "新项目")
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.deleteItem(viewModel.items[index])
        }
    }
}
```

## 6. 高级应用

### 背景上下文处理

对于耗时操作，使用背景上下文可以避免阻塞主线程：

```swift
func performBackgroundTask() {
    let context = PersistenceController.shared.container.newBackgroundContext()
    context.perform {
        // 在背景上下文中执行操作
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            // 处理数据
            try context.save()
        } catch {
            print("背景任务失败: \(error)")
        }
    }
}
```

### 使用 FetchRequest 在 SwiftUI 中直接获取数据

```swift
struct ContentView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        predicate: NSPredicate(format: "isComplete == %@", NSNumber(value: false))
    ) private var items: FetchedResults<Item>
    
    var body: some View {
        List {
            ForEach(items) { item in
                Text(item.title ?? "")
            }
        }
    }
}
```

## 7. 最佳实践

1. **使用单例模式**：通过 `PersistenceController.shared` 确保整个应用使用相同的持久化存储

2. **错误处理**：妥善处理 Core Data 操作过程中可能出现的错误

3. **性能考虑**：
   - 对于大量数据，使用分页加载
   - 耗时操作放在后台上下文中执行
   - 使用 `NSBatchDeleteRequest` 批量删除大量数据

4. **视图模型封装**：将 Core Data 操作封装在视图模型中，遵循 MVVM 设计模式

5. **合理使用预测**：合理设计 `NSPredicate` 以过滤数据，减少内存使用

6. **关系管理**：谨慎处理实体间的关系，避免级联删除问题

## 8. 总结

`PersistenceController` 作为 Core Data 堆栈的管理中心，提供了一种简洁、高效的方式来处理数据持久化需求。正确使用这一模式可以使应用的数据层与 UI 层清晰分离，同时确保数据操作的一致性和可靠性。

通过遵循本文介绍的模式和实践，可以在 SwiftUI 应用中构建健壮的数据持久化系统，为用户提供流畅的数据交互体验。 