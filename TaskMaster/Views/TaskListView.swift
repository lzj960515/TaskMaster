import SwiftUI

struct TaskListView: View {
  @EnvironmentObject var viewModel: TaskViewModel
  @State private var isAddingTask = false
  @State private var editMode: EditMode = .inactive
  @State private var showingFilterSheet = false
  @State private var selectedTaskID: UUID? = nil
  @State private var showTaskDetail = false

  var body: some View {
    NavigationStack {
      VStack {
        // 搜索栏
        SearchBar(
          text: $viewModel.searchText,
          onSearch: {
            viewModel.fetchTasks()
          }
        )
        .padding(.horizontal)

        // 分类和标签筛选指示器
        if viewModel.selectedCategory != nil || !viewModel.selectedTags.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              if let category = viewModel.selectedCategory {
                FilterChip(
                  label: category.name,
                  color: Color(hex: category.colorHex),
                  onRemove: {
                    viewModel.filterByCategory(nil)
                  }
                )
              }

              ForEach(Array(viewModel.selectedTags), id: \.id) { tag in
                FilterChip(
                  label: tag.name,
                  color: .blue,
                  onRemove: {
                    viewModel.toggleTagFilter(tag)
                  }
                )
              }

              if viewModel.selectedCategory != nil || !viewModel.selectedTags.isEmpty {
                Button(action: {
                  viewModel.resetFilters()
                }) {
                  Text("清除全部")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red)
                    .cornerRadius(15)
                }
                .padding(.trailing, 5)
              }
            }
            .padding(.leading, 10)
          }
          .padding(.vertical, 5)
        }

        List {
          ForEach(viewModel.tasks) { task in
            HStack {
              TaskRowView(task: task, viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .layoutPriority(9)

              NavigationLink(destination: TaskDetailView(task: task)) {
                EmptyView()
              }
              .frame(maxWidth: .infinity)
              .layoutPriority(1)
            }.buttonStyle(BorderlessButtonStyle())
          }
          .onDelete { indexSet in
            viewModel.deleteTask(at: indexSet)
          }
        }

        // 添加任务按钮
        Button(action: {
          isAddingTask = true
          let newTask = viewModel.createTask()
          viewModel.currentTask = newTask
        }) {
          HStack {
            Image(systemName: "plus.circle.fill")
            Text("添加新任务")
          }
          .padding()
          .foregroundColor(.white)
          .background(Color.blue)
          .cornerRadius(10)
        }
        .padding(.bottom)
      }
      .navigationTitle("我的任务")
      // 添加导航目标
      .navigationDestination(isPresented: $showTaskDetail) {
        if let taskID = selectedTaskID, let task = viewModel.getTask(by: taskID) {
          TaskDetailView(task: task)
        } else {
          Text("任务未找到")
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(editMode.isEditing ? "完成" : "编辑") {
            withAnimation {
              editMode = editMode.isEditing ? .inactive : .active
            }
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {
            showingFilterSheet = true
          }) {
            Image(systemName: "line.horizontal.3.decrease.circle")
          }
        }
      }
      .environment(\.editMode, $editMode)
      .sheet(isPresented: $isAddingTask) {
        if let task = viewModel.currentTask {
          NavigationView {
            TaskEditView(task: task, isNew: true)
          }
        }
      }
      .sheet(isPresented: $showingFilterSheet) {
        FilterView().environmentObject(viewModel)
      }
      .onDisappear {
        // 确保视图消失时清理可能存在的未保存变更
        viewModel.discardChanges()
        // 移除观察者
        NotificationCenter.default.removeObserver(
          self,
          name: .didSelectTaskFromNotification,
          object: nil
        )
      }
      .onAppear {
        viewModel.fetchTasks()
        // 设置通知观察者
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
    }
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}

// 搜索栏视图
struct SearchBar: View {
  @Binding var text: String
  var onSearch: () -> Void

  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.gray)

      TextField("搜索任务", text: $text)
        .onChange(of: text) { newValue, oldValue in
          onSearch()
        }

      if !text.isEmpty {
        Button(action: {
          text = ""
          onSearch()
        }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.gray)
        }
      }
    }
    .padding(8)
    .background(Color(.systemGray6))
    .cornerRadius(10)
  }
}

// 筛选标签视图
struct FilterChip: View {
  let label: String
  let color: Color
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)

      Text(label)
        .font(.caption)
        .lineLimit(1)

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.system(size: 10))
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Color(.systemGray6))
    .cornerRadius(15)
    .padding(.trailing, 5)
  }
}

// 任务行视图组件
struct TaskRowView: View {
  @ObservedObject var task: Task
  @ObservedObject var viewModel: TaskViewModel

  var body: some View {
    HStack {
      Button(action: {
        viewModel.toggleTaskCompletion(task)
      }) {
        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
          .foregroundColor(task.isCompleted ? .green : .gray)
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(task.title)
            .font(.headline)
            .strikethrough(task.isCompleted)
            .foregroundColor(task.isCompleted ? .gray : .primary)
        }

        if task.category != nil || task.dueDate != nil || task.tags?.count ?? 0 > 0 {
          HStack(spacing: 6) {
            // 分类标签
            if let category = task.category {
              HStack(spacing: 2) {
                Circle()
                  .fill(Color(hex: category.colorHex))
                  .frame(width: 8, height: 8)
                Text(category.name)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }

            // 截止日期
            if let dueDate = task.dueDate {
              Text(formattedDate(dueDate))
                .font(.caption)
                .foregroundColor(isOverdue(dueDate) && !task.isCompleted ? .red : .secondary)
            }
          }

          // 显示标签
          if let tags = task.tags, tags.count > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(task.tagsArray) { tag in
                  Text(tag.name)
                    .font(.system(size: 10))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                }
              }
            }
            .frame(height: 20)
          }
        }

      }

      Spacer()

    }
    .padding(.vertical, 4)
    .enableInjection()
  }

  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()

  private func formattedDate(_ date: Date) -> String {
    return dateFormatter.string(from: date)
  }

  private func isOverdue(_ date: Date) -> Bool {
    return date < Date()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}

// 预览
struct TaskListView_Previews: PreviewProvider {
  static var previews: some View {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = TaskViewModel(context: context)
    TaskListView()
      .environment(\.managedObjectContext, context)
      .environmentObject(viewModel)
  }
}
