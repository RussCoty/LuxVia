// File: LuxVia/ServiceOrderManager.swift
import Foundation

// Broadcast when the service order changes.
// (VCs should observe and reload on this.)
extension Notification.Name {
    static let serviceItemsUpdated = Notification.Name("serviceItemsUpdated")
}

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
        save() // will notify
    }

    func remove(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        save() // will notify
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

        save() // will notify
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save service order: \(error)")
        }
        // Notify on main so UI updates are safe.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .serviceItemsUpdated, object: nil)
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
        // Notify after initial load so first display is up-to-date.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .serviceItemsUpdated, object: nil)
        }
    }

    func clear() {
        items.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        // Notify so UI clears immediately.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .serviceItemsUpdated, object: nil)
        }
    }

    /// Updates existing song items in the service order to include their lyrics for booklet inclusion
    func addLyricsToSongsInServiceOrder(_ lyrics: [Lyric]) {
        func normalize(_ str: String) -> String {
            let charset = CharacterSet.punctuationCharacters.union(.symbols)
            let noPunct = str.components(separatedBy: charset).joined()
            return noPunct.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        func stripExtension(_ name: String) -> String {
            return (name as NSString).deletingPathExtension
        }
        for (index, item) in items.enumerated() {
            guard item.type == .song else { continue }
            let itemTitleNorm = normalize(item.title)
            let itemFileNorm = item.fileName != nil ? normalize(stripExtension(item.fileName!)) : nil
            let lyric = lyrics.first(where: {
                let lyricTitleNorm = normalize($0.title)
                let lyricFileNorm = $0.audioFileName != nil ? normalize(stripExtension($0.audioFileName!)) : nil
                if let itemFileNorm = itemFileNorm, let lyricFileNorm = lyricFileNorm {
                    return itemFileNorm == lyricFileNorm
                }
                return itemTitleNorm == lyricTitleNorm
            })
            if let lyric = lyric {
                items[index] = ServiceItem(
                    type: item.type,
                    title: item.title,
                    subtitle: item.subtitle,
                    fileName: item.fileName,
                    customText: lyric.body
                )
            }
        }
        save()
    }
}
