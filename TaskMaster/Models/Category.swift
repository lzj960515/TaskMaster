import CoreData
import Foundation

class Category: NSManagedObject, Identifiable {
  @NSManaged public var id: UUID
  @NSManaged public var name: String
  @NSManaged public var colorHex: String
  @NSManaged public var tasks: NSSet?

  var tasksArray: [Task] {
    let set = tasks as? Set<Task> ?? []
    return set.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
  }

  convenience init(context: NSManagedObjectContext) {
    let entity = NSEntityDescription.entity(forEntityName: "Category", in: context)!
    self.init(entity: entity, insertInto: context)
    self.id = UUID()
    self.name = ""
    self.colorHex = "#007AFF"  // 默认蓝色
  }
}

extension Category {
  static func fetchRequest() -> NSFetchRequest<Category> {
    return NSFetchRequest<Category>(entityName: "Category")
  }
}
