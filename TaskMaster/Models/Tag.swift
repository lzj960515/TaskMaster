import CoreData
import Foundation

class Tag: NSManagedObject, Identifiable {
  @NSManaged public var id: UUID
  @NSManaged public var name: String
  @NSManaged public var tasks: NSSet?

  var tasksArray: [Task] {
    let set = tasks as? Set<Task> ?? []
    return set.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
  }

  convenience init(context: NSManagedObjectContext) {
    let entity = NSEntityDescription.entity(forEntityName: "Tag", in: context)!
    self.init(entity: entity, insertInto: context)
    self.id = UUID()
    self.name = ""
  }
}

extension Tag {
  static func fetchRequest() -> NSFetchRequest<Tag> {
    return NSFetchRequest<Tag>(entityName: "Tag")
  }
}
