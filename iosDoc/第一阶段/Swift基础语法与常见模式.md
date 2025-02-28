# Swift基础语法与常见模式

## 1. 变量与常量

Swift中通过两个关键字来声明数据：

### let - 常量
- 声明后值**不能更改**
- 用于不需要修改的数据
- 如果是值类型(如struct)，整个对象及其所有属性都不可修改
- 如果是引用类型(如class)，引用不能改变，但对象内部的可变属性可以修改

```swift
let constantNumber = 42          // 简单常量
let constantTask = TodoTask(title: "学习Swift") // 对象常量
```

### var - 变量
- 声明后值**可以更改**
- 用于需要修改的数据

```swift
var counter = 0                  // 可以修改
var username = "Guest"           // 可以修改
```

## 2. 可选值与可选绑定

### 可选值(Optionals)
可选值是Swift的重要特性，表示一个值可能存在也可能不存在(nil)。

```swift
// 声明可选类型
var optionalName: String?        // 可以存储字符串或nil
var optionalIndex: Int?          // 可以存储整数或nil
```

### 可选绑定(Optional Binding)
使用`if let`或`guard let`安全地解包可选值：

```swift
// 尝试在数组中查找元素索引
if let index = tasks.firstIndex(where: { $0.id == task.id }) {
    // 仅当找到索引时执行
    tasks.remove(at: index)
}
```

这种模式比强制解包(`!`)更安全，避免了运行时崩溃。

## 3. 闭包与简写语法

### 闭包(Closures)
闭包是Swift中的匿名函数，常用于回调和高阶函数。

### 参数简写
在闭包中，可以使用`$0`、`$1`等表示第一个、第二个参数：

```swift
// 完整写法
tasks.firstIndex(where: { task in task.id == searchId })

// 使用$0简写
tasks.firstIndex(where: { $0.id == searchId })
```

`$0`表示传递给闭包的第一个参数，简化了代码。

## 4. 方法参数标签

Swift方法通常使用参数标签提高代码可读性：

```swift
// at:是参数标签，index是参数名
func remove(at index: Int)

// 调用时
array.remove(at: 2)
```

不同的标签表示不同的功能：
- `remove(at: index)` - 删除单个元素
- `remove(atOffsets: indexSet)` - 删除多个元素，通常与SwiftUI列表删除操作配合

参数标签使方法调用更接近自然语言，提高代码可读性。

## 5. 集合与索引

Swift中的集合类型(数组、字典等)索引**从0开始**：

```swift
var fruits = ["苹果", "香蕉", "橙子", "葡萄"]
// 索引:     0      1       2      3

// 访问第三个元素
let fruit = fruits[2]  // "橙子"

// 删除第四个元素
fruits.remove(at: 3)   // 删除"葡萄"
```

### IndexSet
`IndexSet`是表示多个整数索引的集合类型，常用于批量操作：

```swift
// 删除多个元素
func deleteTask(at indexSet: IndexSet) {
    tasks.remove(atOffsets: indexSet)
}
```

这在SwiftUI的列表删除操作中特别常见。

## 总结

Swift语言设计注重类型安全和代码可读性，通过特性如可选值、参数标签和闭包简写等，使代码既安全又简洁。理解这些基础概念对掌握SwiftUI应用开发至关重要，因为它们构成了声明式UI编程的基础。 