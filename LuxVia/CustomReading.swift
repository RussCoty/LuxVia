import Foundation

struct CustomReading: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var content: String

    init(id: UUID = UUID(), title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }

    static func == (lhs: CustomReading, rhs: CustomReading) -> Bool {
        return lhs.id == rhs.id
    }
}
