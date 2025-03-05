import Foundation
import UserNotifications

class NotificationController {
  static let shared = NotificationController()

  private init() {}

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
