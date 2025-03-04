import SwiftUI

struct TaskEditView: View {
  var task: Task
  @EnvironmentObject var viewModel: TaskViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var title: String
  @State private var description: String
  @State private var priority: TaskPriority
  @State private var hasDueDate: Bool
  @State private var dueDate: Date
  @State private var selectedCategory: Category?
  @State private var selectedTags: Set<Tag> = []
  @State private var showingCategoryPicker = false
  @State private var showingTagPicker = false

  var isNew: Bool

  init(task: Task, isNew: Bool) {
    self.task = task
    self.isNew = isNew

    _title = State(initialValue: task.title)
    _description = State(initialValue: task.desc)
    _priority = State(initialValue: task.priority)
    _hasDueDate = State(initialValue: task.dueDate != nil)
    _dueDate = State(initialValue: task.dueDate ?? Date().addingTimeInterval(86400))  // An hour from now
    _selectedCategory = State(initialValue: task.category)

    // 初始化已选标签
    if let tags = task.tags as? Set<Tag>, !tags.isEmpty {
      _selectedTags = State(initialValue: tags)
    }
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

      Section(header: Text("分类")) {
        Button(action: {
          showingCategoryPicker = true
        }) {
          HStack {
            Text("分类")
            Spacer()
            if let category = selectedCategory {
              HStack {
                Circle()
                  .fill(Color(hex: category.colorHex))
                  .frame(width: 10, height: 10)
                Text(category.name)
                  .foregroundColor(.gray)
              }
            } else {
              Text("未分类")
                .foregroundColor(.gray)
            }
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.gray)
          }
        }
      }

      Section(header: Text("标签")) {
        Button(action: {
          showingTagPicker = true
        }) {
          HStack {
            Text("标签")
            Spacer()
            if selectedTags.isEmpty {
              Text("添加标签")
                .foregroundColor(.gray)
            } else {
              Text("\(selectedTags.count)个标签")
                .foregroundColor(.gray)
            }
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.gray)
          }
        }

        // 显示已选标签
        if !selectedTags.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(Array(selectedTags), id: \.id) { tag in
                HStack {
                  Text(tag.name)
                    .font(.caption)
                  Button(action: {
                    selectedTags.remove(tag)
                  }) {
                    Image(systemName: "xmark.circle.fill")
                      .font(.caption)
                      .foregroundColor(.gray)
                  }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.systemGray6))
                .cornerRadius(15)
              }
            }
          }
          .padding(.vertical, 5)
        }
      }

      Section(header: Text("优先级")) {
        Picker("优先级", selection: $priority) {
          ForEach(TaskPriority.allCases) { priority in
            Label {
              Text(priority.rawValue)
            } icon: {
              Image(systemName: priority.symbol)
                .foregroundColor(Color(priority.color))
            }
            .tag(priority)
          }
        }
        .pickerStyle(NavigationLinkPickerStyle())
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
          .datePickerStyle(.automatic)
          .environment(\.locale, Locale(identifier: "zh_CN"))
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
    .sheet(isPresented: $showingCategoryPicker) {
      NavigationView {
        List {
          // 无分类选项
          Button(action: {
            selectedCategory = nil
            showingCategoryPicker = false
          }) {
            HStack {
              Text("无分类")
              Spacer()
              if selectedCategory == nil {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              }
            }
          }

          ForEach(viewModel.categories) { category in
            Button(action: {
              selectedCategory = category
              showingCategoryPicker = false
            }) {
              HStack {
                Circle()
                  .fill(Color(hex: category.colorHex))
                  .frame(width: 12, height: 12)
                Text(category.name)
                Spacer()
                if selectedCategory?.id == category.id {
                  Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                }
              }
            }
          }

          // 添加新分类按钮
          NavigationLink(destination: CategoryListView()) {
            HStack {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
              Text("添加新分类")
                .foregroundColor(.blue)
            }
          }
        }
        .navigationTitle("选择分类")
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("完成") {
              showingCategoryPicker = false
            }
          }
        }
      }
    }
    .sheet(isPresented: $showingTagPicker) {
      NavigationView {
        List {
          ForEach(viewModel.tags) { tag in
            Button(action: {
              if selectedTags.contains(tag) {
                selectedTags.remove(tag)
              } else {
                selectedTags.insert(tag)
              }
            }) {
              HStack {
                Text(tag.name)
                Spacer()
                if selectedTags.contains(where: { $0.id == tag.id }) {
                  Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                }
              }
            }
          }

          // 添加新标签按钮
          NavigationLink(destination: TagListView()) {
            HStack {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
              Text("添加新标签")
                .foregroundColor(.blue)
            }
          }
        }
        .navigationTitle("选择标签")
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("完成") {
              showingTagPicker = false
            }
          }
        }
      }
    }
  }

  private func saveTask() {
    task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    task.desc = description
    task.priority = priority
    task.dueDate = hasDueDate ? dueDate : nil
    task.category = selectedCategory

    // 更新标签
    if let existingTags = task.tags {
      for tag in existingTags {
        if let tag = tag as? Tag {
          task.removeFromTags(tag)
        }
      }
    }

    for tag in selectedTags {
      task.addToTags(tag)
    }

    viewModel.updateTask(task)
  }
}

struct TaskEditView_Previews: PreviewProvider {
  static var previews: some View {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = TaskViewModel(context: context)
    let task = Task(context: context)

    return NavigationView {
      TaskEditView(task: task, isNew: true)
        .environmentObject(viewModel)
    }
  }
}
