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

  // 检查通知权限状态
  func checkAuthorizationStatus() async -> UNAuthorizationStatus {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    return settings.authorizationStatus
  }

  // 创建任务提醒
  func scheduleTaskReminder(for task: Task) async throws {
    guard let dueDate = task.dueDate else { return }

    let content = UNMutableNotificationContent()
    content.title = "任务提醒"
    content.body = task.title
    content.sound = .default
    // 添加任务ID到用户信息字典
    content.userInfo = ["taskID": task.id.uuidString]

    // 创建日期组件
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)

    // 创建触发器
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    // 创建请求
    let identifier = "task-\(task.id.uuidString)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    // 添加通知请求
    try await UNUserNotificationCenter.current().add(request)
  }

  // 创建重复任务提醒
  func scheduleRepeatingTaskReminder(for task: Task, components: DateComponents) async throws {
    let content = UNMutableNotificationContent()
    content.title = "任务提醒"
    content.body = task.title
    content.sound = .default
    content.userInfo = ["taskID": task.id.uuidString]

    // 创建重复触发器
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    // 创建请求
    let identifier = "task-repeating-\(task.id.uuidString)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    // 添加通知请求
    try await UNUserNotificationCenter.current().add(request)
  }

  // 取消任务提醒
  func cancelTaskReminder(for task: Task) {
    let identifier = "task-\(task.id.uuidString)"
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      identifier
    ])
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

  // 取消所有通知
  func cancelAllNotifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }
}

// MARK: - UNUserNotificationCenterDelegate
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
}
