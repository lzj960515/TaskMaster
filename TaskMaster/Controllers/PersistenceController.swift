import CoreData
import Foundation

struct PersistenceController {
  static let shared = PersistenceController()

  let container: NSPersistentContainer

  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "TaskMaster")

    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    container.loadPersistentStores { description, error in
      if let error = error {
        let errorDescription = error.localizedDescription
        let errorDesc = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "未知错误"
        print("CoreData加载失败: \(errorDescription)")
        print("详细信息: \(errorDesc)")
        fatalError("无法加载CoreData: \(errorDescription)")
      }

      print("CoreData存储加载成功: \(description.url?.absoluteString ?? "unknown")")
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

    container.viewContext.shouldDeleteInaccessibleFaults = true
  }

  func save() throws {
    let context = container.viewContext
    if context.hasChanges {
      try context.save()
    }
  }
}
