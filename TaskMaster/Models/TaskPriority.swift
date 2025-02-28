import Foundation

enum TaskPriority: String, CaseIterable, Identifiable, Codable {
  case low = "低"
  case medium = "中"
  case high = "高"

  var id: String { self.rawValue }

  var color: String {
    switch self {
    case .low:
      return "PriorityLow"
    case .medium:
      return "PriorityMedium"
    case .high:
      return "PriorityHigh"
    }
  }

  var symbol: String {
    switch self {
    case .low:
      return "arrow.down.circle"
    case .medium:
      return "equal.circle"
    case .high:
      return "arrow.up.circle"
    }
  }
}
