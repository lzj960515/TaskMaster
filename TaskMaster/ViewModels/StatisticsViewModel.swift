import CoreData
import Foundation
import SwiftUI

class StatisticsViewModel: ObservableObject {
  private let viewContext: NSManagedObjectContext
  private let taskViewModel: TaskViewModel

  // 统计数据
  @Published var completionRate: Double = 0.0
  @Published var totalTaskCount: Int = 0
  @Published var completedTaskCount: Int = 0
  @Published var categoryTaskCounts: [String: Int] = [:]
  @Published var priorityTaskCounts: [String: Int] = [:]
  @Published var dailyCompletedTasks: [Date: Int] = [:]
  @Published var dailyCreatedTasks: [Date: Int] = [:]

  // 导出状态
  @Published var isExporting = false
  @Published var exportProgress: Float = 0.0
  @Published var exportError: String? = nil

  init(
    context: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
    taskViewModel: TaskViewModel
  ) {
    self.viewContext = context
    self.taskViewModel = taskViewModel
  }

  // MARK: - 数据统计方法

  /// 计算任务完成率
  func calculateCompletionRate() {
    let request = Task.fetchRequest()

    do {
      let allTasks = try viewContext.fetch(request)
      totalTaskCount = allTasks.count
      completedTaskCount = allTasks.filter { $0.isCompleted }.count

      completionRate =
        totalTaskCount > 0 ? Double(completedTaskCount) / Double(totalTaskCount) : 0.0
    } catch {
      print("计算完成率失败: \(error.localizedDescription)")
      completionRate = 0.0
      totalTaskCount = 0
      completedTaskCount = 0
    }
  }

  /// 计算每个分类的任务数量
  func calculateCategoryStatistics() {
    let categories = taskViewModel.categories
    var result: [String: Int] = [:]

    for category in categories {
      let request = Task.fetchRequest()
      request.predicate = NSPredicate(format: "category == %@", category)

      do {
        let count = try viewContext.count(for: request)
        result[category.name] = count
      } catch {
        print("计算分类统计失败: \(error.localizedDescription)")
      }
    }

    // 处理没有分类的任务
    let uncategorizedRequest = Task.fetchRequest()
    uncategorizedRequest.predicate = NSPredicate(format: "category == nil")

    do {
      let count = try viewContext.count(for: uncategorizedRequest)
      if count > 0 {
        result["未分类"] = count
      }
    } catch {
      print("计算未分类任务失败: \(error.localizedDescription)")
    }

    categoryTaskCounts = result
  }

  /// 计算每个优先级的任务数量
  func calculatePriorityStatistics() {
    var result: [String: Int] = [:]

    for priority in TaskPriority.allCases {
      let request = Task.fetchRequest()
      request.predicate = NSPredicate(format: "priorityRaw == %@", priority.rawValue)

      do {
        let count = try viewContext.count(for: request)
        result[priority.rawValue] = count
      } catch {
        print("计算优先级统计失败: \(error.localizedDescription)")
      }
    }

    priorityTaskCounts = result
  }

