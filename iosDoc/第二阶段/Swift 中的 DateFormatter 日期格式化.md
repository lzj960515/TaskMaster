# Swift 中的 DateFormatter 日期格式化

## 1. DateFormatter 基础

DateFormatter 是 Foundation 框架提供的一个强大工具类，用于在日期对象(Date)和字符串之间进行转换。它支持多种预设格式和完全自定义的格式化选项，同时提供了完善的本地化支持。

### 1.1 基本声明与初始化

```swift
private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()
```

这种使用闭包的懒加载方式有几个优点：
- 只创建一次实例，避免重复初始化的性能开销
- 在声明的同时完成配置
- 保持代码的简洁和可读性

## 2. 日期和时间样式

DateFormatter 提供了五种预定义的日期样式(`dateStyle`)和时间样式(`timeStyle`)，从无到全面依次为：

### 2.1 DateStyle 样式（英文环境）

| 样式 | 代码 | 格式示例 |
|------|------|----------|
| 无 | `.none` | 不显示日期 |
| 短 | `.short` | "12/31/22" |
| 中 | `.medium` | "Dec 31, 2022" |
| 长 | `.long` | "December 31, 2022" |
| 完整 | `.full` | "Saturday, December 31, 2022" |

### 2.2 TimeStyle 样式（英文环境）

| 样式 | 代码 | 格式示例 |
|------|------|----------|
| 无 | `.none` | 不显示时间 |
| 短 | `.short` | "3:30 PM" |
| 中 | `.medium` | "3:30:45 PM" |
| 长 | `.long` | "3:30:45 PM GMT+8" |
| 完整 | `.full` | "3:30:45 PM GMT+08:00" |

### 2.3 组合使用

当同时设置 dateStyle 和 timeStyle 时，它们会组合显示：

```swift
// 设置中等日期格式和短时间格式
formatter.dateStyle = .medium
formatter.timeStyle = .short
// 结果示例: "Dec 31, 2022, 3:30 PM"
```

## 3. 区域设置与本地化

DateFormatter 可以根据不同的区域显示适合当地习惯的日期和时间格式。

### 3.1 设置特定区域

```swift
// 设置为中文(中国大陆)
formatter.locale = Locale(identifier: "zh_CN")

// 使用当前设备设置的区域
formatter.locale = Locale.current
```

### 3.2 常用区域标识符

| 语言/地区 | 标识符 | 说明 |
|-----------|--------|------|
| 中文(中国大陆) | `"zh_CN"` | 使用简体中文，符合大陆习惯 |
| 中文(台湾) | `"zh_TW"` | 使用繁体中文，符合台湾习惯 |
| 中文(香港) | `"zh_HK"` | 使用繁体中文，符合香港习惯 |
| 日文 | `"ja_JP"` | 日本日期格式 |
| 韩文 | `"ko_KR"` | 韩国日期格式 |
| 英文(美国) | `"en_US"` | 美式英语 |
| 英文(英国) | `"en_GB"` | 英式英语 |

### 3.3 中文区域下的样式示例

设置 `locale` 为 `"zh_CN"` 后的日期时间显示：

| 样式 | 日期示例 | 时间示例 |
|------|----------|----------|
| `.short` | "2022/12/31" | "下午3:30" |
| `.medium` | "2022年12月31日" | "下午3:30:45" |
| `.long` | "2022年12月31日" | "GMT+8 下午3:30:45" |
| `.full` | "2022年12月31日 星期六" | "GMT+08:00 下午3:30:45" |

## 4. 自定义日期格式

除了预定义的样式外，DateFormatter 还支持完全自定义的格式。

### 4.1 设置自定义格式

```swift
let formatter = DateFormatter()
formatter.locale = Locale(identifier: "zh_CN")
formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
```

### 4.2 常用格式符号

| 符号 | 描述 | 示例 |
|------|------|------|
| y | 年 | "2022" |
| M | 月 | "12" |
| MMM | 月(缩写) | "十二月" |
| MMMM | 月(全称) | "十二月" |
| d | 日 | "31" |
| E | 星期(缩写) | "六" |
| EEEE | 星期(全称) | "星期六" |
| H | 24小时制 | "15" |
| h | 12小时制 | "3" |
| m | 分钟 | "30" |
| s | 秒 | "45" |
| a | 上午/下午 | "下午" |
| z | 时区 | "GMT+8" |

### 4.3 特殊格式需求示例

```swift
// 中文农历日期
formatter.dateFormat = "yyyy年 M月d日 EEEE"
// "2022年 12月31日 星期六"

// 仅显示时间
formatter.dateFormat = "a h:mm"
// "下午 3:30"

// ISO 8601 标准格式
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
// "2022-12-31T15:30:45+0800"
```

## 5. 使用 DateFormatter 的实际场景

### 5.1 格式化日期显示

```swift
let now = Date()
let formatted = dateFormatter.string(from: now)
// 在UI中显示格式化后的日期
someLabel.text = formatted
```

### 5.2 解析日期字符串

```swift
let dateString = "2022年12月31日 下午3:30"
if let date = dateFormatter.date(from: dateString) {
    // 成功解析，可以使用date对象
    let timeInterval = date.timeIntervalSinceNow
}
```

### 5.3 在列表中显示任务创建时间

```swift
struct TaskRow: View {
    let task: Task
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(task.title)
                .font(.headline)
            if let createdAt = task.createdAt {
                Text("创建于: \(dateFormatter.string(from: createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## 6. 性能考虑与最佳实践

### 6.1 性能优化

DateFormatter 的创建和配置是相对昂贵的操作，应避免频繁创建：

```swift
// 推荐：在类中声明一次
private let dateFormatter = DateFormatter()

// 不推荐：在循环或频繁调用的方法中创建
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter() // 每次调用都创建新实例，性能差
    return formatter.string(from: date)
}
```

### 6.2 格式化大量日期

如果需要格式化大量日期，可以考虑使用更轻量的 ISO8601DateFormatter 或 DateComponentsFormatter。

### 6.3 区域感知

确保考虑不同区域用户的需求：

```swift
// 为不同地区的用户提供适当的日期格式
if let languageCode = Locale.current.languageCode {
    switch languageCode {
    case "zh":
        dateFormatter.dateFormat = "yyyy年MM月dd日"
    case "ja":
        dateFormatter.dateFormat = "yyyy年MM月dd日"
    default:
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
}
```

### 6.4 可访问性考虑

考虑视障用户的需求，提供更友好的日期描述：

```swift
// 更具描述性的日期表示，适合VoiceOver
func accessibleDateDescription(_ date: Date) -> String {
    let calendar = Calendar.current
    
    if calendar.isDateInToday(date) {
        return "今天 \(timeFormatter.string(from: date))"
    } else if calendar.isDateInYesterday(date) {
        return "昨天 \(timeFormatter.string(from: date))"
    } else {
        return dateFormatter.string(from: date)
    }
}
```

## 7. 总结

DateFormatter 是 Swift 处理日期格式化的强大工具：

- 支持多种预设样式和完全自定义格式
- 提供全面的本地化支持，可适应不同区域的日期习惯
- 具有将日期与字符串互相转换的能力
- 需注意性能问题，避免频繁创建新实例

合理使用 DateFormatter 可以确保应用中的日期显示既符合用户习惯，又具有良好的国际化支持。