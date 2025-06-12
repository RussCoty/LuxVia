import Foundation

class CustomReadingStore {
    static let shared = CustomReadingStore()

    private let key = "customReadings"

    private init() {}

    func load() -> [CustomReading] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CustomReading].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ readings: [CustomReading]) {
        if let data = try? JSONEncoder().encode(readings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ reading: CustomReading) {
        var current = load()
        current.append(reading)
        save(current)
    }

    func update(_ id: UUID, with updated: CustomReading) {
        var current = load()
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index] = updated
            save(current)
        }
    }

    func remove(id: UUID) {
        var current = load()
        current.removeAll { $0.id == id }
        save(current)
    }
}
