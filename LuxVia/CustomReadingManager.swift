import Foundation

class CustomReadingManager {
    static let shared = CustomReadingManager()
    private let key = "custom_readings"

    private init() {}

    func save(readings: [CustomReading]) {
        if let data = try? JSONEncoder().encode(readings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> [CustomReading] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let readings = try? JSONDecoder().decode([CustomReading].self, from: data) else {
            return []
        }
        return readings
    }

    func add(_ reading: CustomReading) {
        var readings = load()
        readings.append(reading)
        save(readings: readings)
    }

    func remove(_ reading: CustomReading) {
        var readings = load()
        readings.removeAll { $0 == reading }
        save(readings: readings)
    }
}
