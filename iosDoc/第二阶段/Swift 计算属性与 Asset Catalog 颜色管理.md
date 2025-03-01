# Swift 计算属性与 Asset Catalog 颜色管理

## 1. Swift 计算属性

计算属性是 Swift 中的一种特殊属性，它不直接存储值，而是提供一个 getter 和一个可选的 setter 来间接获取和设置其他属性的值。

### 1.1 基本语法

```swift
var 属性名: 类型 {
    get {
        // 计算并返回值
    }
    set(newValue) {
        // 设置值的逻辑
    }
}
```

### 1.2 只读计算属性简化语法

如果计算属性只有 getter 没有 setter（只读），可以简化为：

```swift
var 属性名: 类型 {
    // 计算并返回值
}
```

### 1.3 实际应用示例

```swift
enum TaskPriority: String {
    case low = "低"
    case medium = "中"
    case high = "高"
    
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

## 2. Xcode Asset Catalog 颜色管理

Asset Catalog 是 Xcode 提供的资源管理系统，可用于管理图片、颜色、数据等各种资源。

### 2.1 Asset Catalog 结构

- **项目名.xcodeproj**：项目文件
  - **Assets.xcassets**：主资源目录
    - **Colors.xcassets**：颜色资源子目录
      - **ColorName.colorset**：特定颜色资源
        - **Contents.json**：颜色定义文件

### 2.2 颜色资源 Contents.json

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.545",
          "green": "0.545",
          "red": "0.200"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.627",
          "green": "0.627",
          "red": "0.282"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

## 3. 在代码中使用 Asset Catalog 颜色

### 3.1 SwiftUI 中使用

```swift
Text("低优先级任务")
    .foregroundColor(Color("PriorityLow"))
    
// 结合枚举计算属性
Text("任务优先级：\(priority.rawValue)")
    .foregroundColor(Color(priority.color))
```

### 3.2 UIKit 中使用

```swift
label.textColor = UIColor(named: "PriorityLow")

// 结合枚举计算属性
button.tintColor = UIColor(named: priority.color)
```

## 4. Asset Catalog 颜色 vs 硬编码颜色

### 4.1 Asset Catalog 颜色优势

1. **暗黑模式适配**：自动切换明/暗模式颜色
2. **集中管理**：所有颜色在一处定义，易于维护
3. **设计一致性**：确保整个应用使用一致的颜色
4. **设计协作**：便于设计师直接编辑和导出
5. **语义化**：通过命名传达颜色用途
6. **国际化支持**：可根据区域提供不同颜色方案
7. **无需重编译**：某些情况下修改颜色不需重编译代码

### 4.2 硬编码颜色优势

1. **简单直接**：`Color(red: 0.75, green: 0.15, blue: 0.5)`
2. **动态生成**：可根据算法或用户输入生成颜色
3. **无外部依赖**：代码自包含，无需外部资源
4. **快速原型**：适合开发初期快速实现

### 4.3 硬编码颜色示例

```swift
// RGB 值 (0-1 范围)
Color(red: 0.75, green: 0.15, blue: 0.5)

// RGB 值 (0-255 范围)
Color(red: 192/255, green: 38/255, blue: 128/255)

// HSB (色相、饱和度、亮度)
Color(hue: 0.8, saturation: 0.7, brightness: 0.9)

// 十六进制
Color(hex: 0xFF5733)  // 需要扩展实现
```

## 5. 最佳实践

### 5.1 何时使用 Asset Catalog 颜色

- 品牌颜色和主题颜色
- 需要支持暗黑模式的界面元素
- 在多个界面重复使用的颜色
- 可能需要全局更新的颜色
- 需要团队协作的设计元素

### 5.2 何时使用硬编码颜色

- 临时或一次性使用的颜色
- 基于用户输入动态生成的颜色
- 基于数据或算法计算的颜色
- 原型开发阶段

### 5.3 混合策略

在大型应用中，通常采用混合策略：

```swift
struct TaskView: View {
    let task: Task
    
    var body: some View {
        VStack {
            Text(task.title)
                .foregroundColor(Color(task.priority.color))  // Asset Catalog
            
            ProgressView(value: task.progress)
                .tint(Color(hue: task.progress, saturation: 0.8, brightness: 0.9))  // 动态计算
        }
        .padding()
        .background(Color("CardBackground"))  // Asset Catalog
    }
}
```

## 6. 创建 Color 扩展增强功能

```swift
extension Color {
    // 从十六进制创建颜色
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
    
    // 基于品牌颜色创建变体
    static func brandColor(lightened: Double = 0) -> Color {
        let baseColor = Color("BrandPrimary")
        // 处理变体...
        return baseColor
    }
}
```

## 7. 总结

- **计算属性**是 Swift 中强大的功能，能够基于其他属性动态计算值，增强代码可读性和维护性
- **Asset Catalog** 提供了专业的颜色管理功能，特别适合支持多种显示模式和设计系统
- **命名颜色**比硬编码 RGB 值更具可读性和可维护性
- **最佳实践**是根据使用场景灵活选择颜色定义方式，通常核心UI元素颜色放入 Asset Catalog，动态生成的颜色使用代码定义

灵活运用这些技术，可以使 UI 代码更加清晰、可维护，同时提供出色的用户体验。
