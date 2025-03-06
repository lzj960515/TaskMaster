# iOS通知系统与导航详解

## 一、通知中心概述

`UNUserNotificationCenter` 是 iOS 中管理通知的核心类，负责处理应用程序的所有本地和远程通知相关操作。它提供了请求权限、调度通知、管理通知等功能。

## 二、通知权限

### 基本权限类型
- **`.alert`**：允许应用显示通知横幅或弹窗
- **`.sound`**：允许通知播放声音
- **`.badge`**：允许在应用图标上显示数字标记（小红点）

### 高级权限类型
- **`.carPlay`**：允许在 CarPlay 环境中显示通知
- **`.criticalAlert`**：允许发送重要警报，即使用户开启了"勿扰模式"也会显示
- **`.providesAppNotificationSettings`**：表明应用提供自己的通知设置界面
- **`.provisional`**：请求临时授权，通知会以非侵入方式显示
- **`.announcement`**：允许 Siri 朗读通知内容（适用于 AirPods）
- **`.timeSensitive`**：标记通知为时间敏感型，可以突破某些系统限制（iOS 15+）

### 请求通知权限
```swift
func requestAuthorization() async throws -> Bool {
  let center = UNUserNotificationCenter.current()
  let options: UNAuthorizationOptions = [.alert, .sound, .badge]
  return try await center.requestAuthorization(options: options)
}
```

## 三、创建和调度通知

### 通知内容
`UNMutableNotificationContent` 用于设置通知的内容，包括标题、正文、声音等：

```swift
let content = UNMutableNotificationContent()
content.title = "任务提醒"
content.body = task.title
content.sound = .default
content.userInfo = ["taskID": task.id.uuidString] // 附加数据
```

### 通知触发器类型

1. **时间间隔触发器**
```swift
// 10秒后触发
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
```

2. **日历触发器**
```swift
// 创建日期组件
let calendar = Calendar.current
let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
// 创建触发器
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
```

3. **位置触发器**
```swift
let center = CLLocationCoordinate2D(latitude: 37.335, longitude: -122.009)
let region = CLCircularRegion(center: center, radius: 100, identifier: "Apple Park")
region.notifyOnEntry = true
let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
```

### 创建重复通知

#### 每天同一时间触发
```swift
var components = DateComponents()
components.hour = 9
components.minute = 30
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

#### 每周特定日期触发
```swift
var components = DateComponents()
components.weekday = 2  // 1是周日，2是周一
components.hour = 10
components.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

#### 每月特定日期触发
```swift
var components = DateComponents()
components.day = 1      // 每月1号
components.hour = 12
components.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

### 创建通知请求
```swift
let identifier = "task-\(task.id.uuidString)"
let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
try await UNUserNotificationCenter.current().add(request)
```

## 四、处理通知响应

### 设置通知代理
```swift
func setupNotificationDelegate() {
  UNUserNotificationCenter.current().delegate = self
}
```

### 实现代理方法
```swift
// 当用户点击通知时调用
func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  didReceive response: UNNotificationResponse,
  withCompletionHandler completionHandler: @escaping () -> Void
) {
  // 获取通知中的任务ID
  let userInfo = response.notification.request.content.userInfo
  if let taskIDString = userInfo["taskID"] as? String,
    let taskID = UUID(uuidString: taskIDString)
  {
    // 发送通知到应用中，携带任务ID
    NotificationCenter.default.post(
      name: .didSelectTaskFromNotification, 
      object: nil,
      userInfo: ["taskID": taskID]
    )
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
```

## 五、通知与应用内导航

### 通知观察者模式

#### 使用 onAppear 设置观察者
```swift
.onAppear {
  // 设置通知观察者
  NotificationCenter.default.addObserver(
    forName: .didSelectTaskFromNotification,
    object: nil,
    queue: .main
  ) { notification in
    if let taskID = notification.userInfo?["taskID"] as? UUID {
      self.selectedTaskID = taskID
      self.showTaskDetail = true
    }
  }
}

.onDisappear {
  // 移除观察者
  NotificationCenter.default.removeObserver(
    self,
    name: .didSelectTaskFromNotification,
    object: nil
  )
}
```

#### 使用 onReceive（SwiftUI 声明式方式）
```swift
.onReceive(NotificationCenter.default.publisher(for: .didSelectTaskFromNotification)) { notification in
  if let taskID = notification.userInfo?["taskID"] as? UUID {
    self.selectedTaskID = taskID
    self.showTaskDetail = true
  }
}
```

### 导航实现方式

#### iOS 16+ 使用 NavigationStack
```swift
NavigationStack {
  VStack {
    // 内容
  }
  .navigationDestination(isPresented: $showTaskDetail) {
    if let taskID = selectedTaskID, let task = viewModel.getTask(by: taskID) {
      TaskDetailView(task: task)
    } else {
      Text("任务未找到")
    }
  }
}
```

#### iOS 15 及以下使用 NavigationView
```swift
NavigationView {
  VStack {
    // 内容
  }
  .background(
    Group {
      if let taskID = selectedTaskID, let task = viewModel.getTask(by: taskID) {
        NavigationLink(
          destination: TaskDetailView(task: task),
          isActive: $showTaskDetail,
          label: { EmptyView() }
        )
        .hidden()
      }
    }
  )
}
```

#### 兼容性处理
```swift
if #available(iOS 16.0, *) {
  // iOS 16+ 使用新 API
  NavigationStack {
    // 内容
  }
} else {
  // iOS 15 及以下使用旧 API
  NavigationView {
    // 内容
  }
}
```

## 六、时间表示方式

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

## 七、最佳实践

1. **权限请求时机**：在用户需要通知功能时请求权限，而不是应用启动时
2. **通知内容**：保持通知内容简洁明了，包含必要信息
3. **唯一标识符**：为每个通知使用唯一标识符，便于后续管理
4. **用户信息**：在通知中包含必要的上下文数据（如任务ID）
5. **通知频率**：避免过多通知打扰用户
6. **错误处理**：妥善处理通知权限被拒绝的情况
7. **导航兼容性**：考虑不同iOS版本的导航API差异

## 八、常见问题解决

1. **通知不显示**：检查权限状态、触发时间是否正确
2. **重复通知**：确保使用正确的日期组件和repeats参数
3. **导航问题**：根据iOS版本选择合适的导航API
4. **内存泄漏**：确保在适当时机移除通知观察者

通过合理使用iOS通知系统和导航功能，可以为用户提供及时的任务提醒，并在用户点击通知后引导他们直接进入相关任务详情页面，提升用户体验。
