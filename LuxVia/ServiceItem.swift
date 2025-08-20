import Foundation

enum ServiceItemType: String, Codable {
    case song
    case music
    case reading
    case welcome
    case farewell
    case customReading
    case background
}

struct ServiceItem: Codable, Identifiable {
    let id: UUID
    var type: ServiceItemType
    var title: String
    var subtitle: String?
    var fileName: String?      // For music only
    var customText: String?    // For readings or messages
    var uid: Int?              // Unique ID for lyrics/readings from CSV; nil for custom items

    /// uid is used for exact matching to lyrics/readings in the CSV. If nil, this is a custom item.
    init(type: ServiceItemType, title: String, subtitle: String? = nil, fileName: String? = nil, customText: String? = nil, uid: Int? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.fileName = fileName
        self.customText = customText
        self.uid = uid
    }
}
