import SwiftUI

struct TaskListView: View {
  @ObservedObject var viewModel: TaskViewModel
  @State private var isAddingTask = false
  @State private var editMode: EditMode = .inactive

  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(viewModel.tasks) { task in
            HStack {
              TaskRowView(task: task, viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .layoutPriority(9)

              ZStack {
                // 不可见导航链接
                NavigationLink(destination: TaskDetailView(task: task, viewModel: viewModel)) {
                  EmptyView()
                }
                .opacity(0)

                // 可见图标
                Image(systemName: "exclamationmark.circle")
                  .foregroundColor(.blue)
                  .font(.system(size: 14))
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
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(editMode.isEditing ? "完成" : "编辑") {
            withAnimation {
              editMode = editMode.isEditing ? .inactive : .active
            }
          }
        }
      }
      .environment(\.editMode, $editMode)
      .sheet(isPresented: $isAddingTask) {
        if let task = viewModel.currentTask {
          NavigationView {
            TaskEditView(task: task, viewModel: viewModel, isNew: true)
          }
        }
      }
      .onDisappear {
        // 确保视图消失时清理可能存在的未保存变更
        viewModel.discardChanges()
      }
      .onAppear {
        viewModel.fetchTasks()
      }
    }
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
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
        Text(task.title)
          .font(.headline)
          .strikethrough(task.isCompleted)
          .foregroundColor(task.isCompleted ? .gray : .primary)

        HStack {
          // 优先级
          Image(systemName: task.priority.symbol)
            .font(.footnote)
            .foregroundColor(Color(task.priority.color))

          // 截止日期
          if let dueDate = task.dueDate {
            Text(formattedDate(dueDate))
              .font(.caption)
              .foregroundColor(isOverdue(dueDate) && !task.isCompleted ? .red : .secondary)
          }
        }
      }

      Spacer()

      if let creationDate = task.createdAt {
        Text(creationDate, style: .date)
          .font(.caption)
          .foregroundColor(.gray)
      }
    }
    .padding(.vertical, 4)
    .enableInjection()
  }

  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
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
    return TaskListView(viewModel: viewModel)
  }
}
