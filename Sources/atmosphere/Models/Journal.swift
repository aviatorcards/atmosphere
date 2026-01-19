import Foundation

struct Journal: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var colorHex: String?  // Optional custom color
    var isDefault: Bool  // True for built-in journals
    var sortOrder: Int  // For custom ordering

    init(
        id: UUID = UUID(), name: String, icon: String, colorHex: String? = nil,
        isDefault: Bool = false, sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    // Predefined journal IDs for special collections
    static let allEntriesID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let mapID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let personalID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let workID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let ideasID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    static let trashID = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!

    // Special collections (not persisted)
    static let all = Journal(
        id: allEntriesID, name: "All Entries", icon: "tray.full", isDefault: true, sortOrder: -3)
    static let map = Journal(id: mapID, name: "Places", icon: "map", isDefault: true, sortOrder: -2)
    static let trash = Journal(id: trashID, name: "Trash", icon: "trash", isDefault: true, sortOrder: -1)

    // Factory methods for default journals
    static func createDefaults() -> [Journal] {
        return [
            Journal(
                id: personalID, name: "Personal", icon: "person.text.rectangle", isDefault: true,
                sortOrder: 0),
            Journal(id: workID, name: "Work", icon: "briefcase", isDefault: true, sortOrder: 1),
            Journal(id: ideasID, name: "Ideas", icon: "lightbulb", isDefault: true, sortOrder: 2),
        ]
    }
}
