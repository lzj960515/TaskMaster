# SwiftUI视图基础与结构化布局

## 基本视图结构

SwiftUI采用声明式UI编程范式，通过组合简单视图构建复杂界面。每个视图都是遵循`View`协议的结构体，必须实现`body`属性。

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

## 修饰符链式调用

### 修饰符工作原理

SwiftUI使用链式调用语法应用修饰符（modifiers）。每个修饰符都会返回一个新的视图，而不是修改原视图。

```swift
Text("Hello")
    .padding()         // 返回带内边距的新视图
    .background(.blue) // 返回带背景的新视图
    .foregroundColor(.white) // 返回带文本颜色的新视图
```

### 修饰符顺序很重要

因为每个修饰符都返回一个新视图，所以顺序会影响最终效果：

```swift
// 背景色会填充内边距区域
Text("Hello")
    .padding()
    .background(.blue)

// 内边距区域不会带有背景色
Text("Hello")
    .background(.blue)
    .padding()
```

### padding修饰符详解

`.padding()`修饰符用于在视图周围添加空白间距，提高可读性和视觉美感。

#### 默认值和基本用法

不带参数的`.padding()`会在所有四个边应用相同的间距：

```swift
Text("Hello")
    .padding() // 所有四边应用默认8点(points)间距
```

- 默认值是上下左右各**8点(points)**
- 相当于`EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)`

#### 自定义间距大小

可以指定自定义的间距大小：

```swift
Text("Hello")
    .padding(20) // 所有四边应用20点间距
```

#### 方向性padding

可以精确控制哪些边应用padding以及各自的大小：

```swift
// 单边padding
Text("Hello").padding(.top, 10)      // 只在顶部添加10点间距
Text("Hello").padding(.bottom, 20)   // 只在底部添加20点间距
Text("Hello").padding(.leading, 15)  // 只在前缘(通常是左侧)添加15点间距
Text("Hello").padding(.trailing, 15) // 只在后缘(通常是右侧)添加15点间距

// 组合方向padding
Text("Hello").padding(.horizontal, 20) // 水平方向(左右)各20点间距
Text("Hello").padding(.vertical, 10)   // 垂直方向(上下)各10点间距

// 多边组合
Text("Hello").padding([.top, .leading], 15) // 顶部和前缘各15点间距
```

#### 自定义EdgeInsets

当需要为每个边设置不同的间距值时，可以使用EdgeInsets：

```swift
Text("Hello")
    .padding(EdgeInsets(top: 10, leading: 20, bottom: 15, trailing: 5))
```

#### 实际应用示例

```swift
// 创建带有不同padding的按钮
Button(action: { /* 操作 */ }) {
    Text("提交")
        .padding(.horizontal, 20) // 水平方向充足的间距
        .padding(.vertical, 10)   // 垂直方向适中的间距
        .background(.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
}

// 精细控制表单项的间距
VStack(alignment: .leading) {
    Text("用户名").font(.caption).foregroundColor(.gray)
    TextField("请输入用户名", text: $username)
        .padding(10)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
        .padding(.bottom, 15) // 只在底部添加额外间距分隔下一个表单项
}
```

### 修饰符应用范围

修饰符应用于它前面的整个视图结构：

```swift
// 整个HStack都有背景色
HStack {
    Image(systemName: "star")
    Text("Starred")
}
.background(.yellow)

// 只有Text有背景色
HStack {
    Image(systemName: "star")
    Text("Starred")
        .background(.yellow)
}
```

## 常用容器视图

### NavigationView

创建带有导航栏的界面布局，支持标题、工具栏和页面导航。

```swift
NavigationView {
    List {
        // 内容...
    }
    .navigationTitle("任务列表")
    .toolbar {
        EditButton()
    }
}
```

### HStack与VStack

`HStack`：水平排列子视图
`VStack`：垂直排列子视图

