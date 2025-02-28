import SwiftUI

struct TaskEditView: View {
  @ObservedObject var task: Task
  @ObservedObject var viewModel: TaskViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var title: String
  @State private var description: String
  @State private var priority: TaskPriority
  @State private var hasDueDate: Bool
  @State private var dueDate: Date

  var isNew: Bool

  init(task: Task, viewModel: TaskViewModel, isNew: Bool) {
    self.task = task
    self.viewModel = viewModel
    self.isNew = isNew

    _title = State(initialValue: task.title)
    _description = State(initialValue: task.desc)
    _priority = State(initialValue: task.priority)
    _hasDueDate = State(initialValue: task.dueDate != nil)
    _dueDate = State(initialValue: task.dueDate ?? Date().addingTimeInterval(86400))  // 默认为明天
  }

  var body: some View {
    Form {
      Section(header: Text("任务信息")) {
        TextField("标题", text: $title)

        ZStack(alignment: .topLeading) {
          if description.isEmpty {
            Text("描述（可选）")
              .foregroundColor(.gray)
              .padding(.top, 8)
              .padding(.leading, 4)
          }

          TextEditor(text: $description)
            .frame(minHeight: 100)
        }
      }

      Section(header: Text("优先级")) {
        Picker("优先级", selection: $priority) {
          ForEach(TaskPriority.allCases) { priority in
            HStack {
              Text(priority.rawValue)
            }
            .tag(priority)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
      }

      Section(header: Text("截止日期")) {
        Toggle("设置截止日期", isOn: $hasDueDate)

        if hasDueDate {
          DatePicker(
            "截止日期",
            selection: $dueDate,
            in: Date()...,
            displayedComponents: [.date, .hourAndMinute]
          )
        }
      }

      if !isNew {
        Section {
          Button(action: {
            viewModel.deleteTask(task)
            presentationMode.wrappedValue.dismiss()
          }) {
            HStack {
              Spacer()
              Text("删除任务")
                .foregroundColor(.red)
              Spacer()
            }
          }
        }
      }
    }
    .navigationBarTitle(isNew ? "新建任务" : "编辑任务", displayMode: .inline)
    .navigationBarItems(
      leading: Button("取消") {
        presentationMode.wrappedValue.dismiss()
      },
      trailing: Button("保存") {
        saveTask()
        presentationMode.wrappedValue.dismiss()
      }
      .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    )
  }

  private func saveTask() {
    task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    task.desc = description
    task.priority = priority
    task.dueDate = hasDueDate ? dueDate : nil

    viewModel.updateTask(task)
  }
}

struct TaskEditView_Previews: PreviewProvider {
  static var previews: some View {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = TaskViewModel(context: context)
    let task = Task(context: context)

    return NavigationView {
      TaskEditView(task: task, viewModel: viewModel, isNew: true)
    }
  }
}
