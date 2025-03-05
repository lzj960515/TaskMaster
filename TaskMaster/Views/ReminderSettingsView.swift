import SwiftUI
import _Concurrency

struct ReminderSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var task: Task
  @State private var isReminderEnabled: Bool
  @State private var reminderDate: Date
  @State private var showingAlert = false
  @State private var alertMessage = ""

  init(task: Task) {
    self.task = task
    _isReminderEnabled = State(initialValue: task.dueDate != nil)
    _reminderDate = State(initialValue: task.dueDate ?? Date())
  }

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("提醒设置")) {
          Toggle("启用提醒", isOn: $isReminderEnabled)

          if isReminderEnabled {
            DatePicker(
              "提醒时间",
              selection: $reminderDate,
              displayedComponents: [.date, .hourAndMinute]
            )
          }
        }

        Section {
          Button(action: saveReminder) {
            Text("保存设置")
              .frame(maxWidth: .infinity)
              .foregroundColor(.blue)
          }
        }
      }
      .navigationTitle("提醒设置")
      .navigationBarItems(
        leading: Button("取消") {
          dismiss()
        }
      )
      .alert("提示", isPresented: $showingAlert) {
        if alertMessage.contains("请在设置中允许应用发送通知") {
          Button("去设置", role: .none) {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(settingsURL)
            }
          }
          Button("取消", role: .cancel) {}
        } else {
          Button("确定", role: .cancel) {}
        }
      } message: {
        Text(alertMessage)
      }
    }
  }

  private func saveReminder() {
    _Concurrency.Task {
      do {
        if isReminderEnabled {
          // 更新任务的截止日期
          task.dueDate = reminderDate

          // 请求通知权限
          let isAuthorized = try await NotificationController.shared.requestAuthorization()

          if isAuthorized {
            // 设置提醒
            try await NotificationController.shared.scheduleTaskReminder(for: task)
            alertMessage = "提醒设置成功"

            // 只在成功时延迟关闭视图
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              dismiss()
            }
          } else {
            alertMessage = "请在设置中允许应用发送通知"
          }
        } else {
          // 取消提醒
          task.dueDate = nil
          NotificationController.shared.cancelTaskReminder(for: task)
          alertMessage = "已取消提醒"

          // 取消提醒也是成功操作，延迟关闭
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
          }
        }

        showingAlert = true
      } catch {
        alertMessage = "设置提醒失败：\(error.localizedDescription)"
        showingAlert = true
      }
    }
  }
}