  /// 计算过去一周每天完成的任务数量
  func calculateDailyCompletionTrend(daysBack: Int = 7) {
    var result: [Date: Int] = [:]
    let calendar = Calendar.current

    // 获取过去几天的日期
    let endDate = calendar.startOfDay(for: Date())

    // 生成日期范围
    for day in 0..<daysBack {
      if let date = calendar.date(byAdding: .day, value: -day, to: endDate) {
        result[date] = 0
      }
    }

    // 获取所有已完成的任务
    let request = Task.fetchRequest()
    request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))

    do {
      let completedTasks = try viewContext.fetch(request)

      for task in completedTasks {
        // 确保任务有创建日期
        guard let createdAt = task.createdAt else { continue }

        // 获取日期的开始时间
        let startOfDay = calendar.startOfDay(for: createdAt)

        // 只统计在我们关注的日期范围内的任务
        if let dateKey = result.keys.first(where: { calendar.isDate($0, inSameDayAs: startOfDay) })
        {
          result[dateKey, default: 0] += 1
        }
      }

      dailyCompletedTasks = result
    } catch {
      print("计算每日完成趋势失败: \(error.localizedDescription)")
    }
  }

  /// 计算过去一周每天创建的任务数量
  func calculateDailyCreationTrend(daysBack: Int = 7) {
    var result: [Date: Int] = [:]
    let calendar = Calendar.current

    // 获取过去几天的日期
    let endDate = calendar.startOfDay(for: Date())

    // 生成日期范围
    for day in 0..<daysBack {
      if let date = calendar.date(byAdding: .day, value: -day, to: endDate) {
        result[date] = 0
      }
    }

    // 获取所有任务
    let request = Task.fetchRequest()

    do {
      let allTasks = try viewContext.fetch(request)

      for task in allTasks {
        // 确保任务有创建日期
        guard let createdAt = task.createdAt else { continue }

        // 获取日期的开始时间
        let startOfDay = calendar.startOfDay(for: createdAt)

        // 只统计在我们关注的日期范围内的任务
        if let dateKey = result.keys.first(where: { calendar.isDate($0, inSameDayAs: startOfDay) })
        {
          result[dateKey, default: 0] += 1
        }
      }

      dailyCreatedTasks = result
    } catch {
      print("计算每日创建趋势失败: \(error.localizedDescription)")
    }
  }

  /// 刷新所有统计数据
  func refreshAllStatistics() {
    calculateCompletionRate()
    calculateCategoryStatistics()
    calculatePriorityStatistics()
    calculateDailyCompletionTrend()
    calculateDailyCreationTrend()
  }

  // MARK: - 数据导出方法

  /// 导出任务数据为CSV格式
  func exportTasksToCSV() -> String {
    let headers = "任务ID,标题,描述,是否完成,优先级,截止日期,创建日期,分类,标签\n"
    var csvString = headers

    for task in taskViewModel.tasks {
      let title = task.title.replacingOccurrences(of: ",", with: "，")
      let desc = task.desc.replacingOccurrences(of: ",", with: "，")

      let dueDate = task.dueDate?.formatted(date: .numeric, time: .omitted) ?? ""
      let createdAt = task.createdAt?.formatted(date: .numeric, time: .omitted) ?? ""

      let category = task.category?.name ?? ""
      let tags = task.tagsArray.map { $0.name }.joined(separator: "|")

      let row =
        "\(task.id),\(title),\(desc),\(task.isCompleted ? "是" : "否"),\(task.priority.rawValue),\(dueDate),\(createdAt),\(category),\(tags)\n"

      csvString += row
    }

    return csvString
  }

  /// 获取用于导出的目录URL
  func getDocumentsDirectory() -> URL {
    // 返回临时目录，而不是文档目录
    return FileManager.default.temporaryDirectory
  }

  /// 导出统计数据为CSV格式
  func exportStatisticsToCSV() -> String {
    // 1. 完成率统计
    var csvString = "统计类型,数据\n"
    csvString += "任务完成率,\(String(format: "%.2f", completionRate * 100))%\n\n"

    // 2. 分类统计
    csvString += "分类,任务数量\n"
    for (category, count) in categoryTaskCounts {
      csvString += "\(category),\(count)\n"
    }
    csvString += "\n"

    // 3. 优先级统计
    csvString += "优先级,任务数量\n"
    for (priority, count) in priorityTaskCounts {
      csvString += "\(priority),\(count)\n"
    }
    csvString += "\n"

    // 4. 每日趋势
    csvString += "日期,创建任务数,完成任务数\n"

    // 合并两个日期字典，确保所有日期都包含在内
    let allDates = Set(dailyCreatedTasks.keys).union(dailyCompletedTasks.keys)
    let sortedDates = allDates.sorted(by: >)

    for date in sortedDates {
      let dateString = date.formatted(date: .numeric, time: .omitted)
      let createdCount = dailyCreatedTasks[date] ?? 0
      let completedCount = dailyCompletedTasks[date] ?? 0

      csvString += "\(dateString),\(createdCount),\(completedCount)\n"
    }

    return csvString
  }
}
