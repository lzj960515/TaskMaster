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
  @NSManaged public var category: Category?
  @NSManaged public var tags: NSSet?

  var priority: TaskPriority {
    get {
      return TaskPriority(rawValue: priorityRaw) ?? .medium
    }
    set {
      priorityRaw = newValue.rawValue
    }
  }

  var tagsArray: [Tag] {
    let set = tags as? Set<Tag> ?? []
    return set.sorted { $0.name < $1.name }
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

  func addToTags(_ tag: Tag) {
    let currentTags = self.tags ?? NSSet()
    self.tags = currentTags.adding(tag) as NSSet
  }

  func removeFromTags(_ tag: Tag) {
    let currentTags = self.tags ?? NSSet()
    self.tags =
      currentTags.filtered(using: NSPredicate(format: "id != %@", tag.id as CVarArg)) as NSSet
  }
}

extension Task {
  static func fetchRequest() -> NSFetchRequest<Task> {
    return NSFetchRequest<Task>(entityName: "Task")
  }
}