```swift
VStack(alignment: .leading, spacing: 10) {
    Text("标题")
        .font(.headline)
    HStack {
        Image(systemName: "calendar")
        Text("2023年5月10日")
        Spacer() // 占据剩余水平空间
    }
}
```

### List

创建可滚动列表，支持多种交互操作。

```swift
List {
    Section(header: Text("待办事项")) {
        ForEach(tasks) { task in
            TaskRow(task: task)
        }
        .onDelete { indexSet in
            deleteTasks(at: indexSet)
        }
    }
}
```

### Spacer

`Spacer`是一个特殊视图，它会扩展以占据容器中的可用空间，常用于布局控制。

```swift
HStack {
    Text("左对齐")
    Spacer() // 推动后面的内容到右边
    Text("右对齐")
}
```

## ForEach与集合视图

### ForEach工作原理

`ForEach`是一个视图生成器，它遍历集合并为每个元素创建视图。

```swift
ForEach(viewModel.tasks) { task in
    TaskRowView(task: task)
}
```

### ForEach语法结构

```swift
// 基本语法：闭包形式
ForEach(collection) { element in
    // 使用element创建视图
}

// 显式指定id
ForEach(collection, id: \.someProperty) { element in
    // 使用element创建视图
}
```

### 元素标识机制

ForEach需要能够唯一标识每个元素，有两种方式：

1. **隐式标识**：元素类型遵循`Identifiable`协议
   ```swift
   struct Task: Identifiable {
       let id: UUID // 自动用作标识符
       var title: String
       // ...
   }
   ```

2. **显式标识**：通过`id`参数提供KeyPath
   ```swift
   ForEach(tasks, id: \.id) { task in
       // ...
   }
   ```

### 列表操作修饰符

`ForEach`与列表结合使用时，支持特殊的交互修饰符：

```swift
ForEach(tasks) { task in
    TaskRow(task: task)
}
.onDelete { indexSet in
    // 处理删除
}
.onMove { source, destination in
    // 处理重排
}
```

注意：这些修饰符必须应用于`ForEach`而非`List`本身。

## 属性包装器

### @State

`@State`用于在视图内部管理可变状态。当状态变化时，SwiftUI会自动重新渲染视图。

```swift
struct ContentView: View {
    @State private var isActive = false
    
    var body: some View {
        Button(isActive ? "活跃" : "未活跃") {
            isActive.toggle()
        }
        .foregroundColor(isActive ? .green : .red)
    }
}
```

特点：
- 用于视图内部的简单状态
- 通常声明为`private`
- 适用于基本数据类型（String、Int、Bool等）
- 当值变化时自动触发视图更新

### @Binding

`@Binding`创建对其他视图状态的引用，实现双向数据流。

```swift
struct ToggleView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("状态", isOn: $isOn)
    }
}

struct ParentView: View {
    @State private var isActive = false
    
    var body: some View {
        ToggleView(isOn: $isActive)
    }
}
```

注意`$`语法用于创建到`@State`变量的绑定。

### @ObservedObject

用于引用外部可观察对象，当对象的`@Published`属性变化时更新视图。

```swift
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
}

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        List(viewModel.tasks) { task in
            Text(task.title)
        }
    }
}
```

## 闭包与事件处理

SwiftUI广泛使用闭包来处理事件和回调：

```swift
Button(action: {
    // 点击处理代码
    isAddingTask = true
}) {
    // 按钮外观
    Text("添加")
}

// 简化语法
Button("添加") {
    isAddingTask = true
}
```

闭包语法的基本结构：

```swift
{ (参数列表) -> 返回类型 in
    // 函数体
}

// 简化形式
{ 参数 in 表达式 }
```

## 结论

SwiftUI的声明式语法和组合模式使构建复杂UI变得更加直观。通过理解视图层次结构、修饰符链、容器视图和状态管理，开发者可以创建既美观又高效的用户界面，同时保持代码的可读性和可维护性。

这种声明式方法与传统命令式UI开发有很大不同，但一旦掌握核心概念，它能够显著提高开发效率和代码质量。