# Core Data 模型设计与级联删除

## 数据模型文件(.xcdatamodeld)

在Core Data中，数据模型文件(`.xcdatamodeld`)是定义应用程序数据结构的核心文件。它包含：

- 实体(Entity)定义：相当于数据库中的表
- 属性(Attribute)定义：相当于表中的列
- 关系(Relationship)定义：实体之间的连接
- 获取请求(Fetch Request)模板
- 配置(Configuration)信息

这个文件通常在Xcode中以图形界面方式编辑，但本质上是一个XML文件。

## 实体关系设计

在任务管理应用中，典型的实体关系结构包括：

```xml
<entity name="Task">
    <!-- 基本属性 -->
    <attribute name="id" type="UUID"/>
    <attribute name="title" type="String"/>
    <attribute name="isCompleted" type="Boolean"/>
    
    <!-- 关系 -->
    <relationship name="category" optional="YES" maxCount="1" 
                 destinationEntity="Category" inverseName="tasks" inverseEntity="Category"/>
    <relationship name="tags" optional="YES" toMany="YES" 
                 destinationEntity="Tag" inverseName="tasks" inverseEntity="Tag"/>
</entity>

<entity name="Category">
    <attribute name="id" type="UUID"/>
    <attribute name="name" type="String"/>
    <relationship name="tasks" optional="YES" toMany="YES" 
                 destinationEntity="Task" inverseName="category" inverseEntity="Task"/>
</entity>

<entity name="Tag">
    <attribute name="id" type="UUID"/>
    <attribute name="name" type="String"/>
    <relationship name="tasks" optional="YES" toMany="YES" 
                 destinationEntity="Task" inverseName="tags" inverseEntity="Task"/>
</entity>
```

关系类型：
- **一对多关系**：一个Category关联多个Task
- **多对多关系**：多个Tag可以关联多个Task，反之亦然

## 级联删除规则(Deletion Rules)

在Core Data中，当删除一个对象时，可以通过`deletionRule`属性定义与其相关联的对象应该如何处理。这类似于SQL数据库中的外键约束。

### 四种删除规则

1. **Nullify**(`"Nullify"`)
   - 最常用的规则
   - 删除对象时，相关联对象的引用会被设置为null
   - 例如：删除Category时，关联的Task的category属性会被设为nil

2. **Cascade**(`"Cascade"`)
   - 删除对象时，与其关联的所有对象也会被删除
   - 会导致连锁反应，可能删除大量数据
   - 例如：如果Task与Category的关系设置为Cascade，删除Category会同时删除所有关联的Task

3. **Deny**(`"Deny"`)
   - 如果对象有关联的对象，则阻止删除该对象
   - 用于确保引用完整性
   - 例如：如果设置为Deny，则Category有关联Task时无法被删除

4. **No Action**(`"NoAction"`)
   - 不采取任何特定操作
   - 可能导致数据不一致，一般不推荐使用

### 实际应用示例

在TaskMaster应用中：

1. **Task ⟷ Category**关系：
   - 删除规则设为`Nullify`
   - 删除Category后，关联的Task保留，但category属性变为nil
   - 代码中不需要手动处理这种关系变更

2. **Task ⟷ Tag**关系：
   - 删除规则设为`Nullify`
   - 删除Tag后，该Tag会自动从所有Task的tags集合中被移除
   - Core Data会自动管理这种多对多关系

## 编程实践

在代码中，设置了`Nullify`规则后，不需要手动清除关系：

```swift
// 简化的删除分类函数 - Core Data会自动处理关系
func deleteCategory(_ category: Category) {
    viewContext.delete(category)
    saveContext()
}
```

对于标签，尽管Core Data会自动处理关系，但显式代码可以增强可读性：

```swift
// 删除标签函数 - 显式处理关系
func deleteTag(_ tag: Tag) {
    // 手动处理与任务的关系（技术上不是必需的）
    let tasks = tag.tasks?.allObjects as? [Task] ?? []
    for task in tasks {
        task.removeFromTags(tag)
    }
    
    viewContext.delete(tag)
    saveContext()
}
```

## 总结

- 数据模型文件(.xcdatamodeld)是Core Data应用的基础
- 正确设计实体关系可以简化数据管理
- 删除规则决定了关联对象在删除操作时的行为
- `Nullify`规则最常用，保留关联对象但清除引用
- Core Data自动管理关系变更，但显式代码可提高可读性 