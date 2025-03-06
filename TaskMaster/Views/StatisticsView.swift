import SwiftUI

struct StatisticsView: View {
  @EnvironmentObject var taskViewModel: TaskViewModel
  @StateObject private var statisticsViewModel: StatisticsViewModel

  @State private var showExportOptions = false
  @State private var showShareSheet = false
  @State private var csvFileURL: URL? = nil
  @State private var exportType: ExportType = .tasks

  enum ExportType {
    case tasks, statistics
  }

  init(taskViewModel: TaskViewModel) {
    _statisticsViewModel = StateObject(
      wrappedValue: StatisticsViewModel(taskViewModel: taskViewModel))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        // 完成率卡片
        CompletionRateCard(
          completionRate: statisticsViewModel.completionRate,
          totalTasks: statisticsViewModel.totalTaskCount,
          completedTasks: statisticsViewModel.completedTaskCount
        )

        // 优先级分布图
        if !statisticsViewModel.priorityTaskCounts.isEmpty {
          PieChartView(
            data: priorityChartData(),
            title: "任务优先级分布"
          )
        }

        // 分类统计图
        if !statisticsViewModel.categoryTaskCounts.isEmpty {
          BarChartView(
            data: categoryChartData(),
            title: "分类任务统计"
          )
        }

        // 每日任务完成趋势
        if statisticsViewModel.dailyCompletedTasks.count > 1 {
          LineChartView(
            data: completionTrendData(),
            title: "每日任务完成趋势",
            lineColor: .blue
          )
        }

        // 每日任务创建趋势
        if statisticsViewModel.dailyCreatedTasks.count > 1 {
          LineChartView(
            data: creationTrendData(),
            title: "每日任务创建趋势",
            lineColor: .green
          )
        }

        // 导出数据按钮
        Button(action: {
          showExportOptions = true
        }) {
          Label("导出统计数据", systemImage: "square.and.arrow.up")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 16)
        .actionSheet(isPresented: $showExportOptions) {
          ActionSheet(
            title: Text("导出数据"),
            message: Text("选择要导出的数据类型"),
            buttons: [
              .default(Text("导出所有任务")) {
                exportType = .tasks
                exportData()
              },
              .default(Text("导出统计数据")) {
                exportType = .statistics
                exportData()
              },
              .cancel(Text("取消")),
            ]
          )
        }
      }
      .padding()
    }
    .navigationTitle("数据统计")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      statisticsViewModel.refreshAllStatistics()
    }
    .sheet(isPresented: $showShareSheet) {
      if let fileURL = csvFileURL {
        ShareSheet(items: [fileURL])
      }
    }
  }

  // MARK: - 图表数据转换方法

  // 优先级饼图数据
  private func priorityChartData() -> [BarChartData] {
    var data: [BarChartData] = []

    // 高优先级 - 红色
    if let highCount = statisticsViewModel.priorityTaskCounts["高"] {
      data.append(BarChartData(label: "高", value: Double(highCount), color: .red))
    }

    // 中优先级 - 橙色
    if let mediumCount = statisticsViewModel.priorityTaskCounts["中"] {
      data.append(BarChartData(label: "中", value: Double(mediumCount), color: .orange))
    }

    // 低优先级 - 绿色
    if let lowCount = statisticsViewModel.priorityTaskCounts["低"] {
      data.append(BarChartData(label: "低", value: Double(lowCount), color: .green))
    }

    return data
  }

  // 分类条形图数据
  private func categoryChartData() -> [BarChartData] {
    let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .gray]

    return statisticsViewModel.categoryTaskCounts.enumerated().map { index, item in
      let color = colors[index % colors.count]
      return BarChartData(label: item.key, value: Double(item.value), color: color)
    }
  }

  // 每日完成趋势折线图数据
  private func completionTrendData() -> [LineChartData] {
    statisticsViewModel.dailyCompletedTasks.map { date, count in
      LineChartData(date: date, value: Double(count))
    }
  }

  // 每日创建趋势折线图数据
  private func creationTrendData() -> [LineChartData] {
    statisticsViewModel.dailyCreatedTasks.map { date, count in
      LineChartData(date: date, value: Double(count))
    }
  }

  // MARK: - 导出方法

  private func exportData() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let dateString = dateFormatter.string(from: Date())
    let uniqueID = UUID().uuidString.prefix(8)

    let fileName: String
    let csvString: String

    switch exportType {
    case .tasks:
      fileName = "Tasks_\(dateString)_\(uniqueID).csv"
      csvString = statisticsViewModel.exportTasksToCSV()
    case .statistics:
      fileName = "Stats_\(dateString)_\(uniqueID).csv"
      csvString = statisticsViewModel.exportStatisticsToCSV()
    }

    if let data = csvString.data(using: .utf8) {
      // 使用临时目录而不是文档目录，避免文件访问权限问题
      let temporaryDirectoryURL = FileManager.default.temporaryDirectory
      let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
      do {
        // 先删除已存在的同名文件
        if FileManager.default.fileExists(atPath: fileURL.path) {
          try FileManager.default.removeItem(at: fileURL)
        }

        // 写入数据
        try data.write(to: fileURL)

        // 检查文件是否确实被创建
        if FileManager.default.fileExists(atPath: fileURL.path) {
          self.csvFileURL = fileURL
          self.showShareSheet = true
          print("文件成功创建: \(fileURL.path)")
        } else {
          print("导出失败: 文件未被创建")
        }
      } catch {
        print("导出数据失败: \(error.localizedDescription)")
      }
    }
  }
}

// MARK: - 子视图组件

struct CompletionRateCard: View {
  var completionRate: Double
  var totalTasks: Int
  var completedTasks: Int

  var body: some View {
    VStack {
      Text("任务完成率")
        .font(.headline)
        .padding(.bottom, 8)

      ZStack {
        Circle()
          .stroke(Color.gray.opacity(0.2), lineWidth: 15)
          .frame(width: 150, height: 150)

        Circle()
          .trim(from: 0, to: CGFloat(min(completionRate, 1.0)))
          .stroke(
            completionRate > 0.7 ? Color.green : (completionRate > 0.4 ? Color.orange : Color.red),
            style: StrokeStyle(lineWidth: 15, lineCap: .round)
          )
          .frame(width: 150, height: 150)
          .rotationEffect(.degrees(-90))
          .animation(.easeInOut, value: completionRate)

        VStack {
          Text("\(Int(completionRate * 100))%")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(
              completionRate > 0.7 ? .green : (completionRate > 0.4 ? .orange : .red)
            )
        }
      }
      .padding()

      Text("共\(totalTasks)个任务，已完成\(completedTasks)个")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(10)
    .shadow(radius: 1)
  }
}

// 用于导出分享的sheet
struct ShareSheet: UIViewControllerRepresentable {
  var items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    // 为文件URL添加额外的选项
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

    // 排除一些不适合CSV文件的活动类型
    controller.excludedActivityTypes = [
      .assignToContact,
      .addToReadingList,
      .postToFlickr,
      .postToVimeo,
      .postToWeibo,
    ]

    // 设置完成回调
    controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
      if let error = error {
        print("分享出错: \(error.localizedDescription)")
      }

      if completed {
        print("分享成功完成")
      } else {
        print("分享被取消或未完成")
      }
    }

    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 预览
struct StatisticsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      StatisticsView(taskViewModel: TaskViewModel())
    }
  }
}
