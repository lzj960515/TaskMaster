import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
  @Published var tasks: [TodoTask] = []

  init(initialTasks: [TodoTask] = []) {
    self.tasks = initialTasks
  }

  // 添加新任务
  func addTask(title: String) {
    let newTask = TodoTask(title: title)
    tasks.append(newTask)
  }

  // 删除任务
  func deleteTask(at indexSet: IndexSet) {
    tasks.remove(atOffsets: indexSet)
  }

  // 删除指定任务
  func deleteTask(task: TodoTask) {
    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
      tasks.remove(at: index)
    }
  }

  // 切换任务完成状态
  func toggleTaskCompletion(task: TodoTask) {
    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
      tasks[index].isCompleted.toggle()
    }
  }
}
