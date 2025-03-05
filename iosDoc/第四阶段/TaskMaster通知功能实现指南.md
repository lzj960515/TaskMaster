# TaskMaster通知功能实现指南

## 一、功能概述

在TaskMaster应用中，通知系统是第四阶段的核心功能，它允许用户为任务设置提醒，确保重要任务不会被遗忘。本指南将详细介绍如何在应用中实现完整的通知功能。

## 二、功能需求

1. 用户可以为任务设置截止日期提醒
2. 支持一次性提醒和重复提醒（每天/每周/每月）
3. 用户可以编辑和取消已设置的提醒
4. 点击通知可以直接跳转到相应任务详情页面
5. 提供通知管理界面，查看所有待处理的提醒

## 三、技术架构

### 核心组件

1. **NotificationController**: 负责通知的创建、更新和取消
2. **ReminderSettingsView**: 提醒设置界面
3. **NotificationListView**: 通知管理界面
4. **Task模型扩展**: 添加提醒相关属性

### 数据模型设计

需要在Task模型中添加以下属性：

```swift
struct Task: Identifiable {
    var id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var reminderEnabled: Bool  // 是否启用提醒
    var reminderType: ReminderType  // 提醒类型（一次性/重复）
    var reminderComponents: DateComponents?  // 用于重复提醒
    // ... 其他属性
}

enum ReminderType {
    case once  // 一次性
    case daily  // 每天
    case weekly  // 每周
    case monthly  // 每月
}
```

## 四、实现步骤

### 1. 创建NotificationController

首先创建一个单例类来管理所有通知操作：

```swift
import Foundation
import UserNotifications

class NotificationController: NSObject {
    static let shared = NotificationController()
    
    private override init() {
        super.init()
        setupNotificationDelegate()
    }
    
    // 设置通知代理
    func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // 请求通知权限
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await center.requestAuthorization(options: options)
    }
    
    // ... 其他方法
}
```

### 2. 实现通知创建功能

添加创建一次性和重复通知的方法：

```swift
// 创建任务提醒
func scheduleTaskReminder(for task: Task) async throws {
    guard let dueDate = task.dueDate else { return }
    
    let content = UNMutableNotificationContent()
    content.title = "任务提醒"
    content.body = task.title
    content.sound = .default
    content.userInfo = ["taskID": task.id.uuidString]
    
    // 根据提醒类型创建不同的触发器
    if task.reminderEnabled {
        switch task.reminderType {
        case .once:
            // 创建一次性提醒
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            scheduleNotification(for: task, with: content, trigger: trigger)
            
        case .daily, .weekly, .monthly:
            // 创建重复提醒
            if let reminderComponents = task.reminderComponents {
                let trigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: true)
                scheduleNotification(for: task, with: content, trigger: trigger)
            }
        }
    }
}

// 通用的通知调度方法
private func scheduleNotification(for task: Task, with content: UNMutableNotificationContent, trigger: UNNotificationTrigger) async throws {
    let identifier = "task-\(task.id.uuidString)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    try await UNUserNotificationCenter.current().add(request)
}
```

### 3. 实现通知管理功能

添加取消和更新通知的方法：

```swift
// 取消任务提醒
func cancelTaskReminder(for task: Task) {
    let identifier = "task-\(task.id.uuidString)"
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
}

// 更新任务提醒
func updateTaskReminder(for task: Task) async throws {
    // 先取消原有提醒
    cancelTaskReminder(for: task)
    // 重新创建提醒
    try await scheduleTaskReminder(for: task)
}

// 获取所有待处理的通知
func getPendingNotifications() async -> [UNNotificationRequest] {
    return await UNUserNotificationCenter.current().pendingNotificationRequests()
}
```

### 4. 实现通知代理

处理用户与通知的交互：

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
}

// 定义通知名称
extension Notification.Name {
    static let didSelectTaskFromNotification = Notification.Name("didSelectTaskFromNotification")
}
```

### 5. 创建提醒设置界面

```swift
struct ReminderSettingsView: View {
    @ObservedObject var task: Task
    @State private var isReminderEnabled: Bool
    @State private var selectedReminderType: ReminderType
    @State private var reminderDate: Date
    @State private var showingDatePicker = false
    
    init(task: Task) {
        self.task = task
        _isReminderEnabled = State(initialValue: task.reminderEnabled)
        _selectedReminderType = State(initialValue: task.reminderType)
        _reminderDate = State(initialValue: task.dueDate ?? Date())
    }
    
