import Combine
import CoreData
import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
  private let viewContext: NSManagedObjectContext

  @Published var tasks: [Task] = []
  @Published var categories: [Category] = []
  @Published var tags: [Tag] = []
  @Published var currentTask: Task?
  @Published var searchText: String = ""
  @Published var selectedCategory: Category?
  @Published var selectedTags: Set<Tag> = []
  @Published var showCompletedTasks: Bool = false

  init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
    self.viewContext = context

    // 初始加载数据
    fetchCategories()
    fetchTags()
    fetchTasks()
  }

  // MARK: - 任务操作

  // 获取任务列表
  func fetchTasks() {
    let request = Task.fetchRequest()

    // 创建筛选条件
    var predicates: [NSPredicate] = []

    // 搜索文本筛选
    if !searchText.isEmpty {
      predicates.append(
        NSPredicate(format: "title CONTAINS[cd] %@ OR desc CONTAINS[cd] %@", searchText, searchText)
      )
    }
    print("selectedCategory: \(selectedCategory?.name)")
    print("showCompletedTasks: \(showCompletedTasks)")
    // 分类筛选
    if let category = selectedCategory {
      predicates.append(NSPredicate(format: "category == %@", category))
    }

    // 标签筛选
    if !selectedTags.isEmpty {
      let tagPredicates = selectedTags.map { tag in
        NSPredicate(format: "ANY tags == %@", tag)
      }
      predicates.append(NSCompoundPredicate(andPredicateWithSubpredicates: tagPredicates))
    }

    // 是否显示已完成任务
    if showCompletedTasks {
      predicates.append(
        NSPredicate(format: "isCompleted == %@", NSNumber(value: true)))
    }

    // 合并所有筛选条件
    if !predicates.isEmpty {
      request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    // 排序
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
    viewContext.rollback()
    fetchTasks()
  }

  // MARK: - 分类操作

  // 获取所有分类
  func fetchCategories() {
    let request: NSFetchRequest<Category> = Category.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]

    do {
      categories = try viewContext.fetch(request)
    } catch {
      print("获取分类失败: \(error.localizedDescription)")
    }
  }

  // 创建新分类
  func createCategory(name: String, colorHex: String = "#007AFF") -> Category {
    let category = Category(context: viewContext)
    category.name = name
    category.colorHex = colorHex
    saveContext()
    return category
  }

  // 删除分类
  func deleteCategory(_ category: Category) {
    // 删除分类
    viewContext.delete(category)
    saveContext()
  }

  // MARK: - 标签操作

  // 获取所有标签
  func fetchTags() {
    let request: NSFetchRequest<Tag> = Tag.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]

    do {
      tags = try viewContext.fetch(request)
    } catch {
      print("获取标签失败: \(error.localizedDescription)")
    }
  }

  // 创建新标签
  func createTag(name: String) {
    let tag = Tag(context: viewContext)
    tag.name = name
    saveContext()
  }

  // 删除标签
  func deleteTag(_ tag: Tag) {
    // 获取与该标签关联的任务
    let request = Task.fetchRequest()
    request.predicate = NSPredicate(format: "ANY tags == %@", tag)

    do {
      let tasks = try viewContext.fetch(request)

      // 从任务中移除标签
      for task in tasks {
        task.removeFromTags(tag)
      }

      // 删除标签
      viewContext.delete(tag)
      saveContext()
    } catch {
      print("删除标签失败: \(error.localizedDescription)")
    }
  }

  // MARK: - 筛选与搜索

  // 重置所有筛选条件
  func resetFilters() {
    searchText = ""
    selectedCategory = nil
    selectedTags = []
    showCompletedTasks = true
    fetchTasks()
  }

  // 根据筛选条件更新任务列表
  func applyFilters() {
    fetchTasks()
  }

  // 切换任务完成状态筛选
  func toggleCompletedTasksVisibility() {
    showCompletedTasks.toggle()
    fetchTasks()
  }

  // 按分类筛选
  func filterByCategory(_ category: Category?) {
    selectedCategory = category
    fetchTasks()
  }

  // 按标签筛选
  func toggleTagFilter(_ tag: Tag) {
    if selectedTags.contains(tag) {
      selectedTags.remove(tag)
    } else {
      selectedTags.insert(tag)
    }
    fetchTasks()
  }

  // MARK: - 核心数据操作

  // 保存上下文
  private func saveContext() {
    do {
      try PersistenceController.shared.save()
      // 更新所有数据集合
      fetchTasks()
      fetchCategories()
      fetchTags()
    } catch {
      print("保存失败: \(error)")
    }
  }
}
