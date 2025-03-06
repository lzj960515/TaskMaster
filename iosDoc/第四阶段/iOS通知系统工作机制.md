# iOS通知系统工作机制

## 通知系统概述

iOS的通知系统包含两个主要部分：
1. **系统本地通知** (UNUserNotification)：向用户显示的通知，出现在通知中心、锁屏或横幅
2. **应用内通知** (NotificationCenter)：应用内部组件间通信的机制

## 通知流程

### 完整工作流程

1. **设置通知代理和监听器**（应用启动时）
   - 设置系统通知代理
   - 设置应用内通知监听器

2. **发送本地通知**（当需要提醒用户时）
   - 创建通知内容，包含必要信息（如任务ID）
   - 设置触发条件（时间、位置等）
   - 添加到通知中心

3. **用户接收并交互**
   - 系统在指定条件下向用户展示通知
   - 用户点击通知

4. **系统回调应用**
   - 系统调用应用中的通知代理方法
   - 代理方法从通知中提取数据
   - 代理方法发布应用内通知

5. **应用内处理**
   - 应用内监听器接收到通知
   - 执行相应操作（如跳转到任务详情页）

### 代码实现

#### 1. 设置通知代理和监听器

在iOS中，有两种主要方式可以监听应用内通知：通过selector或闭包。

##### 方式一：使用selector（传统方式）

```swift
// 在AppDelegate或应用启动时设置
func setupNotifications() {
    // 设置系统通知代理
    UNUserNotificationCenter.current().delegate = notificationController
    
    // 设置应用内通知监听（selector方式）
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleTaskSelection),
        name: .didSelectTaskFromNotification,
        object: nil
    )
}

// 处理应用内通知的方法
@objc func handleTaskSelection(notification: Notification) {
    if let taskID = notification.userInfo?["taskID"] as? UUID {
        // 跳转到对应任务详情页
        showTaskDetail(taskID: taskID)
    }
}
```

##### 方式二：使用闭包（现代Swift方式）

```swift
// 在SwiftUI视图或ViewController中设置
func setupNotificationObserver() {
    // 设置通知观察者（闭包方式）
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
```

##### 两种方式的比较

1. **闭包方式**：
   - 更现代的Swift风格
   - 直接在注册时定义处理逻辑
   - 可以指定通知在哪个队列上处理（如`.main`）
   - 返回一个观察者对象，需要保存以便后续移除
   - 代码更紧凑，逻辑更连贯

2. **Selector方式**：
   - 传统的Objective-C风格
   - 处理逻辑定义在一个单独的方法中
   - 需要使用`@objc`标记方法
   - 自动绑定到`self`，移除时需要使用`removeObserver`
   - 适合有多处重用同一处理逻辑的情况

在现代Swift开发中，特别是SwiftUI项目，闭包方式更为常见和推荐。

#### 2. 发送本地通知

```swift
func scheduleTaskReminder(for task: Task) {
    // 创建通知内容
    let content = UNMutableNotificationContent()
    content.title = "任务提醒"
    content.body = "你的任务「\(task.title)」即将到期"
    content.sound = .default
    content.userInfo = ["taskID": task.id.uuidString]
    
    // 创建触发器（例如，在截止日期前10分钟）
    let triggerDate = task.dueDate.addingTimeInterval(-600)
    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: triggerDate
    )
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: components,
        repeats: false
    )
    
    // 创建通知请求
    let request = UNNotificationRequest(
        identifier: "task-\(task.id.uuidString)",
        content: content,
        trigger: trigger
    )
    
    // 添加到通知中心
    UNUserNotificationCenter.current().add(request)
}
```

#### 3. 通知代理方法实现

```swift
extension NotificationController: UNUserNotificationCenterDelegate {
    // 当用户点击通知时调用
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 获取通知中的任务ID
        let userInfo = response.notification.request.content.userInfo
        if let taskIDString = userInfo["taskID"] as? String,
           let taskID = UUID(uuidString: taskIDString) {
            // 发送应用内通知，携带任务ID
            NotificationCenter.default.post(
                name: .didSelectTaskFromNotification, 
                object: nil,
                userInfo: ["taskID": taskID]
            )
        }

        completionHandler()
    }
    
    // 当应用在前台时收到通知的处理
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

## 自定义通知名称

为了便于管理应用内通知，可以创建扩展定义自定义通知名称：

```swift
extension Notification.Name {
    static let didSelectTaskFromNotification = Notification.Name("didSelectTaskFromNotification")
    // 可以添加更多自定义通知名称
}
```

## 通知权限请求

在使用通知前，需要请求用户授权：

```swift
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound, .badge]
    ) { granted, error in
        if granted {
            print("通知权限已获取")
        } else {
            print("通知权限被拒绝")
        }
    }
}
```

## 通知管理

为了良好的用户体验，应用应该提供通知管理功能：

1. 允许用户开启/关闭特定类型的通知
2. 提供自定义通知时间的选项
3. 实现通知的增删改查功能
4. 在任务完成或删除时，移除相关的待发送通知

```swift
// 移除特定任务的通知
func removeTaskNotifications(taskID: UUID) {
    let identifier = "task-\(taskID.uuidString)"
    UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: [identifier]
    )
}
```

## 最佳实践

1. **保持通知简洁**：通知内容应简明扼要，包含必要信息
2. **合理使用通知**：避免过多通知打扰用户
3. **提供深度链接**：确保用户点击通知后能直接进入相关内容
4. **处理通知权限**：优雅地处理用户拒绝通知权限的情况
5. **测试各种场景**：测试应用在前台、后台和关闭状态下接收通知的行为

## 总结

iOS通知系统提供了强大的用户提醒和应用内通信机制。通过正确实现通知流程，可以显著提升用户体验，确保用户不会错过重要的任务截止日期，同时能够方便地从通知直接跳转到相关任务。