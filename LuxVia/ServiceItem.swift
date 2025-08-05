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

    init(type: ServiceItemType, title: String, subtitle: String? = nil, fileName: String? = nil, customText: String? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.fileName = fileName
        self.customText = customText
    }
}
