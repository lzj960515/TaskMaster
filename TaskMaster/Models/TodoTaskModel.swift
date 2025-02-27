import Foundation

struct TodoTask: Identifiable {
  let id: UUID
  var title: String
  var isCompleted: Bool
  let createdAt: Date

  init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date()) {
    self.id = id
    self.title = title
    self.isCompleted = isCompleted
    self.createdAt = createdAt
  }
}

// 示例数据，用于预览和测试
extension TodoTask {
  static let sampleTasks = [
    TodoTask(title: "完成SwiftUI学习", isCompleted: true),
    TodoTask(title: "实现任务列表显示", isCompleted: false),
    TodoTask(title: "添加新任务功能", isCompleted: false),
    TodoTask(title: "实现删除任务", isCompleted: false),
    TodoTask(title: "完成标记任务状态功能", isCompleted: false),
  ]
}
