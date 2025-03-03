import SwiftUI

struct TagListView: View {
  @EnvironmentObject var viewModel: TaskViewModel
  @State private var showingAddSheet = false
  @State private var newTagName = ""

  var body: some View {
    List {
      Section(header: Text("已选标签")) {
        if viewModel.selectedTags.isEmpty {
          Text("未选择标签")
            .foregroundColor(.gray)
            .italic()
        } else {
          ForEach(Array(viewModel.selectedTags), id: \.id) { tag in
            Button(action: {
              viewModel.toggleTagFilter(tag)
            }) {
              HStack {
                Text(tag.name)
                  .foregroundColor(.primary)
                Spacer()
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.red)
              }
            }
          }

          Button(action: {
            viewModel.selectedTags.removeAll()
            viewModel.fetchTasks()
          }) {
            Text("清除所有标签")
              .foregroundColor(.red)
          }
        }
      }

      Section(header: Text("所有标签")) {
        ForEach(viewModel.tags) { tag in
          Button(action: {
            viewModel.toggleTagFilter(tag)
          }) {
            HStack {
              Text(tag.name)
              Spacer()
              if viewModel.selectedTags.contains(where: { $0.id == tag.id }) {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              }
            }
          }
        }
        .onDelete(perform: deleteTags)
      }
    }
    .navigationTitle("标签")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {
          showingAddSheet = true
        }) {
          Image(systemName: "plus")
        }
      }
    }
    .sheet(isPresented: $showingAddSheet) {
      NavigationView {
        Form {
          Section(header: Text("标签信息")) {
            TextField("标签名称", text: $newTagName)
          }
        }
        .navigationTitle("新建标签")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("取消") {
              newTagName = ""
              showingAddSheet = false
            }
          }

          ToolbarItem(placement: .navigationBarTrailing) {
            Button("保存") {
              if !newTagName.isEmpty {
                viewModel.createTag(name: newTagName)
                newTagName = ""
                showingAddSheet = false
              }
            }
            .disabled(newTagName.isEmpty)
          }
        }
      }
    }
  }

  private func deleteTags(at offsets: IndexSet) {
    for index in offsets {
      viewModel.deleteTag(viewModel.tags[index])
    }
  }
}
