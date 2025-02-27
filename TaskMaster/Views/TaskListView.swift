import SwiftUI

struct TaskListView: View {
  @ObservedObject var viewModel: TaskViewModel
  @State private var newTaskTitle = ""
  @State private var isAddingTask = false
  @State private var editMode: EditMode = .inactive

  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(viewModel.tasks) { task in
            TaskRowView(
              task: task,
              onToggle: {
                viewModel.toggleTaskCompletion(task: task)
              })
          }
          .onDelete { indexSet in
            viewModel.deleteTask(at: indexSet)
          }
        }

        // 添加任务按钮
        Button(action: {
          isAddingTask = true
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
        AddTaskView { title in
          if !title.isEmpty {
            viewModel.addTask(title: title)
          }
          isAddingTask = false
        }
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
  let task: TodoTask
  let onToggle: () -> Void

  var body: some View {
    HStack {
      Button(action: onToggle) {
        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
          .foregroundColor(task.isCompleted ? .green : .gray)
      }

      Text(task.title)
        .strikethrough(task.isCompleted)
        .foregroundColor(task.isCompleted ? .gray : .primary)

      Spacer()

      Text(task.createdAt, style: .date)
        .font(.caption)
        .foregroundColor(.gray)
    }
    .padding(.vertical, 4)
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}

// 添加任务视图
struct AddTaskView: View {
  @State private var newTaskTitle = ""
  @Environment(\.presentationMode) var presentationMode
  var onAdd: (String) -> Void

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("任务信息")) {
          TextField("任务标题", text: $newTaskTitle)
        }

        Section {
          Button("添加") {
            onAdd(newTaskTitle)
            presentationMode.wrappedValue.dismiss()
          }
          .frame(maxWidth: .infinity, alignment: .center)
          .disabled(newTaskTitle.isEmpty)
        }
      }
      .navigationTitle("添加新任务")
      .navigationBarItems(
        trailing: Button("取消") {
          presentationMode.wrappedValue.dismiss()
        })
    }
    .enableInjection()
  }

  #if DEBUG
    @ObserveInjection var forceRedraw
  #endif
}

// 预览
struct TaskListView_Previews: PreviewProvider {
  static var previews: some View {
    TaskListView(viewModel: TaskViewModel(initialTasks: TodoTask.sampleTasks))
  }
}