    var body: some View {
        Form {
            Section(header: Text("提醒设置")) {
                Toggle("启用提醒", isOn: $isReminderEnabled)
                
                if isReminderEnabled {
                    Picker("提醒类型", selection: $selectedReminderType) {
                        Text("一次性").tag(ReminderType.once)
                        Text("每天").tag(ReminderType.daily)
                        Text("每周").tag(ReminderType.weekly)
                        Text("每月").tag(ReminderType.monthly)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if selectedReminderType == .once {
                        DatePicker("提醒时间", selection: $reminderDate)
                    } else {
                        // 根据不同的重复类型显示不同的时间选择器
                        // ...
                    }
                }
            }
            
            Section {
                Button("保存提醒设置") {
                    saveReminderSettings()
                }
            }
        }
        .navigationTitle("提醒设置")
    }
    
    private func saveReminderSettings() {
        task.reminderEnabled = isReminderEnabled
        task.reminderType = selectedReminderType
        
        if isReminderEnabled {
            if selectedReminderType == .once {
                task.dueDate = reminderDate
                // 创建一次性提醒
            } else {
                // 创建重复提醒的DateComponents
                var components = DateComponents()
                
                switch selectedReminderType {
                case .daily:
                    // 只设置小时和分钟
                    components.hour = Calendar.current.component(.hour, from: reminderDate)
                    components.minute = Calendar.current.component(.minute, from: reminderDate)
                case .weekly:
                    // 设置星期几、小时和分钟
                    components.weekday = Calendar.current.component(.weekday, from: reminderDate)
                    components.hour = Calendar.current.component(.hour, from: reminderDate)
                    components.minute = Calendar.current.component(.minute, from: reminderDate)
                case .monthly:
                    // 设置日、小时和分钟
                    components.day = Calendar.current.component(.day, from: reminderDate)
                    components.hour = Calendar.current.component(.hour, from: reminderDate)
                    components.minute = Calendar.current.component(.minute, from: reminderDate)
                default:
                    break
                }
                
                task.reminderComponents = components
            }
            
            // 调用通知控制器创建提醒
            Task {
                do {
                    try await NotificationController.shared.updateTaskReminder(for: task)
                } catch {
                    print("创建提醒失败: \(error)")
                }
            }
        } else {
            // 取消提醒
            NotificationController.shared.cancelTaskReminder(for: task)
        }
    }
}
```

### 6. 创建通知列表界面

```swift
struct NotificationListView: View {
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("加载中...")
            } else if pendingNotifications.isEmpty {
                Text("没有待处理的通知")
                    .foregroundColor(.secondary)
            } else {
                ForEach(pendingNotifications, id: \.identifier) { request in
                    NotificationRow(request: request)
                }
                .onDelete(perform: deleteNotifications)
            }
        }
        .navigationTitle("通知管理")
        .toolbar {
            Button("刷新") {
                loadNotifications()
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        isLoading = true
        Task {
            pendingNotifications = await NotificationController.shared.getPendingNotifications()
            isLoading = false
        }
    }
    
    private func deleteNotifications(at offsets: IndexSet) {
        let identifiersToRemove = offsets.map { pendingNotifications[$0].identifier }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        // 更新列表
        offsets.forEach { pendingNotifications.remove(at: $0) }
    }
}

struct NotificationRow: View {
    let request: UNNotificationRequest
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(request.content.title)
                .font(.headline)
            Text(request.content.body)
                .font(.subheadline)
            
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                Text("下次触发时间: \(formattedDate(nextTriggerDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
```

### 7. 在应用启动时请求通知权限

在`TaskMasterApp.swift`中添加：

```swift
@main
struct TaskMasterApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 请求通知权限
                    Task {
                        do {
                            let granted = try await NotificationController.shared.requestAuthorization()
                            print("通知权限: \(granted ? "已授权" : "已拒绝")")
                        } catch {
                            print("请求通知权限失败: \(error)")
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // 应用进入前台时，更新角标
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}
```

### 8. 处理通知点击事件

在主视图中添加通知观察者：

```swift
struct ContentView: View {
    @State private var selectedTaskID: UUID?
    @State private var showingTaskDetail = false
    
    var body: some View {
        // 主视图内容
        // ...
        .onReceive(NotificationCenter.default.publisher(for: .didSelectTaskFromNotification)) { notification in
            if let taskID = notification.userInfo?["taskID"] as? UUID {
                selectedTaskID = taskID
                showingTaskDetail = true
            }
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let taskID = selectedTaskID {
                TaskDetailView(taskID: taskID)
            }
        }
    }
}
```

## 五、测试策略

1. **权限测试**：验证通知权限请求和处理
2. **创建测试**：测试不同类型提醒的创建
3. **触发测试**：验证通知在正确时间触发
4. **交互测试**：测试点击通知的跳转功能
5. **管理测试**：验证通知的取消和更新功能

## 六、注意事项

1. **权限处理**：优雅处理用户拒绝通知权限的情况
2. **时区考虑**：确保通知在用户切换时区时仍然正确触发
3. **通知限制**：iOS限制每个应用最多64个待处理通知
4. **电池优化**：避免过于频繁的通知以节省电池
5. **用户体验**：提供清晰的通知管理界面，让用户掌控通知

## 七、进阶功能

1. **通知分组**：使用线程标识符对相关通知进行分组
2. **通知附件**：添加图片或其他媒体到通知中
3. **通知操作**：添加快速操作按钮（如"完成任务"）
4. **通知摘要**：自定义通知中心的摘要文本
5. **时间敏感通知**：对重要任务使用时间敏感通知

## 八、实现进度追踪

- [ ] 创建NotificationController
- [ ] 实现通知权限请求
- [ ] 实现一次性提醒创建
- [ ] 实现重复提醒创建
- [ ] 实现通知管理功能
- [ ] 创建提醒设置界面
- [ ] 创建通知列表界面
- [ ] 实现通知点击处理
- [ ] 完成测试和优化 