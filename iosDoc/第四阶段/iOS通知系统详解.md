# iOS通知系统详解

## 一、UNUserNotificationCenter 概述

`UNUserNotificationCenter` 是 iOS 中管理通知的核心类，属于 UserNotifications 框架。它负责处理应用程序的所有本地和远程通知相关操作。

### 主要功能

- 请求通知权限
- 管理通知设置
- 调度本地通知
- 处理远程通知
- 管理已发送和待发送的通知

### 基本使用

```swift
// 获取通知中心实例
let center = UNUserNotificationCenter.current()

// 请求通知权限
func requestAuthorization() async throws -> Bool {
  let options: UNAuthorizationOptions = [.alert, .sound, .badge]
  return try await center.requestAuthorization(options: options)
}
```

## 二、通知权限类型

### 基本权限选项

- **`.alert`** - 允许应用显示通知横幅或弹窗
- **`.sound`** - 允许通知播放声音
- **`.badge`** - 允许在应用图标上显示数字标记（小红点）

### 高级权限选项

- **`.carPlay`** - 允许在 CarPlay 环境中显示通知
- **`.criticalAlert`** - 允许发送重要警报，即使用户开启了"勿扰模式"也会显示
- **`.providesAppNotificationSettings`** - 表明应用提供自己的通知设置界面
- **`.provisional`** - 请求临时授权，通知会以非侵入方式显示
- **`.announcement`** - 允许 Siri 朗读通知内容（适用于 AirPods）
- **`.timeSensitive`** - 标记通知为时间敏感型，可以突破某些系统限制（iOS 15+）

### 权限组合示例

```swift
// 基本通知
let basicOptions: UNAuthorizationOptions = [.alert, .sound, .badge]

// 包含 CarPlay 支持
let carPlayOptions: UNAuthorizationOptions = [.alert, .sound, .badge, .carPlay]

// 包含重要警报的医疗应用
let medicalOptions: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
```

## 三、创建和调度通知

### 通知内容设置

```swift
let content = UNMutableNotificationContent()
content.title = "任务提醒"
content.body = "完成项目报告"
content.sound = .default
content.userInfo = ["taskID": "12345"] // 可以附加自定义数据
```

### 通知触发器类型

iOS 提供了三种主要的触发器类型：

#### 1. 基于日历的触发器

```swift
// 创建日期组件
let calendar = Calendar.current
let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)

// 创建触发器
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
```

#### 2. 基于时间间隔的触发器

```swift
// 5秒后触发
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
```

#### 3. 基于位置的触发器

```swift
let center = CLLocationCoordinate2D(latitude: 37.335, longitude: -122.009)
let region = CLCircularRegion(center: center, radius: 100, identifier: "Apple Park")
region.notifyOnEntry = true
let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
```

### 创建通知请求

```swift
let identifier = "reminder-123"
let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

// 添加通知请求
try await UNUserNotificationCenter.current().add(request)
```

## 四、重复通知设置

### 每天同一时间触发

```swift
var components = DateComponents()
components.hour = 9
components.minute = 30
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

### 每周特定日期触发

```swift
var components = DateComponents()
components.weekday = 2  // 1是周日，2是周一，依此类推
components.hour = 10
components.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

### 每月特定日期触发

```swift
var components = DateComponents()
components.day = 1      // 每月1号
components.hour = 12
components.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

### 每年特定日期触发

```swift
var components = DateComponents()
components.month = 1    // 1月
components.day = 1      // 1日
components.hour = 8
components.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

## 五、时间表示方式

iOS 中有多种表示时间的方式，每种都有其特定用途：

### 1. Date 对象

```swift
let now = Date()
let specificDate = Date(timeIntervalSince1970: 1672531200) // 2023年1月1日
```

### 2. TimeInterval

```swift
let tenSecondsLater = Date().timeIntervalSince1970 + 10
```

### 3. DateComponents

```swift
var components = DateComponents()
components.year = 2023
components.month = 7
components.day = 20
components.hour = 15
components.minute = 30
```

### 4. ISO8601 字符串

```swift
let dateFormatter = ISO8601DateFormatter()
let dateString = dateFormatter.string(from: Date()) // "2023-07-20T15:30:45Z"
```

### 5. 自定义格式字符串

```swift
let formatter = DateFormatter()
formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
let dateString = formatter.string(from: Date()) // "2023年07月20日 15:30:45"
```

## 六、通知管理

### 取消特定通知

```swift
let identifier = "task-12345"
UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
```

### 取消所有通知

```swift
UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
```

### 获取待处理通知

```swift
let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
```

## 七、通知代理处理

通过实现 `UNUserNotificationCenterDelegate` 协议，可以处理通知的交互事件：

```swift
extension NotificationController: UNUserNotificationCenterDelegate {
  // 当用户点击通知时调用
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // 获取通知中的自定义数据
    let userInfo = response.notification.request.content.userInfo
    if let taskID = userInfo["taskID"] as? String {
      // 处理用户点击通知的逻辑
      print("用户点击了任务ID为 \(taskID) 的通知")
    }
    completionHandler()
  }

  // 当应用在前台时收到通知
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 允许在前台显示通知
    completionHandler([.banner, .sound, .badge])
  }
}
```

## 八、最佳实践

1. **权限请求时机**：在用户需要通知功能时才请求权限，并解释为什么需要通知权限
2. **通知内容**：保持通知内容简洁明了，包含关键信息
3. **通知频率**：避免过多通知打扰用户
4. **深度链接**：点击通知后直接导航到相关内容
5. **错误处理**：妥善处理通知权限被拒绝的情况
6. **通知分组**：使用线程标识符对相关通知进行分组
7. **通知管理**：提供界面让用户管理应用内的通知设置

## 九、注意事项

1. **通知限制**：iOS对应用可以调度的通知数量有限制（通常为64个）
2. **权限状态**：用户可以随时在系统设置中更改通知权限
3. **前台通知**：iOS 10以前，应用在前台时不会显示通知，需要特殊处理
4. **通知内容大小**：通知内容大小有限制，不要附加过大的数据
5. **电池影响**：频繁的通知会增加电池消耗
6. **时区处理**：使用DateComponents时要考虑时区变化的影响 