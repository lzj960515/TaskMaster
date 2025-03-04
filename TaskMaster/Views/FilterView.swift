import SwiftUI

struct FilterView: View {
  @EnvironmentObject var viewModel: TaskViewModel
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("完成状态")) {
          Toggle("显示已完成任务", isOn: $viewModel.showCompletedTasks)
            .onChange(of: viewModel.showCompletedTasks) { oldValue, newValue in
              viewModel.fetchTasks()
            }
        }

        Section(header: Text("分类")) {
          NavigationLink(destination: CategoryListView()) {
            HStack {
              Text("分类")
              Spacer()
              if let category = viewModel.selectedCategory {
                HStack {
                  Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 10, height: 10)
                  Text(category.name)
                    .foregroundColor(.gray)
                }
              } else {
                Text("所有")
                  .foregroundColor(.gray)
              }
            }
          }
        }

        Section(header: Text("标签")) {
          NavigationLink(destination: TagListView()) {
            HStack {
              Text("标签")
              Spacer()
              Text(viewModel.selectedTags.isEmpty ? "所有" : "已选择 \(viewModel.selectedTags.count) 个")
                .foregroundColor(.gray)
            }
          }
        }

        Section {
          Button("重置所有筛选条件") {
            viewModel.resetFilters()
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.red)
        }
      }
      .navigationTitle("筛选")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("完成") {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }
}
