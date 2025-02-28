import CoreData
import Foundation

class Task: NSManagedObject, Identifiable {
  @NSManaged public var id: UUID
  @NSManaged public var title: String
  @NSManaged public var desc: String
  @NSManaged public var isCompleted: Bool
  @NSManaged public var priorityRaw: String
  @NSManaged public var dueDate: Date?
  @NSManaged public var createdAt: Date?

  var priority: TaskPriority {
    get {
      return TaskPriority(rawValue: priorityRaw) ?? .medium
    }
    set {
      priorityRaw = newValue.rawValue
    }
  }

  convenience init(context: NSManagedObjectContext) {
    let entity = NSEntityDescription.entity(forEntityName: "Task", in: context)!
    self.init(entity: entity, insertInto: context)
    self.id = UUID()
    self.createdAt = Date()
    self.title = ""
    self.desc = ""
    self.isCompleted = false
    self.priorityRaw = TaskPriority.medium.rawValue
  }
}

extension Task {
  static func fetchRequest() -> NSFetchRequest<Task> {
    return NSFetchRequest<Task>(entityName: "Task")
  }
}
