import SwiftUI

struct TaskDetailView: View {
  var task: Task
  @EnvironmentObject var viewModel: TaskViewModel
  @State private var showEditView = false
  @State private var showReminderSettings = false

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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // 标题和完成状态
        HStack {
          Text(task.title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .strikethrough(task.isCompleted)

          Spacer()

          Button(action: {
            viewModel.toggleTaskCompletion(task)
          }) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
              .resizable()
              .frame(width: 24, height: 24)
              .foregroundColor(task.isCompleted ? .green : .gray)
          }
        }
        .padding(.bottom, 8)

        // 优先级
        HStack(spacing: 8) {
          Image(systemName: task.priority.symbol)
            .foregroundColor(Color(task.priority.color))

          Text("优先级: \(task.priority.rawValue)")
            .font(.headline)
            .foregroundColor(Color(task.priority.color))
        }
        .padding(.vertical, 4)

        // 截止日期和提醒设置
        if let dueDate = task.dueDate {
          HStack(spacing: 8) {
            Image(systemName: "calendar")
              .foregroundColor(.orange)

            Text("截止日期: \(formattedDate(dueDate))")
              .font(.headline)
              .foregroundColor(isOverdue(dueDate) && !task.isCompleted ? .red : .primary)

            Spacer()

            Button(action: {
              showReminderSettings = true
            }) {
              Image(systemName: "bell.circle.fill")
                .foregroundColor(.blue)
            }
          }
          .padding(.vertical, 4)
        } else {
          Button(action: {
            showReminderSettings = true
          }) {
            HStack {
              Image(systemName: "bell.badge.plus")
              Text("设置提醒")
            }
            .foregroundColor(.blue)
          }
          .padding(.vertical, 4)
        }

        // 创建日期
        HStack(spacing: 8) {
          Image(systemName: "clock")
            .foregroundColor(.blue)

          if let creationDate = task.createdAt {
            Text("创建时间: \(formattedDate(creationDate))")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .padding(.vertical, 4)

        Divider()

        // 描述
        VStack(alignment: .leading, spacing: 8) {
          Text("描述")
            .font(.headline)

          Text(task.desc.isEmpty ? "无描述" : task.desc)
            .font(.body)
            .foregroundColor(task.desc.isEmpty ? .secondary : .primary)
        }
        .padding(.vertical, 4)

        Spacer()
      }
      .padding()
    }
    .navigationBarTitle("任务详情", displayMode: .inline)
    .navigationBarItems(
      trailing: Button(action: {
        showEditView = true
      }) {
        Text("编辑")
      }
    )
    .sheet(isPresented: $showEditView) {
      NavigationView {
        TaskEditView(task: task, isNew: false)
      }
    }
    .sheet(isPresented: $showReminderSettings) {
      ReminderSettingsView(task: task)
    }
  }

  private func isOverdue(_ date: Date) -> Bool {
    return date < Date()
  }
}

struct TaskDetailView_Previews: PreviewProvider {
  static var previews: some View {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = TaskViewModel(context: context)
    let task = Task(context: context)
    task.title = "示例任务"
    task.desc = "这是一个示例任务描述"
    task.priority = .medium
    task.dueDate = Date().addingTimeInterval(86400)  // 明天

    return NavigationView {
      TaskDetailView(task: task)
        .environmentObject(viewModel)
    }
  }
}
