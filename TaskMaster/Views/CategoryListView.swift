import SwiftUI

struct CategoryListView: View {
  @EnvironmentObject var viewModel: TaskViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var showingAddSheet = false
  @State private var newCategoryName = ""
  @State private var newCategoryColor = "#007AFF"

  // 预定义颜色选项
  private let colorOptions = [
    "#FF2D55",  // 红色
    "#FF9500",  // 橙色
    "#FFCC00",  // 黄色
    "#4CD964",  // 绿色
    "#5AC8FA",  // 浅蓝色
    "#007AFF",  // 蓝色
    "#5856D6",  // 紫色
    "#FF2D55",  // 粉色
  ]

  var body: some View {
    List {
      // 所有分类选项
      Button(action: {
        viewModel.filterByCategory(nil)
        dismiss()
      }) {
        HStack {
          Image(systemName: "tray.full")
            .foregroundColor(.blue)
          Text("所有任务")
          Spacer()
          if viewModel.selectedCategory == nil {
            Image(systemName: "checkmark")
              .foregroundColor(.blue)
          }
        }
      }

      // 未分类选项
      Button(action: {
        // 创建一个特殊的"无分类"筛选条件
        let predicate = NSPredicate(format: "category == nil")
        let request = Task.fetchRequest()
        request.predicate = predicate
        viewModel.selectedCategory = nil
        viewModel.fetchTasks()
        dismiss()
      }) {
        HStack {
          Image(systemName: "questionmark.folder")
            .foregroundColor(.gray)
          Text("未分类")
          Spacer()
        }
      }

      Section(header: Text("分类")) {
        ForEach(viewModel.categories) { category in
          Button(action: {
            viewModel.filterByCategory(category)
            dismiss()
          }) {
            HStack {
              Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 12, height: 12)
              Text(category.name)
              Spacer()
              if viewModel.selectedCategory?.id == category.id {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              }
            }
          }
        }
        .onDelete(perform: deleteCategories)
      }
    }
    .navigationTitle("分类")
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
          Section(header: Text("分类信息")) {
            TextField("分类名称", text: $newCategoryName)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
              ForEach(colorOptions, id: \.self) { colorHex in
                Circle()
                  .fill(Color(hex: colorHex))
                  .frame(width: 30, height: 30)
                  .overlay(
                    Circle()
                      .stroke(Color.primary, lineWidth: newCategoryColor == colorHex ? 2 : 0)
                  )
                  .onTapGesture {
                    newCategoryColor = colorHex
                  }
              }
            }
            .padding(.vertical)
          }
        }
        .navigationTitle("新建分类")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("取消") {
              newCategoryName = ""
              showingAddSheet = false
            }
          }

          ToolbarItem(placement: .navigationBarTrailing) {
            Button("保存") {
              if !newCategoryName.isEmpty {
                viewModel.createCategory(name: newCategoryName, colorHex: newCategoryColor)
                newCategoryName = ""
                showingAddSheet = false
              }
            }
            .disabled(newCategoryName.isEmpty)
          }
        }
      }
    }
  }

  private func deleteCategories(at offsets: IndexSet) {
    for index in offsets {
      viewModel.deleteCategory(viewModel.categories[index])
    }
  }
}

// Color扩展，用于从十六进制字符串创建颜色
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
