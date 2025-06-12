import Foundation

class CustomReadingStore {
    static let shared = CustomReadingStore()
    private let fileName = "custom_readings.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func load() -> [CustomReading] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([CustomReading].self, from: data)) ?? []
    }

    func save(_ readings: [CustomReading]) {
        guard let data = try? JSONEncoder().encode(readings) else { return }
        try? data.write(to: fileURL)
    }

    func add(_ reading: CustomReading) {
        var readings = load()
        readings.append(reading)
        save(readings)
    }

    func remove(id: UUID) {
        var readings = load()
        readings.removeAll { $0.id == id }
        save(readings)
    }
}
