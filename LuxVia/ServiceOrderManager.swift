import Foundation

class ServiceOrderManager {
    static let shared = ServiceOrderManager()

    private let storageKey = "serviceOrder"
    private(set) var items: [ServiceItem] = []

    private init() {
        load()
    }

    func add(_ item: ServiceItem) {
        items.append(item)
        print("🟢 Added to service order: \(item.title) [\(item.type.rawValue)]")
        print("📋 Current service items:")
        items.forEach { print("• \($0.title) [\($0.type.rawValue)]") }
        save()
    }


    func remove(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        save()
    }

    func move(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < items.count,
              destinationIndex >= 0, destinationIndex <= items.count else { return }

        let item = items[sourceIndex]
        print("🔁 Moving '\(item.title)' from \(sourceIndex) to \(destinationIndex)")

        items.remove(at: sourceIndex)
        items.insert(item, at: destinationIndex)

        print("✅ New internal order:")
        for (i, item) in items.enumerated() {
            print("  \(i): \(item.title)")
        }

        save()
    }


    func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save service order: \(error)")
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                items = try JSONDecoder().decode([ServiceItem].self, from: data)
            } catch {
                print("Failed to load service order: \(error)")
            }
        }
    }

    func clear() {
        items.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
