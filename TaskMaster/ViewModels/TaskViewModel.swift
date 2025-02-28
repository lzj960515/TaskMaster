import Combine
import CoreData
import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
  private let viewContext: NSManagedObjectContext

  @Published var tasks: [Task] = []
  @Published var currentTask: Task?

  init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
    self.viewContext = context
  }

  // 获取任务列表
  func fetchTasks() {
    let request = Task.fetchRequest()
    request.sortDescriptors = [
      NSSortDescriptor(keyPath: \Task.dueDate, ascending: true),
      NSSortDescriptor(keyPath: \Task.createdAt, ascending: false),
    ]

    do {
      tasks = try viewContext.fetch(request)
    } catch {
      print("获取任务失败: \(error.localizedDescription)")
    }
  }

  // 创建新任务 - 不立即保存
  func createTask() -> Task {
    return Task(context: viewContext)
  }

  // 更新任务
  func updateTask(_ task: Task) {
    saveContext()
  }

  // 删除任务
  func deleteTask(_ task: Task) {
    viewContext.delete(task)
    saveContext()
  }

  func deleteTask(at indexSet: IndexSet) {
    for index in indexSet {
      let task = tasks[index]
      viewContext.delete(task)
    }
    saveContext()
  }

  // 标记任务完成状态
  func toggleTaskCompletion(_ task: Task) {
    task.isCompleted.toggle()
    saveContext()
  }

  // 清理未保存的任务 - 用于取消操作
  func discardChanges() {
    print("discardChanges")
    viewContext.rollback()
    fetchTasks()
  }

  // 保存上下文
  private func saveContext() {
    do {
      try PersistenceController.shared.save()
      fetchTasks()
    } catch {
      print("保存失败: \(error)")
    }
  }
}
